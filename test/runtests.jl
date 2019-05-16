#!/usr/bin/env julia

using Keldysh, Test, LinearAlgebra

@testset "branch" begin
  let tmax = 2.0, β = 3.0
    fwd = Branch(forward_branch, tmax)
    back = Branch(backward_branch, tmax)
    imag = Branch(imaginary_branch, β)

    @test fwd.domain == forward_branch
    @test back.domain == backward_branch
    @test imag.domain == imaginary_branch

    @test length(fwd) == tmax
    @test length(back) == tmax
    @test length(imag) == β

    @test fwd(0.0).val == 0.0
    @test fwd(1.0).val == tmax

    @test back(0.0).val == tmax
    @test back(1.0).val == 0.0

    @test imag(0.0).val == 0.0
    @test imag(1.0).val == -1.0im * β
  end
end

@testset "contour" begin
  let c = Contour(full_contour, tmax=2.0, β=5.0)
    for i in 1:3
      @test c.branches[i].domain == BranchEnum(i)
    end

    c = twist(c)
    for i in 1:3
      @test c.branches[i].domain == BranchEnum(mod1(i+1, 3))
    end

    @test nbranches(full_contour) == 3
    @test nbranches(keldysh_contour) == 2
    @test nbranches(imaginary_contour) == 1

    for b in instances(BranchEnum)
      @test get_branch(c, b).domain == b
    end
  end
end

@testset "time_grid" begin
  let tmax = 2.0, β = 5.0, npts_real=21, npts_imag=51
    c = Contour(full_contour, tmax=tmax, β=β)
    grid = TimeGrid(c, npts_real=npts_real, npts_imag=npts_imag)
    @test grid.step[1] ≈ 0.1
    @test grid.step[2] ≈ -0.1
    @test grid.step[3] ≈ -0.1im
    @test map(p -> p.idx, grid) == 1:(2npts_real + npts_imag)

    for i in 1:3
      @test grid.branch_bounds[i][1].val == grid.contour.branches[i](0.0)
      @test grid.branch_bounds[i][2].val == grid.contour.branches[i](1.0)
    end

    @test β == Keldysh.get_beta(grid, nothing)
    @test_throws AssertionError Keldysh.get_beta(grid, β)

    @test integrate(t -> 1, grid) ≈ -1.0im * β
  end

  let tmax = 2.0, β = 5.0, npts_real = 21
    c = Contour(keldysh_contour, tmax=tmax)
    grid = TimeGrid(c, npts_real=npts_real)
    @test grid.step[1] ≈ 0.1
    @test grid.step[2] ≈ -0.1
    @test map(p -> p.idx, grid) == 1:(2npts_real)

    for i in 1:2
      @test grid.branch_bounds[i][1].val == grid.contour.branches[i](0.0)
      @test grid.branch_bounds[i][2].val == grid.contour.branches[i](1.0)
    end

    @test_throws AssertionError Keldysh.get_beta(grid, nothing)
    @test β == Keldysh.get_beta(grid, β)
  end

  let tmax = 2.0, c = Contour(keldysh_contour, tmax=tmax)
    grid = TimeGrid(c, npts_real=51)

    Δt1 = TimeGF(grid) do t1, t2
      t1.val.val - t2.val.val
    end

    Δt2 = TimeGF(grid) do t1, t2
      integrate(t -> 1.0, grid, t1, t2)
    end
    @test Δt1 ≈ Δt2
  end

  let tmax = 2.0, c = twist(Contour(keldysh_contour, tmax=tmax))
    grid = TimeGrid(c, npts_real=51)

    Δt1 = TimeGF(grid) do t1, t2
      t1.val.val - t2.val.val
    end

    Δt2 = TimeGF(grid) do t1, t2
      integrate(t -> 1.0, grid, t1, t2)
    end
    @test Δt1 ≈ Δt2
  end

end

@testset "generate_gf" begin
  let tmax = 1.0, β = 1.0, ν = 1/1000, ϵ = 2.0
    c = twist(Contour(full_contour, tmax=tmax, β=β))
    grid = TimeGrid(c, npts_real=51, npts_imag=51)
    dos = ω -> Keldysh.gaussian_dos(ω, ν=ν, ϵ=ϵ)

    hyb1 = dos2gf(dos, grid)
    hyb2 = gf_1level(grid, ϵ=ϵ)

    # gf_1level is gf for a delta function spectrum
    @test isapprox(hyb1, hyb2, atol=ν, norm=x -> norm(x, Inf))

    # can't also supply β if it is part of the contour
    @test_throws AssertionError dos2gf(dos, grid, β = β)
  end
end
