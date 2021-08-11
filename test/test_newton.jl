using Test
using LinearAlgebra
using QuantumPropagators

@testset "random Hermitian state" begin

    precision = 1e-10

    # Input
    N = 1000

    X = rand(ComplexF64, (N, N))
    H = Hermitian(X)

    dt = 0.5

    Ψ₀ = rand(ComplexF64, N)
    Ψ₀ ./= norm(Ψ₀)

    @test norm(Ψ₀) ≈ 1

    # Expected
    U = exp(-im * H * dt)
    @test norm(U * U'  - one(U)) < precision  # U is unitary
    Ψ_out_expected = U * Ψ₀
    @test norm(Ψ_out_expected) ≈ 1

    Ψ = copy(Ψ₀)
    wrk = NewtonWrk(Ψ₀, 5)
    newton!(Ψ, H, dt, wrk)
    Ψ_out = copy(Ψ)
    @test_broken norm(Ψ_out) ≈ 1

    # Comparison
    @test_broken norm(Ψ_out - Ψ_out_expected) < precision

end
