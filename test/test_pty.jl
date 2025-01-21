using Base: RawFD

function create_pty_pair()
    master = ccall(:posix_openpt, Cint, (Cint,), Base.Filesystem.JL_O_RDWR)
    master == -1 && error("Failed to open PTY master")
    
    # Setup PTY
    ccall(:grantpt, Cint, (Cint,), master) == 0 || error("grantpt failed")
    ccall(:unlockpt, Cint, (Cint,), master) == 0 || error("unlockpt failed")
    
    # Get slave path
    slave_path = unsafe_string(ccall(:ptsname, Ptr{UInt8}, (Cint,), master))
    
    return RawFD(master), slave_path
end

function monitor_terminal(target_pts::String)
    # Open target terminal and get its file descriptor
    target_file = Base.Filesystem.open(target_pts, Base.JL_O_RDWR)
    target_fd = RawFD(Base.Filesystem.fd(target_file))
    
    # Create monitoring PTY
    master_fd, slave_path = create_pty_pair()
    
    println("Monitoring $target_pts via $slave_path")
    
    buffer = Vector{UInt8}(undef, 1024)
    try
        while true
            # Read from target terminal
            n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), target_fd, buffer, sizeof(buffer))
            if n > 0
                data = String(view(buffer, 1:n))
                println("Captured: ", repr(data))
                
                # Write to master PTY
                ccall(:write, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), master_fd, buffer, n)
            end
            sleep(0.0001)
        end
    catch e
        if e isa InterruptException
            println("\nMonitoring stopped.")
        else
            @error "Monitoring failed" exception=e
        end
    finally
        # Cleanup
        Base.Filesystem.close(target_file)
        ccall(:close, Cint, (RawFD,), master_fd)
    end
end

# Usage (replace with actual pts number):
monitor_terminal("/dev/pts/12")

#%%