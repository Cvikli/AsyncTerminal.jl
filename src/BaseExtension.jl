
using Base: run


Base.run(t_io::IOStream, cmd::Cmd) = begin
	# run(`echo "$cmd"`, t_io, t_io, t_io)  # print the command
	write(t_io, "$(cmd)\n")  									# print the command
	flush(t_io)
	run(cmd, t_io, t_io, t_io)            # run the command
end
Base.run(t_io::IOStream, cmds::Tuple)                  = for cmd in cmds run(t_io,cmd) end
Base.run(t_io::IOStream, cmds::NTuple{N, Cmd}) where N = for cmd in cmds run(t_io,cmd) end
Base.run(t_io::IOStream, cmds::Vector{Cmd})            = for cmd in cmds run(t_io,cmd) end 


