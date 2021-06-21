using Revise 

includet("../src/AsyncTerminal.jl")
using .AsyncTerminal: aync_tty
aync_tty([
	`tty`,
	[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], 
	`echo "We are rocking!"`
])

#%%
terminals = aync_tty([
	(`ssh -t serverX@192.168.0.100 pwd`, `ssh -t serverX@192.168.0.100 echo "We are rocking!"`,`ssh -t serverX@192.168.0.100 "cd repo && pwd"`,`ssh -t serverX@192.168.0.100 pwd`),
	(`echo "heyyooo"`),
	])
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
macroexpand(@aync_tty [
	`tty`,
	(`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`), 
	`echo "We are rocking!"`
])
#%%

run_on(term1, `tty`)
#%%


# AsyncTerminal.@aync_ssh [
# 	(`master@127.0.0.1`, `tty`),
# 	(`master@127.0.0.1`, `echo `haha whut``),
# ] 

