using Revise 

using AsyncTerminal: aync_tty

aync_tty((
	`tty`,
	[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], 
	`echo "We are rocking!"`
))

#%%

#%%
includet("../src/AsyncTerminal.jl")
using .AsyncTerminal: async_tty

terminals = async_tty([
	(`ssh -t serverX@192.168.0.100 pwd`, `ssh -t serverX@192.168.0.100 echo "We are rocking!"`,`ssh -t serverX@192.168.0.100 "cd repo && pwd"`,`ssh -t serverX@192.168.0.100 pwd`),
	(`echo "heyyooo"`,),
	(`echo "heyyooo"`,`tty`,`echo "heyyooo"`,),
	], shell="zsh")
#%%

run(terminals[1], `echo "I am still here heyyy"`)
run(terminals[2], `ssh -t serverX@192.168.0.23 "cd Video && ls"`)
run(terminals[2], `echo "I am actually just a terminal! I still need to ressh into the session to do the command on the remote. The Cmd restart each time."`)

#%%

# user, ip, cust_cmd = "testuser", "127.0.0.1", """echo "I am on the machine" """
terms = aync_tty([
	`tty`,
	(`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`), 
	`echo "We are rocking!"`
])
@show terms
#%%
using Base.Threads
using AsyncTerminal: create_ttys
TTNum = 3
ttys = create_ttys(TTNum, "zsh")
@threads for i in 1:3
	@show i
	write(ttys[i], "I am here $i\n") 
	flush(ttys[i])
end
#%%
is it possible to read data from the terminal?
how could I handle the data coming from it? What pattern should I use?


start_x_tty(tty_count, shell="bash") = [open("/dev/pts/$t_id", "w") for t_id in sort(start_x_tty_nostart(tty_count, shell))]
can I get data from that /dev/pts/id or it is not possible?
#%%
ttys = create_ttys(1, "zsh")
function read_terminal(io::IOStream)
	while !eof(io)
			line = readline(io)
			# Process the line
			println("Received: ", line)
	end
end

# Async reading pattern
@async read_terminal(ttys[1])
write(ttys[1], "I am here i\n") 
flush(ttys[1])
write(ttys[1], "I am2 here 2\n") 
flush(ttys[1])

#%%
using AsyncTerminal: create_ttys
ttys = create_ttys(1, "zsh")
write(ttys[1], "I am here i\n") 
flush(ttys[1])
write(ttys[1], "I am2 here 2\n") 
flush(ttys[1])

#%%
function monitor_terminal(io::IOStream)
	buffer = IOBuffer()
	while isopen(io)
			try
					if bytesavailable(io) > 0
							write(buffer, read(io))
							# Process buffer content
							println(String(take!(buffer)))
					end
					sleep(0.1)  # Prevent busy waiting
			catch e
					@warn "Terminal read error" exception=e
					break
			end
	end
end

ttys = create_ttys(1)
@async monitor_terminal(ttys[1])


#%%
macroexpand(@aync_tty [
	`tty`,
	(`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`), 
	`echo "We are rocking!"`
])
#%%
ttys
#%%
using .AsyncTerminal: terminate
terminate.(ttys, ["zsh"])
#%%
ttys
#%%
using .AsyncTerminal: terminate_all_async_terminal
terminate_all_async_terminal()
#%%

run_on(term1, `tty`)
#%%
read(`gnome-terminal -- bash -c "tty && sleep(2)"`, String)
#%%
@edit @async start(tty_io, cmd)
#%%
includet("../src/AsyncTerminal.jl")

using .AsyncTerminal: start_x_tty, aync_tty
ttys = aync_tty((`tty`,`tty`), "zsh")
sleep(1)
# terminate.(ttys)
#%%
ttys[1].name[7:end-1]
#%%
a=run(`gnome-terminal -- zsh`; write=true)
#%%
run(`kill -9 17033`)
#%%
read(`ps aux \| grep '\[z\]sh' \| awk '\{print \$2, \$7\}'`, String)
#%%
read(pipeline(`ps aux \| grep '\[z\]sh' \| awk '\{print \$2, \$7\}'`), String)
#%%
cccm = `ps aux`
out = read(cccm, String)
lines = split(out, '\n')
#%%
using .AsyncTerminal: list_all_terminals
list_all_terminals("zsh")

#%%
split(lines[2])
#%%
lines[2][5:16]
#%%
using Base: PipeEndpoint
q=PipeEndpoint()
#%%
#%%
write(q.buffer, "test")
flush(q.buffer)
#%%
b=open(`gnome-terminal -- zsh`, q, write=true)
#%%
fieldnames(typeof(ttys[1]))
#%%
using Boilerplate
@typeof ttys[1].handle
@typeof ttys[1].ios
@typeof ttys[1].name
@typeof ttys[1].mark
@typeof ttys[1].lock
@typeof ttys[1]._dolock
#%%
fieldnames(typeof(b.in))
#%%
b.in, b.out, b.err
#%%
b.in
#%%
b.cmd
#%%
b[cmd]
#%%
xx=Vector{UInt8}(undef, 6)
readbytes!(b.in, xx)
#%%
b.in
#%%
String(xx)
#%%
read(b.in)
#%%
println.([(col,getfield(b,col)) for col in fieldnames(typeof(b))])
#%%
write(b.out, "exit\n")
#%%
flush(b.out)
#%%
flush(b.in)
#%%
b.in
#%%
a.exitnotify
#%%
a.in, a.out, a.err
#%%
fieldnames(typeof(a))
#%%
terminate(ttys[1])
#%%
write(ttys[1], "exit")
flush(ttys[1])
#%%
fd = Base.Filesystem.open("/dev/pts/15", Base.JL_O_RDWR)
rawfd = Base.Filesystem.fd(fd)
tty = Base.TTY(rawfd)

# Keep reading in a loop
while true
    try
        line = readline(tty)
        println("Received: ", line)í
    catch e
        println("Error: ", e)
        break
    end
end

#%%
function read_pts(pts_path)
	    # Create a new PTY pair
			master_fd = ccall(:posix_openpt, Cint, (Cint,), Base.Filesystem.JL_O_RDWR)
			master_fd == -1 && error("Failed to open PTY master")
			@show "litening"
			# Grant and unlock PTY
			ccall(:grantpt, Cint, (Cint,), master_fd) == 0 || error("grantpt failed")
			ccall(:unlockpt, Cint, (Cint,), master_fd) == 0 || error("unlockpt failed")
			
			@show "??"
			# Set non-blocking I/O on master
			ccall(:fcntl, Int32, (RawFD, Int32, Int32), RawFD(master_fd), 3, 2048)
			
			@show "??f"
			# Configure terminal
			run(`sh -c "stty raw -echo -icanon -iexten -isig -ixon -ixoff < $pts_path"`)
			@show "??ff3"
			
			buffer = Vector{UInt8}(undef, 1)
			while true
					try
							n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), RawFD(master_fd), buffer, 1)
							if n > 0
									# We got data before terminal consumed it
									@show String(buffer)
									flush(stdout)
							else
									sleep(0.001)
							end
					catch e
							println("Error: ", e)
							break
					end
			end
			
			@show "closing"
			# Cleanup
			ccall(:close, Cint, (RawFD,), RawFD(master_fd))
	

end
read_pts("/dev/pts/7")

#%%


# AsyncTerminal.@aync_ssh [
# 	(`master@127.0.0.1`, `tty`),
# 	(`master@127.0.0.1`, `echo `haha whut``),
# ] 

