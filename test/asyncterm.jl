using Boilerplate: @async_showerr
using AsyncTerminal: create_ttys, get_pts_from_psaux

import REPL.Terminals: TTYTerminal
using REPL.Terminals

function read_terminal(tty::IOStream)
    buffer = Vector{UInt8}(undef, 4)
    fd = Base.Filesystem.RawFD(Base.fd(tty))
    pts = get_pts_from_psaux(tty.name)
    tty_path = "/dev/$pts"
    
    # Use more complete terminal configuration
    run(`sh -c "stty raw -echo -icanon -iexten -isig -ixon -ixoff -istrip < '$tty_path'"`)
    
    println("Started reading from terminal: $tty_path")
    
    while isopen(tty)
        try
            n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), fd, buffer, 1)
            n <= 0 && (sleep(0.001); continue)
            
            if buffer[1] == 0x1b  # Escape sequence
                chars = UInt8[buffer[1]]
                sleep(0.001)
                while bytesavailable(tty) > 0
                    n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), fd, buffer, 1)
                    n <= 0 && break
                    push!(chars, buffer[1])
                end
                println("\nReceived escape sequence: ", String(chars))
            else  # UTF-8 character
                bytes_needed = utf8_bytes_needed(buffer[1])
                for i in 2:bytes_needed
                    n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), fd, view(buffer, i:i), 1)
                    n <= 0 && break
                end
                print(String(view(buffer, 1:bytes_needed)))
            end
            flush(stdout)
        catch e
            @warn "Terminal read error" exception=e
            break
        end
    end
end

utf8_bytes_needed(first_byte::UInt8) = 
    first_byte & 0xf8 == 0xf0 ? 4 :
    first_byte & 0xf0 == 0xe0 ? 3 :
    first_byte & 0xe0 == 0xc0 ? 2 : 1

function start_input_terminals(count::Int)
    println("Creating $count terminals...")
    ttys = create_ttys(count, "zsh")
    
    for (i, tty) in enumerate(ttys)
        @async_showerr read_terminal(tty)
        write(tty, "echo 'Terminal $i ready'\n")
        flush(tty)
    end
    return ttys
end

# Example usage:
println("Starting terminals...")
ttys = start_input_terminals(1)
println("Terminals started. Press Enter to exit.")
readline() # Keep main process alive


#%%
