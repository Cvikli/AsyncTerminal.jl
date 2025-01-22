module PTYTerminal

using Base: RawFD, Filesystem

# Use the full path to libc on Linux systems
const LIBC = Base.Libc.Libdl.dlopen("/lib/x86_64-linux-gnu/libc.so.6")
const openpty = Base.Libc.Libdl.dlsym(LIBC, :openpty)

export create_pty, write_pty, read_pty, close_pty, start_terminal_redirect

mutable struct PTY
    master_fd::RawFD
    slave_fd::RawFD
    slave_path::String
    socat_process::Union{Base.Process, Nothing}
end

function create_pty()
    master_ptr = Ref{Cint}()
    slave_ptr = Ref{Cint}()
    ret = ccall(openpty, Cint,
                (Ptr{Cint}, Ptr{Cint}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                master_ptr, slave_ptr, C_NULL, C_NULL, C_NULL)
    
    ret != 0 && error("openpty failed")
    
    # Get slave path
    slave_tty = unsafe_string(ccall(:ttyname, Ptr{UInt8}, (Cint,), slave_ptr[]))
    
    # Set raw mode on slave
    run(`sh -c "stty raw -echo -icanon -iexten -isig < $slave_tty"`)
    
    PTY(RawFD(master_ptr[]), RawFD(slave_ptr[]), slave_tty, nothing)
end

function start_terminal_redirect(pty::PTY)
    # Start socat with bidirectional connection and keep terminal open
    cmd = `gnome-terminal -- zsh -c "socat STDIO,raw,echo=0 PTY,link=$(pty.slave_path),rawer; exec zsh"`
    pty.socat_process = run(cmd, wait=false)
    sleep(0.4)  # Give time for socat to establish connection
    return pty
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
    if pty.socat_process !== nothing
        kill(pty.socat_process)
    end
    ccall(:close, Cint, (RawFD,), pty.master_fd)
    ccall(:close, Cint, (RawFD,), pty.slave_fd)
end

end # module
