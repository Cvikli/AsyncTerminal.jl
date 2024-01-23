
# THE magic function. Prerequest the next X terminal tty number, so we can attach to them. See Readme Caveat.
get_next_pts_nums(task_num) = begin
	@assert false "This function doesn't always predict itt accurately."
	pts_ls = read(`ls /dev/pts`, String)
	pts_nums = parse.(Int,split(pts_ls, '\n')[1:end-2]) # 1:end-2 because: "x" "y" "z" "a" "b" "c" ... "ptmx" ""
	sort!(pts_nums)

	pts_ids = Vector{Int}(undef,task_num)
	x, i, j = 0, 0, 0 
	while i < task_num
			while (j+=1) <= length(pts_nums) && x == pts_nums[j]
					x+=1
			end
			pts_ids[i+=1] = x
			x+=1
	end
	@show pts_ids
	pts_ids
end
