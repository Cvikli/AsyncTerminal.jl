module AsyncTerminal

using Revise
using Base.Threads

export aync_tty

include("BaseExtension.jl")

all_our_pts2ID = Dict{String,Int}()

const LIBC = Base.Libc.Libdl.dlopen("/lib/x86_64-linux-gnu/libc.so.6")
const openpty = Base.Libc.Libdl.dlsym(LIBC, :openpty)

mutable struct PTY
    master_fd::RawFD
    slave_fd::RawFD
    slave_path::String
    process::Union{Base.Process, Nothing}
end

function create_pty()
    # O_RDWR | O_NOCTTY
    master_fd = ccall(:posix_openpt, Cint, (Cint,), 2 | 32768)
    master_fd < 0 && error("Failed to open PTY master")

    # Grant and unlock PTY
    ccall(:grantpt, Cint, (Cint,), master_fd) == 0 || error("Failed to grant PTY")
    ccall(:unlockpt, Cint, (Cint,), master_fd) == 0 || error("Failed to unlock PTY")

    # Get slave path
    slave_path = zeros(UInt8, 1024)
    ret = ccall(:ptsname_r, Cint, (Cint, Ptr{UInt8}, Csize_t), 
                master_fd, slave_path, length(slave_path))
    ret != 0 && error("Failed to get slave PTY name")

    # Open slave
    slave_path_str = GC.@preserve slave_path unsafe_string(pointer(slave_path))
    slave_fd = ccall(:open, Cint, (Ptr{UInt8}, Cint), slave_path_str, 2)
    slave_fd < 0 && (close(master_fd); error("Failed to open slave PTY"))

    PTY(RawFD(master_fd), RawFD(slave_fd), slave_path_str, nothing)
end

start_x_tty_nostart(tty_count, shell="bash"; monitor=false) = begin
    pts_ls = read(`ls /dev/pts`, String)
		@show pts_ls
    monitor_ptys = nothing
    
    if monitor
        monitor_ptys = [create_pty() for _ in 1:tty_count]
        
        @threads for i in 1:length(monitor_ptys)
            pty = monitor_ptys[i]
            # Use cat to keep the terminal open and pipe through the shell
            cmd = `gnome-terminal -- $shell -c "stty raw -echo; cat <$(pty.slave_path) | $shell >$(pty.slave_path) 2>&1"`
            pty.process = run(cmd)
        end
        sleep(0.5)
    else
        @threads for i in 1:tty_count
            # Keep shell running by using -i flag and preventing immediate exit
            run(`gnome-terminal -- $shell -i`)
        end
    end
    
    new_pts_ls = read(`ls /dev/pts`, String)
		@show new_pts_ls
    pts_nums = parse.(Int, split(pts_ls, '\n')[1:end-2])
    new_pts_nums = parse.(Int, split(new_pts_ls, '\n')[1:end-2])
    new_t_ids = Int[t_id for t_id in new_pts_nums if !(t_id in pts_nums)]
		@show new_t_ids

    return new_t_ids, monitor_ptys
end

function start_x_tty(tty_count, shell="bash") 
    term_ids, _ = start_x_tty_nostart(tty_count, shell, monitor=false)
    [open("/dev/pts/$t_id", "w") for t_id in sort(term_ids)]
end

# Update the start_x_tty_monitored function
function start_x_tty_monitored(tty_count, shell="bash")
    term_ids, monitor_ptys = start_x_tty_nostart(tty_count, shell, monitor=true)
    ttys = [open("/dev/pts/$t_id", "w") for t_id in sort(term_ids)]
    return ttys, monitor_ptys
end

start(t_io::IOStream, cmd::Cmd)               = run(t_io, cmd) 
start(t_io::IOStream, cmds::Tuple)            = for cmd in cmds; run(t_io, cmd)    end 
start(t_io::IOStream, cmds::Vector{Cmd})      = for cmd in cmds; run(t_io, cmd)    end 
# start(t_io::IOStream, fns::Tuple)             = for fn  in fns;  println(t_io, fn) end 
start(t_io::IOStream, fns::Vector{Function})  = for fn  in fns;  println(t_io, fn) end 

list_all_bashes(shell="bash") = begin
	ps_output     = read(`ps aux`, String)
	lines         = split(ps_output, '\n')
	zsh_lines     = filter(l -> occursin(shell, l), lines)
end
list_all_terminals(shell="bash") = begin
	zsh_lines     = list_all_bashes(shell)
	all_terminals = Dict{String, Int}()
	for line in zsh_lines
			fields   = split(line)
			pid, tty = parse(Int,fields[2]), fields[7]
			all_terminals[tty] = pid
	end
	all_terminals
end
get_pts_from_psaux(str) = str[12:end-1] # [12:end-1]: this strip the "pts/X" part from: "<file /dev/pts/X>" 



exit(t_io::IOStream, shell="bash")                         = terminate(t_io, shell)
close_tty(t_io::IOStream, shell="bash")                    = terminate(t_io, shell)
terminate(t_io::IOStream, shell="bash")                    = begin
	PID::Ref{Int} = -1
	all_pts2ID = list_all_terminals(shell)
	pts = get_pts_from_psaux(t_io.name)
	try 
		PID[] = all_pts2ID[pts]
		run(`kill -9 $(PID[])`)
	catch err
		if isa(err, KeyError)
			println(typeof(err),": Terminal with $(pts) isn't found!")
		elseif isa(err, ProcessFailedException)
			println(typeof(err),": Terminal with $(pts) isn't found!")
		else
			println(typeof(err))
			rethrow()
		end
	end
	pts => PID[]
end
terminate_all_async_terminal() = begin
	global all_our_pts2ID
	call_our_pts2ID = deepcopy(all_our_pts2ID)
	for (pts,tty_pid) in call_our_pts2ID
		try 
			run(`kill -9 $(tty_pid)`)
			delete!(all_our_pts2ID,pts)
		catch err
			if isa(err, KeyError)
				println(typeof(err),": Terminal(previously $(tty_pid)) with $(pts) isn't found!")
			elseif isa(err, ProcessFailedException)
				println(typeof(err),": Terminal(previously $(tty_pid)) with $(pts) isn't found!")
			else
				println(typeof(err))
				rethrow()
			end
		end
	end
	call_our_pts2ID
end

# Add cleanup function for PTYs
function cleanup_pty(pty::PTY)
    if pty.process !== nothing
        kill(pty.process)
    end
    ccall(:close, Cint, (RawFD,), pty.master_fd)
    ccall(:close, Cint, (RawFD,), pty.slave_fd)
end
	

#################### @async_tty ####################
# macro ttys(args...); quote esc(ttys(($(esc(args)))...)) end;end

function create_ttys(ttys_count::Int, shell="bash")
	global all_our_pts2ID
	tty_IOs    = start_x_tty(ttys_count, shell)
	tty_pts2ID = list_all_terminals(shell)
	for tty in tty_IOs
		pts = get_pts_from_psaux(tty.name)
		isempty(pts) && continue
		all_our_pts2ID[pts]=tty_pts2ID[pts]  
	end
	return tty_IOs
end
function async_tty(cmds::Tuple, shell="bash")
	tty_IOs = create_ttys(length(cmds), shell)
	@show cmds
	for (tty_io,cmd) in zip(tty_IOs, cmds) @async run(tty_io, cmd) end
	return tty_IOs
end
async_tty(cmds::Vector{T}; shell="bash") where T = async_tty((cmds...,), shell)


end # module
