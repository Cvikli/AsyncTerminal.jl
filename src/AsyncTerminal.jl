module AsyncTerminal

using Revise
using Base.Threads

export aync_tty

include("BaseExtension.jl")

all_our_pts2ID = Dict{String,Int}()

start_x_tty_nostart(tty_count, shell="bash"; monitor=false) = begin
	pts_ls = read(`ls /dev/pts`, String)
	monitor_fds = nothing
	
	if monitor
			# Create monitoring PTYs first
			monitor_fds = Vector{RawFD}(undef, tty_count)
			monitor_pts = Vector{String}(undef, tty_count)
			for i in 1:tty_count
					master_fd = ccall(:posix_openpt, Cint, (Cint,), Base.Filesystem.JL_O_RDWR)
					master_fd == -1 && error("Failed to open PTY master")
					ccall(:grantpt, Cint, (Cint,), master_fd) == 0 || error("grantpt failed")
					ccall(:unlockpt, Cint, (Cint,), master_fd) == 0 || error("unlockpt failed")
					monitor_pts[i] = unsafe_string(ccall(:ptsname, Ptr{UInt8}, (Cint,), master_fd))
					monitor_fds[i] = RawFD(master_fd)
			end
			
			@threads for i in 1:tty_count
            # Use script with -f for flushing and -q for quiet mode
            run(`gnome-terminal -- $shell -c "script -f -q $(monitor_pts[i])"`, wait=false)
        end
	else
			@threads for i in 1:tty_count
					run(`gnome-terminal -- $shell`, wait=false)
			end
	end
	
	new_pts_ls = read(`ls /dev/pts`, String)
	pts_nums = parse.(Int,split(pts_ls, '\n')[1:end-2])
	new_pts_nums = parse.(Int,split(new_pts_ls, '\n')[1:end-2])
	new_t_ids = Int[t_id for t_id in new_pts_nums if !(t_id in pts_nums)]

	return new_t_ids, monitor_fds
end

function start_x_tty(tty_count, shell="bash") 
    term_ids, _ = start_x_tty_nostart(tty_count, shell, monitor=false)
    [open("/dev/pts/$t_id", "w") for t_id in sort(term_ids)]
end

function start_x_tty_monitored(tty_count, shell="bash")
    term_ids, monitor_fds = start_x_tty_nostart(tty_count, shell, monitor=true)
    ttys = [open("/dev/pts/$t_id", "w") for t_id in sort(term_ids)]
    return ttys, monitor_fds
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

function read_terminall(io::IOStream)
    buffer = Vector{UInt8}(undef, 1024)
    while isopen(io)
        try
            if bytesavailable(io) > 0
                n = readbytes!(io, buffer)
                if n > 0
                    print(String(view(buffer, 1:n)))
                    flush(stdout)
                end
            end
            sleep(0.01)
        catch e
            @warn "Terminal read error" exception=e
            break
        end
    end
end

end # module
