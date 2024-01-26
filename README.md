
Run @async BUT each of output in different terminal. 
The code is about 40 lines... if you want just use it.

# How?
Create terminals, then use their IO to print out. 
```julia
using Base.Threads
using AsyncTerminal: create_ttys
ttys = create_ttys(nthreads(), "zsh")
@threads for i in 1:100
	write(ttys[threadid()], "I am here $i\n") 
	flush(ttys[threadid()])
end
```
Closing the terminals if we still have the ttys ios!
```julia
using AsyncTerminal: terminate
terminate.(ttys, ["zsh"])
```
or `terminate_all_async_terminal()` that was open in this running session.

```julia
using AsyncTerminal: aync_tty
aync_tty([
	`tty`,
	[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], 
	`echo "We are rocking!"`
])
```
This runs 3 terminal with the specified commands.

*BEST*
Multiple ssh run simultaneously with prespecified commands!
```julia
terminals = aync_tty([
	(`tty`, `echo "Local server heyy"`),
	(`ssh -t SERVERX@192.168.0.23 tty"`, `ssh -t SERVERX@192.168.0.23 tty`, `ssh -t SERVERX@192.168.0.23 echo "I am on the machine"`), 
	(`ssh -t SERVER4@192.168.0.22 echo "We are rocking!"`, `echo "We are rocking!"`)
])
```
Don't forget to have some privatekey on your side.

Continuing the sessions in the terminals:
```
run(terminals[1], `echo "I am still here heyyy"`)
run(terminals[2], `ssh -t SERVERX@192.168.0.23 "cd Pictures && ls"`)
run(terminals[2], `echo "I am actually just a terminal! I still need to ressh into the session to do the command on the remote. The Cmd restart each time."`)
```


# Why?
I needed this to open several terminal and see the output of different runs. 

# TODO
- We need to close each terminal. But I just couldn't figure out how to send "exit" command to these terminal. It would be really nice to have: `terminate.(ttys)` to terminate each async terminal at once. 

# Caveats
There is a slight chance that if you simultaneously open a terminal when the call "reserve" the terminal sessions, then the code can take ownership of your terminal and run the commands in your just opened terminal. But this is really like 0.0001s when those terminal opens at the calls. 

Killing a terminal cause a problem with the terminal creation. Somehow the Ubuntu doesn't reschedule the closed session ID in the next terminal session?

# ERRORS
Error: /usr/bin/gnome-terminal.real: symbol lookup error: /snap/core20/current/lib/x86_64-linux-gnu/libpthread.so.0: undefined symbol: __libc_pthread_init, version GLIBC_PRIVATE
Solution: https://stackoverflow.com/questions/75921414/java-symbol-lookup-error-snap-core20-current-lib-x86-64-linux-gnu-libpthread
"terminal.integrated.env.linux": {
    "GTK_PATH": ""
},


