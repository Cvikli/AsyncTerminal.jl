using Revise 

includet("../src/AsyncTerminal.jl")
using .AsyncTerminal: aync_tty

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
includet("../src/AsyncTerminal.jl")
using .AsyncTerminal: create_ttys
ttys = create_ttys(nthreads(), "zsh")
@threads for i in 1:100
	write(ttys[threadid()], "I am here $i\n") 
	flush(ttys[threadid()])
end
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


# AsyncTerminal.@aync_ssh [
# 	(`master@127.0.0.1`, `tty`),
# 	(`master@127.0.0.1`, `echo `haha whut``),
# ] 

