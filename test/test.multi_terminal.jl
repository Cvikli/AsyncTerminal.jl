# Make sure the UNIX socket does not exist yet
rm("/tmp/unix.sock", force=true)

# This is the code that the server will run
server_code = """using Sockets; foreach(s -> (println(s);run(`\$s`)), eachline(accept(listen("/tmp/unix.sock"))))"""
@show server_code

# Spawn a new julia process in a new terminal
julia = Base.julia_cmd()[1]
@show julia
cmd = `gnome-terminal -e "$julia -e '$server_code'"`
@show cmd
run(cmd, wait=false)
#%%

# Connect to the socket and send some strings to it
using Sockets
terminal_run() = begin
    s = connect("/tmp/unix.sock")
    write(s, "tty\n");   flush(s); sleep(3)
    write(s, "ls\n");   flush(s); sleep(3)
    # write(s, "Hello...\n"); flush(s); sleep(3)
    # write(s, "World!\n");   flush(s); sleep(3)
    # It can be used to redirect the output of a pipeline, too
    #%%
    # run(pipeline(`echo Hello from an other process`, stdout=s))
    run(pipeline(`echo Hello from an other process`, stdout="/dev/pts/66"))
    run(pipeline(`tty`, stdout="/dev/pts/66"))
    sleep(1)
end
#%%
println(stdout="/dev/prs/66", "Ige")
#%%
using Sockets
@async foreach(println, eachline(accept(listen("/tmp/unix3.sock"))))
#%%
s = connect("/tmp/unix3.sock")
write(s, "Hello...\n"); flush(s); sleep(3)



#%%
#%%
using Sockets

struct Terminal
    socket_file::String
    socket
end
using Base: run
function Base.run(terminal::Terminal, cmds::String; auth::String="")
    println(cmds)
    if auth === ""
        write(terminal.socket, """$(cmds)\n"""); flush(terminal.socket);
    else
        write(terminal.socket, """ssh -t $auth "$(cmds)\n" """); flush(terminal.socket);
    end
end
create_terminal() = begin
    tmp_file = tempname() * ".sock"
    rm(tmp_file, force=true)

    julia = Base.julia_cmd()[1]
    server_code = """using Sockets; for s in eachline(accept(listen("$tmp_file"))) 
    try
        println(s)
        run(`\$s`)
    catch e
        println(e) 
    end
end"""
    Base.run(`gnome-terminal -e "$julia -e '$server_code'"`, wait=false)

    sleep(1)

    tmp_socket = connect(tmp_file)
    Terminal(tmp_file, tmp_socket)
end
t = create_terminal()
run(t, "ls", auth="")
run(t, "echo \"Hello from an other process\"", auth="")
run(t, """echo "Hello from an other process" \n""", auth="")
run(t, "ls", auth="")
# runn(t, `ls`)
#%%

@edit run(`ls`)

