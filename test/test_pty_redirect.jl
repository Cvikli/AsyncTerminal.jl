using Pkg
Pkg.activate(".")
using Test
include("pty_terminal.jl")
using .PTYTerminal
using .PTYTerminal: start_terminal_redirect

# Create PTY and start terminal redirect
pty = create_pty()
println("Creating PTY at $(pty.slave_path)")

# Start terminal
start_terminal_redirect(pty)
println("Terminal started, sending test command...")

# Send a test command
write_pty(pty, "echo 'Hello from PTY'\n")

# Read loop
try
    while true
        data = read_pty(pty)
        if !isempty(data)
            print("Received: ", String(data))
            flush(stdout)
        end
        sleep(0.1)
    end
catch e
    if e isa InterruptException
        println("\nStopping...")
    else
        rethrow(e)
    end
finally
    close_pty(pty)
end
#%%

start_terminal_redirect(pty)