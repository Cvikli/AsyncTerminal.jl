using Revise 

includet("../src/AsyncTerminal.jl")
using .AsyncTerminal: aync_tty, aync_ssh, @aync_tty, @aync_ssh 


# user, ip, cust_cmd = "testuser", "127.0.0.1", """echo "I am on the machine" """
terms = aync_tty([
	`tty`,
	(`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`), 
	`echo "We are rocking!"`
])
@show terms
#%%
@aync_tty [
	`tty`,
	(`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`), 
	`echo "We are rocking!"`
]
#%%

run_on(term1, `tty`)

#%%
aync_tty([
	(`ssh six@192.168.0.100`, `tty`, `echo "I am on the machine"`),
	(`tty`),
	(`tty`, `echo "I am on the machine"`)
])

#%%
aync_ssh([
	("six@192.168.0.100", `tty`),
	(nothing, `tty`),
	("six@192.168.0.100", `tty`)
])
#%%
@aync_ssh [
	("six@192.168.0.100", `tty`),
	(nothing, `tty`),
	("six@192.168.0.100", `tty`)
]


# AsyncTerminal.@aync_ssh [
# 	("master@127.0.0.1", `tty`),
# 	("master@127.0.0.1", `echo "haha whut"`),
# ] 

# #%%
# f(x)= x.*3
# @async f([3,4,5])
