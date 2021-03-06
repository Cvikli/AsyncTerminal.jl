module AsyncTerminal

using Base: run

export aync_tty

# THE magic function. Prerequest the next X terminal tty number, so we can attach to them. See Readme Caveat.
get_next_pts_nums(task_num) = begin
	pts_ls = read(`ls /dev/pts`, String)
	pts_nums = parse.(Int,split(pts_ls, '\n')[1:end-2])
	sort!(pts_nums)

	pts_ids = Vector{Int}(undef,task_num)
	x, i, j = 0, 1, 1 
	while i <= task_num
			while j <=length(pts_nums) && x == pts_nums[j]
					x+=1
					j+=1
			end
			pts_ids[i] = x
			x+=1
			i+=1
	end
	pts_ids
end

Base.run(terminal_io::IOStream, cmd)  = begin
	run(`echo "$cmd"`, terminal_io, terminal_io, terminal_io) # print the command
	run(cmd, terminal_io, terminal_io, terminal_io)  # run the command
end 
Base.run(terminal_io::IOStream, cmds::NTuple{N, Cmd}) where N = for cmd in cmds run(terminal_io,cmd) end
Base.run(terminal_io::IOStream, cmds::Vector{Cmd}) = for cmd in cmds run(terminal_io,cmd) end 

open_tty(tty_count, shell="zsh") = [begin 
		run(`gnome-terminal -- $shell`)
		open("/dev/pts/$t_id", "w") 
end for t_id in get_next_pts_nums(tty_count)]

#################### @async_tty ####################
function aync_tty(cmds)
	tty_IOs = open_tty(length(cmds))
	for (tty_io,cmd) in zip(tty_IOs, cmds) @async run(tty_io, cmd) end
	return tty_IOs
end

# macro aync_tty(cmds)
# 	async_tty(cmds)
# end

end # module
