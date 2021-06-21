module AsyncTerminal

export @aync_tty, @aync_ssh 

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

run_cmd(cmds::NTuple{N, Cmd}, io, auth) where N = for cmd in cmds AsyncTerminal.run_cmd(cmd, io, auth) end
run_cmd(cmds::NTuple{N, Cmd}, io) where N = for cmd in cmds AsyncTerminal.run_cmd(cmd, io) end

run_cmd(cmd::Cmd, io, auth) = begin
	@show "heeeyyyooo"
	run(`echo "ssh  -oStrictHostKeyChecking=no  -t $auth $cmd"`, io, io, io) # print the command
	@show cmd
	run(`ssh -t $auth $cmd`, io, io, io)  # run the command
end
run_cmd(cmd::Cmd, io) = begin
	run(`echo "$cmd"`, io, io, io) # print the command
	run(cmd, io, io, io)  # run the command
end


run_in_terminal(cmd, t_id, auth) = begin
	run(`gnome-terminal -- zsh`)
	@show t_id
	pts_file = open("/dev/pts/$t_id", "w")
	# AsyncTerminal.run_cmd(cmd, pts_file, auth)
	pts_file
end
run_in_terminal(cmd, t_id) = begin
	run(`gnome-terminal -- zsh`)
	pts_file = open("/dev/pts/$t_id", "w")
	# AsyncTerminal.run_cmd(cmd, pts_file)
	pts_file
end

#################### @async_tty  &  @async_ssh ####################
macro aync_tty(cmds)
	eval(esc(:(
		tty_IOs = [];
		for (i,t_id) in enumerate(AsyncTerminal.get_next_pts_nums(length($cmds)))
		
				tty_IO = AsyncTerminal.run_in_terminal($cmds[i], t_id) &&	push!(tty_IOs, tty_IO)
				# println(tty_IOs)
				# @async AsyncTerminal.run_in_terminal($cmds[i], t_id)
		end;
		return tty_IOs
	)))
	
end

macro aync_ssh(remote_cmds)
	esc(:(for (i,t_id) in enumerate(AsyncTerminal.get_next_pts_nums(length($remote_cmds)))
			auth = $remote_cmds[i][1]
			cmd= $remote_cmds[i][2]
			@show cmd
			@show auth
			@async AsyncTerminal.run_in_terminal(cmd, t_id, auth)
	end))
end

end # module
