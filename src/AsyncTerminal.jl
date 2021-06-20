module AsyncTerminal

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
run_cmd(cmds::Vector{Cmd}, io) = for cmd in cmds run_cmd(cmd, io) end
run_cmd(cmd::Cmd, io) = begin
	run(`echo "$cmd"`, io, io, io) # print the command
	run(cmd, io, io, io)  # run the command
end
run_in_terminal(cmd, t_id) = begin
	run(`gnome-terminal -- zsh`)
	pts_file = open("/dev/pts/$t_id", "w")
	run_cmd(cmd, pts_file)
end
macro aync_tty(cmd)
	esc(:(for (i,t_id) in enumerate(get_next_pts_nums(length($cmd)))
			@async run_in_terminal($cmd[i], t_id)
	end))
end

end # module
