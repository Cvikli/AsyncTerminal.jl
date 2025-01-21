using Base.Libc
function create_pty()
	# O_RDWR is typically 2, O_NOCTTY is typically 32768
	master_fd = ccall(:posix_openpt, Cint, (Cint,), 2 | 32768)
	if master_fd < 0
			error("Failed to open PTY master")
	end

	# Grant PTY
	ret = ccall(:grantpt, Cint, (Cint,), master_fd)
	if ret != 0
			close(master_fd)
			error("Failed to grant PTY")
	end

	# Unlock PTY
	ret = ccall(:unlockpt, Cint, (Cint,), master_fd)
	if ret != 0
			close(master_fd)
			error("Failed to unlock PTY")
	end

	# Get slave path
	slave_path = zeros(UInt8, 1024)
	ret = ccall(:ptsname_r, Cint, (Cint, Ptr{UInt8}, Csize_t), master_fd, slave_path, length(slave_path))
	if ret != 0
			close(master_fd)
			error("Failed to get slave PTY name")
	end

	# Open slave
	slave_path_str = GC.@preserve slave_path unsafe_string(pointer(slave_path))
	slave_fd = ccall(:open, Cint, (Ptr{UInt8}, Cint), slave_path_str, 2)  # O_RDWR = 2
	if slave_fd < 0
			close(master_fd)
			error("Failed to open slave PTY")
	end

	return master_fd, slave_fd
end
function interactive_tty()
    master_fd, slave_fd = create_pty()
    master_tty = Base.TTY(Base.RawFD(master_fd))
    slave_tty = Base.TTY(Base.RawFD(slave_fd))

    # Create a task to read from standard input and write to master_tty
    input_task = @async begin
        while true
            byte = read(stdin, UInt8)
            write(master_tty, byte)
        end
    end

    # Create a task to read from master_tty and print
    output_task = @async begin
        while true
            byte = read(master_tty, UInt8)
            println("Received: '$(Char(byte))' ($(byte))")
            write(slave_tty, byte)
        end
    end

    # Wait for both tasks
    wait(input_task)
    wait(output_task)
end

# Run it
interactive_tty()