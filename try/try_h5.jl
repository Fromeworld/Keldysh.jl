A = collect(reshape(1:120, 15, 8))
h5open("dat/test2.h5" , "w") do file
    write(file, "mygroup2/A", A)
end

println("A:")
println(A)

c= h5open("dat/test2.h5" , "r") do file
    data = read(file, "mygroup2/A")
    println("file:")
    [println(a) for a in file]
    println("data")
    println(data)
end



