using PyPlot
using HDF5

t,rho,Z= h5open("dat/output.h5" , "r") do file
    println("file:")
    [println(a) for a in file]
    println(" ")
    read(file,"output/t"),read(file,"output/rho"),read(file,"output/Z")
end
println("t=",t)
println("size rho=",size(rho))
# PyPlot.close(p1)
p1=PyPlot.figure()
PyPlot.plot(t,real(rho[:,1]))
PyPlot.plot(t,real(rho[:,2]).+0.01)
for i=3:4
PyPlot.plot(t,real(rho[:,i]))
# PyPlot.plot(t,imag(rho[:,i]))
end
PyPlot.savefig("plot/plot_h5.png")
PyPlot.close(p1)