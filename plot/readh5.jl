using Plots
using HDF5

t,rho,Z= h5open("dat/output.h5" , "r") do file
    println("file:")
    [println(a) for a in file]
    println(" ")
    read(file,"output/t"),read(file,"output/rho"),read(file,"output/Z")
end
println("t=",t)
println("size rho=",size(rho))

plot(t,real(rho[:,1]))
for i=2:4
plot!(t,real(rho[:,i]))
# plot!(t,imag(rho[:,i]))
end
savefig("plot/plot_h5")
