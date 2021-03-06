#module PhysicalObservables
#include("Setup.jl")

"""
NN Transvers field Ising model
    H = ∑ J Zi Zj + ∑ Γ Xi
"""
function TFIsing(J::Real, Γ::Real; field::Symbol=:N)
    if field == :N
        h = zeros(2,2)
    else
        η = 1.e-2
        h = η .* pauli(field)
    end
    return cmpo(Γ*pauli(:x)+h, √J*pauli(:z), √J*pauli(:z), zeros(2,2))
end

"""
function XYmodel(; J::Real = 1.0)
    sgn = sign(J) 
    sp = pauli(:+); sm = pauli(:-);
    L = zeros(2,2,2)
    L[:,:,1] = 1/√2 * sp ; L[:,:,2] = 1/√2 * sm
    R = zeros(2,2,2)
    R[:,:,1] = -sgn*1/√2 * sm ; R[:,:,2] = -sgn*1/√2 * sp
    Q = zeros(2,2)
    P = zeros(2,2,2,2)
    return cmpo(Q,R,L,P)
end
"""
function HeisenbergModel(; J::Real=1.0)
    #AFM Heisenberg model
    sp = pauli(:+); sm = pauli(:-);
    LR = zeros(2,2,3)
    LR[:,:,1] = 1/√2 * sp ; LR[:,:,2] = 1/√2 * sm; LR[:,:,3] = pauli(:z)
    Q = zeros(2,2)
    P = zeros(2,2,3,3) 
    return cmpo(Q,LR,LR,P)
end

"""
function XXZmodel(Jx::Real, Jz::Real)
    if Jx == Jz 
        return HeisenbergModel(J=Jz)
    elseif Jz == 0
        return XYmodel(J=Jx)
    elseif Jx == 0
        return TFIsing(Jz, 0.0)
    else
        sgnz = sign(Jz) ; sgnx = sign(Jx)
        Jz = abs(Jz); Jx = abs(Jx)
        sp = pauli(:+); sm = pauli(:-);
        L = zeros(2,2,3)
        L[:,:,1] = √(Jx/2) * sp ; L[:,:,2] = √(Jx/2) * sm; L[:,:,3] = √(Jz) *pauli(:z)
        R = zeros(2,2,3)
        R[:,:,1] = -sgn * √(Jx/2) * sm ; R[:,:,2] = -sgn * √(Jx/2) * sp; R[:,:,3] = -sgn * √(Jz) *pauli(:z)
        Q = zeros(2,2)
        P = zeros(2,2,3,3)
        return cmpo(Q,R,L,P)
    end
end
"""

function make_operator(Op::AbstractArray, dim::Int)
    eye = Matrix(1.0I, dim, dim)
    return eye ⊗ Op ⊗ eye
end

function make_operator(Op::AbstractArray, ψ::cmps)
    eye = Matrix(1.0I, size(ψ.Q))
    return eye ⊗ Op ⊗ eye
end

"""
The thermal average of local opeartors ===============================
"""
function thermal_average(Op::AbstractArray, ψ::cmps, W::cmpo, β::Real)
    #eye = Matrix(1.0I, size(ψ.Q))
    #Op = eye ⊗ Op ⊗ eye
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(-β*K)
    m = maximum(e)
    Op = v' * Op * v
    den = exp.(e .- m) |> sum
    num = exp.(e .- m) .* diag(Op) |> sum
    return num/den
end

function thermal_average(Op::AbstractArray, ψ::cmps, β::Real)
    K = ψ * ψ |> symmetrize |> Hermitian
    e, v = eigen(-β*K)
    m = maximum(e)
    Op = v' * Op * v
    den = exp.(e .- m) |> sum
    num = exp.(e .- m) .* diag(Op) |> sum
    return num/den
end


"""
Thermal dynamic quanties =============================================
"""
function partitian(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    num = trexp(-β*K)
    den = trexp(-β*H)
    return exp(num.max - den.max) * num.res/den.res
end

function partitian!(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    return trexp(-β*K)
end

function free_energy(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    res = logtrexp(-β*K)- logtrexp(-β*H)
    return -1/β * res
end

function free_energy(param::Array{T,3} where T<:Number, W::cmpo, β::Real)
    free_energy(tocmps(param), W, β)
end

function energy(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    eng = thermal_average(K, ψ, W, β) - thermal_average(H, ψ, β)
    return eng
end

function specific_heat(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    K2 = K * K
    H2 = H * H
    c = thermal_average(K2, ψ, W, β) - thermal_average(K, ψ, W, β)^2
    c -= thermal_average(H2, ψ, β) - thermal_average(H, ψ, β)^2
    return β^2 * c
end

function entropy(ψ::cmps, W::cmpo, β::Real)
    s = energy(ψ,W,β) - free_energy(ψ,W,β)
    return β*s
end


"""
The local two-time correlation functions
"""
function correlation_2time(τ::Number, A::AbstractArray,B::AbstractArray,
                           ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        num += exp(-β*e[i]- m + τ*(e[i] - e[j])) * A[i,j] * B[j,i]
    end
    return num/den
end

function susceptibility(n::Integer, A::AbstractArray,B::AbstractArray,
                        ψ::cmps, W::cmpo, β::Real)
    # i ωn
    ωn = 2π * n/β  #boson
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        up = exp(- β*e[j]-m) - exp(-β * e[i]-m)
        up = up * A[i,j] * B[j,i]
        down = 1im*ωn + e[i] - e[j]
        num += up/down
    end
    return num/den |> real
end


function imag_susceptibility(ω::Real,A::AbstractArray,B::AbstractArray,
                             ψ::cmps, W::cmpo, β::Real; η::Float64 = 0.05)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        res = exp(-β*e[i]-m) - exp(-β*e[j]-m)
        res = res * A[i,j] * B[j,i] * delta(ω+e[i]-e[j],η)
        num += res
    end
    return  π*num/den
end

function structure_factor(ω::Real, A::AbstractArray,B::AbstractArray,
                        ψ::cmps, W::cmpo, β::Real; η::Float64 = 0.05)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        num += exp(-β*e[i]-m)*A[i,j]*B[j,i]*delta(ω+e[i]-e[j], η)
    end
    return num/den * 2π
end
#end  # module PhysicalObservables
