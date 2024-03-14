@show "hey"
ret = ccall((:open, "libc.so.6"), Cint, (Cstring, Cint), "/dev/ptmx",2) 
@show ret
ret2 = ccall((:grantpt, "libc.so.6"), Cint, (Cint,), ret) 
ret3 = ccall((:unlockpt, "libc.so.6"), Cint, (Cint,), ret) 
@show ret
# ret2 = ccall((:unlockpt, "libc.so.6"), Cint, (Cint,), ret) 
# @show ret2
# ret3 = ccall((:unlockpt, "libc.so.6"), Cint, (Cint,), ret) 
# @show ret3
#%%
pts_file = ccall((:open, "libc.so.6"), Cint, (Cstring, Cint), "/dev/ptmx",2) 
ret2 = ccall((:grantpt, "libc.so.6"), Cint, (Cint,), pts_file) 
ret3 = ccall((:unlockpt, "libc.so.6"), Cint, (Cint,), pts_file) 
pts_file_url = ccall((:ptsname, "libc.so.6"), Ptr{UInt8} , (Cint,), pts_file) 
@show unsafe_string(pts_file_url)
#%%
# ret = @ccall "libc.so.6".open("/dev/ptmx"::String,2::Int32)::Int32
# ret = @ccall "libmean.so.6".mean(2.0::Float64, 5.0::Float64)::Float64
# ret = ccall((:mean,"libmean"),Float64,(Float64,Float64),2.0,5.0)
#%%
ret = ccall((:ptsname, "libc.so.6"), Ptr{UInt8} , (Cint,), 2) 
# @show String(ret)
#%%
@show unsafe_string(ret)
#%%
ret = ccall((:ttyname, "libc.so.6"), Cint, (Cint,), 1) 

#%%
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
# user, ip, cust_cmd = "testuser", "127.0.0.1", """echo "I am on the machine" """
@aync_tty [`tty`,[`echo "haha whut"`, `tty`, `echo "I am on the machine"`, `echo "hell"`], `echo "We are rocking!"`]
#%%
fn(user,ip) = begin
    term_pts = get_next_pts_nums(1)[1]
    run(`gnome-terminal -- zsh`)
    @async begin 
        term_io = open("/dev/pts/$term_pts","w")
        auth= `ssh -i \~/.ssh/home_nb -t $user@$ip`
        run(`$auth echo "hello cmd"`,term_io,term_io,term_io)
        run(`$auth tty`,term_io,term_io,term_io)
        run(`$auth echo helllo`,term_io,term_io,term_io)
    end
end
fn("marcellhavlik", "35.195.22.176")
sleep(1)
#%%
res
# f = open("/dev/pts/ptmx", "r+") 
# @show "hey"
# file = fd(f)
# @show "hey3"
# ret = ccall((:grantpt, "libc.so.6"), Cint, (Cint,), file) 
# @show ret
# ret2 = ccall((:unlockpt, "libc.so.6"), Cint, (Cint,), file) 
# @show "hey2"
# @show ret2
# ret3 = ccall((:ptsname, "libc.so.6"), Cint, (Cint,), file) 
# @show "hey2"
# @show ret3

# fd_master = open("/dev/ptmx", O_RDWR); 
# grantpt(fd_master); 
# unlockpt(fd_master); 
# slave = ptsname(fd_master); 


# read(f, 2)
