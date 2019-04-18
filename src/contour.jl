@enum ContourEnum full_contour=1 keldysh_contour=2 imaginary_contour=3

struct Contour
  branches::Vector{Branch}
  domain::ContourEnum
  function Contour(d::ContourEnum; tmax=0.0, β=0.0)
    if d == full_contour
      return new([Branch(forward_branch, tmax), Branch(backward_branch, tmax), Branch(imaginary_branch, β)], full_contour)
    elseif d == keldysh_contour
      return new([Branch(forward_branch, tmax), Branch(backward_branch, tmax)], keldysh_contour)
    else
      return new([Branch(imaginary_branch, β)], imaginary_contour)
    end
  end
end

function twist(c::Contour)
  c.branches .= circshift(c.branches, -1)
  return c
end

function get_branch(c::Contour, d::BranchEnum)
  for b in c.branches
    b.domain == d && return b
  end
  return nothing
end

"""
θ(t1, t2) = t1 >= t2 ? 1.0 : 0.0
"""
function heaviside(c::Contour, t1::BranchPoint, t2::BranchPoint)
  if t1.domain == t2.domain
    return t1.ref >= t2.ref
  else
    for b in c.branches
      b.domain == t1.domain && return true
      b.domain == t2.domain && return false
    end
  end
end

"""
Heaviside function on standard keldysh contour
"""
function heaviside(t1::BranchPoint, t2::BranchPoint)
  if t1.domain == t2.domain
    return t1.ref >= t2.ref
  else
    return t1.domain > t2.domain
  end
end

const θ = heaviside
