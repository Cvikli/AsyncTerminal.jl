module PTYTerminal

using Base: RawFD, Filesystem

export create_pty, write_pty, read_pty, close_pty
const O_RDWR = 0x0002
const O_NOCTTY = 0x0400

export create_pty, write_pty, read_pty, close_pty

struct PTY
    master_fd::RawFD
    slave_fd::RawFD
    slave_path::String
end

function create_pty()
    # Open PTY master
    master_fd = ccall(:posix_openpt, Cint, (Cint,), O_RDWR | O_NOCTTY)
    master_fd == -1 && error("Failed to open PTY master: $(Base.Libc.strerror())")
    
    # Grant and unlock PTY
    ccall(:grantpt, Cint, (Cint,), master_fd) == 0 || error("grantpt failed")
    ccall(:unlockpt, Cint, (Cint,), master_fd) == 0 || error("unlockpt failed")
    
    # Get slave path
    slave_name = zeros(UInt8, 1024)
    ccall(:ptsname_r, Cint, (Cint, Ptr{UInt8}, Csize_t), master_fd, slave_name, length(slave_name)) == 0 || error("ptsname_r failed")
    slave_path = unsafe_string(pointer(slave_name))
    
    # Open slave end
    slave_fd = ccall(:open, Cint, (Cstring, Cint), slave_path, O_RDWR | O_NOCTTY)
    slave_fd == -1 && error("Failed to open PTY slave: $(Base.Libc.strerror())")
    
    # Set raw mode on slave using sh -c to handle quoting
    run(`sh -c "stty raw -echo -icanon -iexten -isig < $slave_path"`)
    
    PTY(RawFD(master_fd), RawFD(slave_fd), slave_path)
end


function write_pty(pty::PTY, data::Union{String,Vector{UInt8}})
    data_bytes = data isa String ? Vector{UInt8}(data) : data
    ccall(:write, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), 
          pty.master_fd, data_bytes, length(data_bytes))
end

function read_pty(pty::PTY, size::Integer=1024)
    buffer = Vector{UInt8}(undef, size)
    n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), 
              pty.master_fd, buffer, size)
    n <= 0 && return UInt8[]
    resize!(buffer, n)
    return buffer
end

function close_pty(pty::PTY)
    ccall(:close, Cint, (RawFD,), pty.master_fd)
    ccall(:close, Cint, (RawFD,), pty.slave_fd)
end
function intercept_terminal(pts_path)
    pty = create_pty()
    try
        while true
            data = read_pty(pty)
            if !isempty(data)
                @show String(data)
                flush(stdout)
            end
            sleep(0.001)
        end
    finally
        close_pty(pty)
    end
end

end # module
