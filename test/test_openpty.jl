include("pty_terminal.jl")
using .PTYTerminal

# Create PTY
pty = create_pty()
@show pty

# Test writing and reading
test_str = "Hello PTY!"
write_pty(pty, test_str)
sleep(0.1) # Give some time for data to be available

# Read and verify
data = read_pty(pty)
@show !isempty(data)
@show String(data) == test_str

# Cleanup
close_pty(pty)
