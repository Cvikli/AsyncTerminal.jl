using Revise
includet("../src/AsyncTerminal.jl")

# user, ip, cust_cmd = "testuser", "127.0.0.1", """echo "I am on the machine" """
@aync_tty [`tty`,[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], `echo "We are rocking!"`]
