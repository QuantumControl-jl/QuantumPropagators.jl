using Test
using Logging
using LinearAlgebra

using QuantumPropagators
using QuantumPropagators: Generator, Operator
using QuantumPropagators.Interfaces: check_generator, check_state
using QuantumControlTestUtils.RandomObjects: random_matrix, random_state_vector
using QuantumControlTestUtils: QuantumTestLogger
_OT(::Generator{OT,AT}) where {OT,AT} = OT
_AT(::Generator{OT,AT}) where {OT,AT} = AT
_OT(::Operator{OT,CT}) where {OT,CT}  = OT
_CT(::Operator{OT,CT}) where {OT,CT}  = CT



@testset "standard Hamiltonians" begin

    H₀ = random_matrix(5; hermitian=true)
    H₁ = random_matrix(5; hermitian=true)
    ϵ₁ = t -> 1.0
    H₂ = random_matrix(5; hermitian=true)
    ϵ₂ = t -> 1.0

    H = hamiltonian(H₀)
    @test H ≡ H₀

    H = hamiltonian(H₀, H₁)
    @test H isa Matrix
    @test norm(H - H₀ - H₁) < 1e-14

    H = hamiltonian(H₀, (H₁, ϵ₁))
    @test H isa Generator
    @test _OT(H) == Matrix{ComplexF64}
    @test _AT(H) <: Function
    @test _AT(H) == typeof(ϵ₁)
    @test length(H.ops) == 2
    @test length(H.amplitudes) == 1
    @test (length(H.ops) - length(H.amplitudes)) == 1
    @test H.ops[1] ≡ H₀
    @test H.ops[2] ≡ H₁
    @test H.amplitudes[1] ≡ ϵ₁

    H = hamiltonian(H₀, (H₁, ϵ₁), (H₂, ϵ₂))
    @test H isa Generator
    @test _OT(H) == Matrix{ComplexF64}
    @test _AT(H) == Function
    @test length(H.ops) == 3
    @test length(H.amplitudes) == 2
    @test (length(H.ops) - length(H.amplitudes)) == 1
    @test H.ops[1] ≡ H₀
    @test H.ops[2] ≡ H₁
    @test H.ops[3] ≡ H₂
    @test H.amplitudes[1] ≡ ϵ₁
    @test H.amplitudes[2] ≡ ϵ₂
    @test startswith(repr(H), "Generator(Matrix{ComplexF64}")
    repl_repr = repr("text/plain", H; context=(:limit => true))
    @test startswith(repl_repr, "Generator with 3 ops and 2 amplitudes")
    @test contains(repl_repr, "ops::Vector{Matrix{ComplexF64}}")
    @test contains(repl_repr, "amplitudes::Vector{Function}")

    H = hamiltonian(H₀, (H₁, ϵ₁), (H₂, ϵ₁))
    @test H isa Generator
    @test length(H.ops) == 2
    @test length(H.amplitudes) == 1
    @test (length(H.ops) - length(H.amplitudes)) == 1
    @test H.ops[1] ≡ H₀
    @test norm(H.ops[2] - H₁ - H₂) < 1e-14
    @test H.amplitudes[1] ≡ ϵ₁

    H = hamiltonian(H₀, (H₁, ϵ₁), (H₁, ϵ₂))
    @test H isa Generator
    @test length(H.ops) == 3
    @test length(H.amplitudes) == 2
    @test (length(H.ops) - length(H.amplitudes)) == 1
    @test H.ops[1] ≡ H₀
    @test H.ops[2] ≡ H₁
    @test H.ops[3] ≡ H₁
    @test H.amplitudes[1] ≡ ϵ₁
    @test H.amplitudes[2] ≡ ϵ₂

    H = hamiltonian(H₀, (H₁, ϵ₁), H₂)
    @test H isa Generator
    @test length(H.ops) == 2
    @test length(H.amplitudes) == 1
    @test (length(H.ops) - length(H.amplitudes)) == 1
    @test norm(H.ops[1] - H₀ - H₂) < 1e-14
    @test H.amplitudes[1] ≡ ϵ₁

end


@testset "Hamiltonian interface" begin
    H₀ = random_matrix(5; hermitian=true)
    H₁ = random_matrix(5; hermitian=true)
    ϵ₁ = t -> 1.0
    H₂ = random_matrix(5; hermitian=true)
    ϵ₂ = t -> 1.0
    H = hamiltonian(H₀, (H₁, ϵ₁), H₂)
    Ψ = random_state_vector(5)
    tlist = collect(range(0, 2; length=20))
    @test check_state(Ψ; normalized=true)
    @test check_generator(H; state=Ψ, tlist, for_parameterization=true)
end


@testset "pathological Hamiltonians" begin

    H₀ = random_matrix(5; hermitian=true)

    @test_throws ErrorException("Generator has no terms") begin
        H = hamiltonian()
    end

    @test_throws ErrorException("A Generator requires at least one amplitude") begin
        G = Generator([H₀], [])
    end

end


