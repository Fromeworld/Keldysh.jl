c= h5open("dat/output.h5" , "r") do file
    println("file:")
    [println(a) for a in file]
    println(" ")
end
