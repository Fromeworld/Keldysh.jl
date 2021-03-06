using QuadGK
using Elliptic

"""
Descriptor of an integrable singularity in DOS
"""
struct DOSSingularity
  # Position of the singularity, Ω_p.
  position::Real
  # Asymptotic behavior of the DOS near the singularity, S_p(ω).
  # To be chosen such that \lim_{ω \to Ω_p} [D(ω) - S_p(ω)] = 0
  asymptotics
  # Integral of 'asymptotics' over ω\in[ω_{min};ω_{max}].
  integral
end

"""
  SingularDOS represents densities of states D(ω) according to
  the following decomposition,

  D(ω) = R(ω) + \\sum_{p=1}^P S_p(ω).

  R(ω) is a smooth function on [ω_{min};ω_{max}], and the number P of
  singular contributions S_p(ω) equals the number of integrable singularities
  Ω_p of D(ω). Each term S_p(ω) is regular everywhere on
  ω\\in[ω_{min};ω_{max}] except for its corresponding ω = Ω_p.
"""
struct SingularDOS
  # Support limits
  ωmin::Real
  ωmax::Real
  # Regular part R(ω)
  regular
  # List of singularities
  singularities::Vector{DOSSingularity}
end

"""Evaluate singular DOS at a given frequency"""
function (dos::SingularDOS)(ω)
  dos.regular(ω) + sum(s.asymptotics(ω) for s in dos.singularities)
end

"""
Support limits of a DOS object
"""
dos_support_limits(dos) = (-Inf, Inf)
dos_support_limits(dos::SingularDOS) = (dos.ωmin, dos.ωmax)

"""Integrator for general DOS objects"""
function dos_integrator(f, dos; atol=1e-10, rtol=1e-10, maxevals=10^9, order=21)
  limits = dos_support_limits(dos)
  integral, err = quadgk(ω -> f(ω) * dos(ω),
                         limits[1], limits[2],
                         atol=atol, rtol=rtol, maxevals=maxevals, order=order)
  integral
end

"""
  Integrator for SingularDOS

  \\int_{ω_{min}}^{ω_{max}} dω D(ω) f(ω) =
  \\int_{ω_{min}}^{ω_{max}} dω R(ω) f(ω) +
  \\sum_{p=1}^P \\int_{ω_{min}}^{ω_{max}} dω S_p(ω) [f(ω) - f(Ω_p)] +
  \\sum_{p=1}^P f(Ω_p) \\int_{ω_{min}}^{ω_{max}} dω S_p(ω).

  The integrands in the first two terms of the RHS are smooth,
  and the value of the integral in the last term must be provided in the
  `integral` field of the corresponding `DOSSingularity` structure.
"""
function dos_integrator(f, dos::SingularDOS; atol=1e-10, rtol=1e-10, maxevals=10^9, order=21)
  limits = dos_support_limits(dos)
  val = quadgk(ω -> f(ω) * dos.regular(ω),
               limits[1], limits[2],
               atol=atol, rtol=rtol, maxevals=maxevals, order=order)[1]
  for s in dos.singularities
    f_s = f(s.position)
    val += quadgk(ω -> ω ≈ s.position ? .0 : s.asymptotics(ω) * (f(ω) - f_s),
                  limits[1], limits[2],
                  atol=atol, rtol=rtol, maxevals=maxevals, order=order)[1]
    val += f_s * s.integral
  end
  val
end

#
# DOS factory functions
#

"""
`flat_dos(;ν=1.0, D=5.0)`

return flat band DOS with half-bandwith D and inverse cutoff width ν centered at zero
"""
flat_dos(; ν=1.0, D=5.0) = ω -> (1.0/π) / ((1 + exp(ν * (ω - D))) * (1 + exp(-ν * (ω + D))))

"""
`gaussian_dos(; ϵ=1.0, ν=1.0)`

return normalized Gaussian DOS centered at ϵ with width ν
"""
gaussian_dos(; ϵ=1.0, ν=1.0) = ω -> (1.0 / (2 * sqrt(π * ν))) * exp(-((ω - ϵ)^2)/(4ν))

"""
`bethe_dos(; t=1.0)`

return normalized DOS of a Bethe lattice with hopping constant t
"""
bethe_dos(; t=1.0) = SingularDOS(-2t, 2t,
  ω -> begin
    if ω == -2t || ω == 2t
      -2 / (π*t)
    else
      x = ω / (2t)
      (sqrt(1 - x*x) - sqrt(2 * (1 - x)) - sqrt(2 * (1 + x))) / (π*t)
    end
  end,
  [
    DOSSingularity(-2t, ω -> sqrt(2 * (1 + ω / (2t))) / (π*t), 16 / (3*π)),
    DOSSingularity( 2t, ω -> sqrt(2 * (1 - ω / (2t))) / (π*t), 16 / (3*π))
  ]
)

"""
`chain_dos(; t=1.0)`

return normalized DOS of a linear chain with hopping constant t
"""
chain_dos(; t=1.0) = SingularDOS(-2t, 2t,
  ω -> begin
    if ω == -2t || ω == 2*t
      -3 / (8*π*t)
    else
      x = ω / (2t)
      rp = sqrt(2 * (1 - x))
      # The second term regularizes the derivative of near ω = 2t to ease integration
      sp = 1 / (2*π*t * rp) + rp / (16*π*t)

      rm = sqrt(2 * (1 + x))
      # The second term regularizes the derivative near ω = -2t to ease integration
      sm = 1 / (2*π*t * rm) + rm / (16*π*t)

      (1 / (2*π*t)) / sqrt(1 - x*x) - sp - sm
    end
  end,
  [
    DOSSingularity(-2t, ω -> begin
                          x = ω / (2t)
                          s = sqrt(2 * (1 + x))
                          # The second term regularizes the derivative
                          1 / (2*π*t*s) + s / (16*π*t)
                        end,
                    7 / (3*π)),
    DOSSingularity( 2t, ω -> begin
                          x = ω / (2t)
                          s = sqrt(2 * (1 - x))
                          # The second term regularizes the derivative
                          1 / (2*π*t*s) + s / (16*π*t)
                        end,
                    7 / (3*π))
  ]
)

"""
`square_dos(; t=1.0)`

return normalized DOS of a 2D square lattice with hopping constant t
"""
square_dos(; t=1.0) = SingularDOS(-4t, 4t,
  ω -> begin
    if ω ≈ 0
      0
    else
      x = ω / (4t)
      (1 / (2 * π^2 * t)) * (Elliptic.K(1 - x^2) + log(abs(x) / 4));
    end
  end,
  [
    DOSSingularity(0, ω -> -1 / (2 * π^2 * t) * log(abs(ω) / (16t)),
                   4 / (π^2) * (1 + 2 * log(2)))
  ]
)
