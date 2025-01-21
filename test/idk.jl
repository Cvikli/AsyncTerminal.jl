

# for _ in 1:2
#     start_input_terminal()
# end



#%%
using AsyncTerminal: create_ttys
function start_input_terminals(count::Int)
    ttys = create_ttys(count, "julia")
    for tty in ttys
        write(tty, """include("$(pwd())/terminal_input.jl")\n""")
        flush(tty)
    end
    return ttys
end

# Example usage:
ttys = start_input_terminals(2)


function start_input_terminal()
	pts_ls = read(`ls /dev/pts`, String)
	run(`gnome-terminal -- julia -e "include(\"$(pwd())/terminal_input.jl\")"`, wait=false)
	sleep(0.5) # Give time for terminal to start
	new_pts_ls = read(`ls /dev/pts`, String)
	
	pts_nums = parse.(Int, split(pts_ls, '\n')[1:end-2])
	new_pts_nums = parse.(Int, split(new_pts_ls, '\n')[1:end-2])
	new_t_id = first(setdiff(new_pts_nums, pts_nums))
	
	return new_t_id
end