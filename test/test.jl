include("../src/AsyncTerminal.jl")
using .AsyncTerminal


# user, ip, cust_cmd = "testuser", "127.0.0.1", """echo "I am on the machine" """
# AsyncTerminal.@aync_tty [`tty`,[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], `echo "We are rocking!"`]


AsyncTerminal.@aync_ssh [
	("master@127.0.0.1", `tty`),
	("master@127.0.0.1", `echo "haha whut"`),
] 
