using Plots
using JLD

d = load("dat/output.jld")
t = d["t"]
rho = d["rho"]
println(size(rho))
plot(t,real(rho[:,1]))
for i=2:4
plot!(t,real(rho[:,i]))
# plot!(t,imag(rho[:,i]))
end
savefig("plot/plot_jld")