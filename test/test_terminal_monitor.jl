using AsyncTerminal

# Create a monitored terminal
ttys = create_ttys(1)
tty = first(ttys)

# Run some commands
write(tty, "echo 'Hello World'\n")
write(tty, "ls -la\n")
sleep(2)  # Give some time for commands to execute

# Clean up
terminate(tty)
