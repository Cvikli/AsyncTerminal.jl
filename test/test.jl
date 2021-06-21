include("../src/AsyncTerminal.jl")
using .AsyncTerminal


# user, ip, cust_cmd = "testuser", "127.0.0.1", """echo "I am on the machine" """
terms = AsyncTerminal.@aync_tty [
	`tty`,
	(`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`), 
	`echo "We are rocking!"`
]
@show terms
#%%
@show "ok"

# @aync_tty [
# 	(term1, `tty`),
# 	(term2, `tty`)
# ]


# AsyncTerminal.@aync_ssh [
# 	("master@127.0.0.1", `tty`),
# 	("master@127.0.0.1", `echo "haha whut"`),
# ] 

# #%%
# f(x)= x.*3
# @async f([3,4,5])
