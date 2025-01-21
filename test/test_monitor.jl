using AsyncTerminal

# Create a monitored terminal
ttys, monitor_fds = AsyncTerminal.start_x_tty_monitored(1, "bash")
tty, monitor_fd = first(ttys), first(monitor_fds)

# Write test command with clear output markers
write(tty, "echo '=== START TEST ==='; ls -l; echo '=== END TEST ==='\n")
flush(tty)

# Create IOStream from the monitor file descriptor
monitor_io = fdio(Base.cconvert(Cint, monitor_fd))

# Read from monitor buffer
buffer = Vector{UInt8}(undef, 1024)
println("Reading monitor output (Ctrl+C to stop):")
try
    while true
        if bytesavailable(monitor_io) > 0
            n = readbytes!(monitor_io, buffer)
            if n > 0
                print(String(view(buffer, 1:n)))
                flush(stdout)
            end
        end
        sleep(0.05)
    end
catch e
    if e isa InterruptException
        println("\nMonitoring stopped.")
    else
        rethrow(e)
    end
finally
    close(monitor_io)
    close(tty)
end
