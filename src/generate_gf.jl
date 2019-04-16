using QuadGK

"""
check/get β from contour or explicitly given value
"""
function get_beta(grid::TimeGrid, β)
  im_b = get_branch(grid.contour, imaginary_branch)
  @assert (im_b === nothing && β !== nothing) || (im_b !== nothing && β === nothing)
  β === nothing ? length(im_b) : β
end

function make_gf(f, grid)
  f.(grid.points, permutedims(grid.points))
end

function gf_1level(grid::TimeGrid; ϵ, β=nothing)
  β = get_beta(grid, β)
  make_gf(grid) do t1, t2
    -1.0im * (θ(t1, t2) - fermi(ϵ, β)) * exp(-1.0im * (t1.val - t2.val) * ϵ)
  end
end

function dos2gf(grid::TimeGrid; dos, β=nothing, D=100.0)
  β = get_beta(grid, β)

#  make_gf(grid) do t1, t2
#    integral, err = quadgk(ω -> dos(ω) * (θ(t1, t2) - fermi(ω, β)) * exp(-1.0im * (t1.val - t2.val) * ω), -Inf, Inf)
#    return integral
#  end

  make_gf(grid) do t1, t2
    theta = θ(t1, t2)
    Δt = t1.val - t2.val
    integrand = ω -> dos(ω) * (ω > 0.0 ? exp(-1.0im * ω * (Δt - 1.0im * (1.0 - theta) * β)) / (exp(-β * ω) + 1) :
                                         exp(-1.0im * ω * (Δt + 1.0im * theta * β)) / (exp(β * ω) + 1))
    integral, err = quadgk(integrand, -D, D, atol=1e-10, rtol=1e-10, maxevals=10^8)
    return -1.0im * (2 * theta - 1) * integral
  end
end

function bare_prop(grid::TimeGrid; levels, β=nothing)
  β = get_beta(grid, β)
end