@testset "vector control Hamiltonians" begin

    H₀ = random_matrix(5; hermitian=true)
    H₁ = random_matrix(5; hermitian=true)
    ϵ₁ = rand(10)
    H₂ = random_matrix(5; hermitian=true)
    ϵ₂ = rand(10)

    H = hamiltonian(H₀, (H₁, ϵ₁), (H₂, ϵ₂))
    @test H isa Generator
    @test _OT(H) == Matrix{ComplexF64}
    @test _AT(H) == Vector{Float64}
    @test startswith(repr(H), "Generator(Matrix{ComplexF64}")
    repl_repr = repr("text/plain", H; context=(:limit => true))
    @test startswith(repl_repr, "Generator with 3 ops and 2 amplitudes")
    @test contains(repl_repr, "ops::Vector{Matrix{ComplexF64}}")
    @test contains(repl_repr, "amplitudes::Vector{Vector{Float64}}")

end


@testset "pathological Hamiltonians" begin

    H₀_r = random_matrix(5; complex=false)
    H₀ = random_matrix(5; hermitian=true)
    H₁ = random_matrix(5; hermitian=true)
    ϵ₁ = t -> 1.0
    H₂ = random_matrix(5; hermitian=true)
    ϵ₂ = t -> 1.0
    ϵ₂_v = rand(10)

    @test_logs (:warn, "Collected amplitudes are of disparate types") begin
        H = hamiltonian(H₀, (H₁, ϵ₁), (H₂, ϵ₂_v))
    end
    @test H isa Generator
    @test _OT(H) == Matrix{ComplexF64}
    @test _AT(H) == Any
    @test startswith(repr(H), "Generator(Matrix{ComplexF64}")

    H = hamiltonian(nothing, (nothing, ϵ₁), (nothing, ϵ₂))
    @test startswith(repr(H), "Generator([nothing, nothing, nothing], Function[")
    repl_repr = repr("text/plain", H; context=(:limit => true))
    @test startswith(repl_repr, "Generator with 3 ops and 2 amplitudes")
    @test contains(repl_repr, "ops::Vector{Nothing}")
    @test contains(repl_repr, "amplitudes::Vector{Function}")

    logger = QuantumTestLogger()
    with_logger(logger) do
        try
            H = hamiltonian((H₀, (H₁, ϵ₁), (H₂, ϵ₂)))
        catch
        end
    end
    @test "Warn: Generator terms may not have been properly expanded" ∈ logger

    logger = QuantumTestLogger()
    with_logger(logger) do
        try
            H = hamiltonian([H₀, (H₁, ϵ₁), (H₂, ϵ₂)])
        catch
        end
    end
    @test "Warn: Generator terms may not have been properly expanded" ∈ logger

    logger = QuantumTestLogger()
    with_logger(logger) do
        H = hamiltonian((H₀, (H₁, ϵ₁)))
    end
    @test "Warn: Generator terms may not have been properly expanded" ∈ logger

    logger = QuantumTestLogger()
    with_logger(logger) do
        H = hamiltonian([H₀, (H₁, ϵ₁)])
    end
    @test "Warn: Generator terms may not have been properly expanded" ∈ logger

    logger = QuantumTestLogger()
    with_logger(logger) do
        try
            H = hamiltonian(H₀_r, (H₁, ϵ₁, ϵ₂))
            @test "raised Exception" == ""
        catch exc
            @test exc == ErrorException("time-dependent term must be 2-tuple")
        end
    end

    logger = QuantumTestLogger()
    with_logger(logger) do
        try
            H = hamiltonian(H₀_r, ϵ₁, (H₂, ϵ₂))
        catch exc
        end
    end
    @test "Error: Collected drift operators are of a disparate type" ∈ logger

    logger = QuantumTestLogger()
    with_logger(logger) do
        H = hamiltonian((ϵ₁, H₁), (ϵ₂, H₂))
    end
    @test "Warn: It looks like (op, ampl) in term are reversed" ∈ logger
    @test "Warn: Collected operators are not of a concrete type" ∈ logger

    logger = QuantumTestLogger()
    with_logger(logger) do
        H = hamiltonian(H₀, (ϵ₁, H₁), (ϵ₂, H₂))
    end
    @test "Warn: It looks like (op, ampl) in term are reversed" ∈ logger
    @test "Warn: Collected operators are not of a concrete type: Any" ∈ logger
    #@test r"Error: evaluate.* for amplitude does not return a number" ∈ logger
    #@test "Warn: Collected amplitude #1 is invalid" ∈ logger
    #@test "Warn: Collected amplitude #2 is invalid" ∈ logger
    @test startswith(repr(H), "Generator(Any[ComplexF64[")
    repl_repr = repr("text/plain", H; context=(:limit => true))
    @test startswith(repl_repr, "Generator with 3 ops and 2 amplitudes")
    @test contains(repl_repr, "ops::Vector{Any}")
    @test contains(repl_repr, "amplitudes::Vector{Matrix{ComplexF64}}")

end
