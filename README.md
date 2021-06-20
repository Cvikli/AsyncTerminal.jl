Run @async BUT in terminals. 
The code is about 40 lines... if you want just use it.

# How?
```julia
@aync_tty [`tty`,[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], `echo "We are rocking!"`]
```
This runs 3 terminal with the specified commands.

*BEST*
Multiple ssh run simultaneously with prespecified commands!
```julia
@aync_tty [`tty`,[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], `echo "We are rocking!"`]
```

# Why?
I needed this to open several terminal and see the output continuously of different runs. 

# Caveats
There is a slight chance that if you simultaneously open a terminal when the call "reserve" the terminal sessions, then the code can take ownership of your terminal and run the commands in your just opened terminal. But this is really like 0.0001s when those terminal opens at the calls. 
