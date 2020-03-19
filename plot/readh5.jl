t,s= h5open("dat/output.h5" , "r") do file
    println("file:")
    [println(a) for a in file]
    println(" ")
    read(file,"output/t"),read(file,"output/t")
end
println("t=",t)
println("s=",s)

# read multiple var?