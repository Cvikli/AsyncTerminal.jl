using REPL
import REPL.Terminals

mutable struct TerminalInput
    term::REPL.Terminals.TTYTerminal
    original_mode::Bool
    fd::RawFD
    
    function TerminalInput()
        term = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
        fd = Base.Filesystem.RawFD(0)
        original_mode = false
        new(term, original_mode, fd)
    end
end

function enable_raw_mode(t::TerminalInput)
    t.original_mode = REPL.Terminals.raw!(t.term, true)
    # run(`stty -echo -icanon`)
    ccall(:fcntl, Int32, (RawFD, Int32, Int32), t.fd, 3, 2048)
end

function read_char(t::TerminalInput)
    buffer = Vector{UInt8}(undef, 4)
    while true
        n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), t.fd, buffer, 1)
        n <= 0 && (sleep(0.001); continue)
        
        if buffer[1] == 0x1b  # Escape sequence
            chars = UInt8[buffer[1]]
            sleep(0.001)  # Give time for full sequence
            while bytesavailable(stdin) > 0
                n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), t.fd, buffer, 1)
                n <= 0 && break
                push!(chars, buffer[1])
                sequence = String(chars)
                if haskey(special_keys, sequence)
                    return Dict("type" => "special", "key" => special_keys[sequence])
                end
            end
            return Dict("type" => "special", "key" => "ESCAPE")
        elseif buffer[1] < 32  # Control characters
            key = get(control_chars, Int(buffer[1]), "UNKNOWN_$(Int(buffer[1]))")
            return Dict("type" => "control", "key" => key)
        else  # UTF-8 character
            bytes_needed = utf8_bytes_needed(buffer[1])
            for i in 2:bytes_needed
                n = ccall(:read, Cssize_t, (RawFD, Ptr{UInt8}, Csize_t), t.fd, view(buffer, i:i), 1)
                n <= 0 && return "�"  # Return replacement char on error
            end
            try
                return String(view(buffer, 1:bytes_needed))
            catch
                return "�"  # Return replacement char on invalid UTF-8
            end
        end
    end
end

# Helper function to determine UTF-8 bytes needed
utf8_bytes_needed(first_byte::UInt8) = 
    first_byte & 0xf8 == 0xf0 ? 4 :
    first_byte & 0xf0 == 0xe0 ? 3 :
    first_byte & 0xe0 == 0xc0 ? 2 : 1

# Lookup tables
const special_keys = Dict(
    "[A" => "UP",
    "[B" => "DOWN",
    "[C" => "RIGHT",
    "[D" => "LEFT",
    "[3~" => "DELETE"
)

const control_chars = Dict(
    3 => "CTRL_C",
    4 => "CTRL_D",
    8 => "BACKSPACE",
    9 => "TAB",
    13 => "ENTER"
)

# Modified main to be callable multiple times
function main()
    println("Starting terminal input capture (Press CTRL+C or CTRL+D to exit):")
    term = TerminalInput()
    try
        # enable_raw_mode(term)
        while true
            input = read_char(term)
            if isa(input, Dict)
                input["key"] in ["CTRL_C", "CTRL_D"] && break
                print("\r\nSpecial key: ", input["key"])
            else
                print("\r\nCharacter: '$(input)'")
            end
            flush(stdout)
        end
    catch e
        println("\r\nError: ", e)
    finally
        REPL.Terminals.raw!(term.term, term.original_mode)
        println("\r\nDone.")
    end
end

main()

