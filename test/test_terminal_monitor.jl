using Pkg
Pkg.activate()
#%%
using AsyncTerminal
using Base: RawFD

# Create a monitored terminal and get its PTY
ttys, monitor_ptys = AsyncTerminal.start_x_tty_monitored(1, "zsh")
#%%
tty, monitor_pty = first(ttys), first(monitor_ptys)

println("Terminal created and monitored. Sending test commands...")
sleep(1)

# Send test commands
write(tty, """
echo "=== Starting Test ==="
ls -la
echo "Current directory: \$(pwd)"
echo "=== Test Complete ==="\n
""")
flush(tty)

# Read from monitor PTY with error handling
buffer = Vector{UInt8}(undef, 1024)
println("\nMonitor output (Ctrl+C to stop):")

try
    # Set non-blocking mode on master fd
    flags = ccall(:fcntl, Cint, (RawFD, Cint, Cint), monitor_pty.master_fd, 3, 0)  # F_GETFL = 3
    ccall(:fcntl, Cint, (RawFD, Cint, Cint), monitor_pty.master_fd, 4, flags | 2048)  # F_SETFL = 4, O_NONBLOCK = 2048
    
    while true
        n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), 
                 monitor_pty.master_fd, buffer, length(buffer))
        
        if n < 0 && Base.Libc.errno() != Base.Libc.EAGAIN
            error("Read error on PTY: $(Base.Libc.strerror())")
        elseif n > 0
            print(String(view(buffer, 1:n)))
            flush(stdout)
        end
        sleep(0.1)
    end
catch e
    if e isa InterruptException
        println("\nMonitoring stopped.")
    else
        @error "Error during monitoring" exception=e
    end
finally
    println("\nCleaning up...")
    try
        AsyncTerminal.cleanup_pty(monitor_pty)
        close(tty)
    catch cleanup_err
        @warn "Cleanup error" error=cleanup_err
    end
    end
end
