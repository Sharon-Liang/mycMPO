#module utilities
import Base: kron

function pauli(symbol::Symbol)
    if symbol==:x return [0. 1.; 1. 0.]
    elseif symbol==:y return [0. -1im; 1im 0.]
    elseif symbol==:z return [1. 0.; 0. -1.]
    elseif symbol==:+ return [0. 1.; 0. 0.]
    elseif symbol==:- return [0. 0.; 1. 0.]
    else
        error("The input should be :x,:y,:z,:+,:-.")
    end
end

function delta(x::Real, η::Real)
    num = η
    den = (x^2 + η^2) * π
    return num/den
end

function ⊗(A::AbstractMatrix, B::AbstractMatrix)
    kron(A,B)
end

function ⊗(A::AbstractMatrix, B::Array{T,3}) where T<:Number
    (eltype(A) <: Complex) | (eltype(B)<: Complex) ?
        dtype = ComplexF64 : dtype = Float64
    χ1 = size(A)[1]; χ2 = size(B)[1]; D = size(B)[3]
    res = zeros(dtype,(χ1*χ2, χ1*χ2, D))
    for d = 1:D
        res[:,:,d] = A ⊗ B[:,:,d]
    end
    return res
end

function ⊗(A::Array{T,3}, B::AbstractMatrix) where T<:Number
    (eltype(A) <: Complex) | (eltype(B)<: Complex) ?
        dtype = ComplexF64 : dtype = Float64
    χ1 = size(A)[1]; χ2 = size(B)[1]; D = size(A)[3]
    res = zeros(dtype,(χ1*χ2, χ1*χ2, D))
    for d = 1:D
        res[:,:,d] = A[:,:,d] ⊗ B
    end
    return res
end

function ⊗(A::Array{T,3} where T<:Number, B::Array{T,3} where T<:Number)
    (eltype(A) <: Complex) | (eltype(B)<: Complex) ?
        dtype = ComplexF64 : dtype = Float64
    χ1 = size(A)[1]; χ2 = size(B)[1]; D = size(A)[3]
    res = zeros(dtype,(χ1*χ2, χ1*χ2))
    for d = 1:D
        res += A[:,:,d] ⊗ B[:,:,d]
    end
    return res
end

function ⊗(A::Array{T,4} where T<:Number, B::Array{T,3} where T<:Number)
    (eltype(A) <: Complex) | (eltype(B)<: Complex) ?
        dtype = ComplexF64 : dtype = Float64
    χ1 = size(A)[1]; χ2 = size(B)[1]; D = size(B)[3]
    res = zeros(dtype,(χ1*χ2, χ1*χ2,D))
    for d = 1:D
        res[:,:,d] = A[:,:,d,:] ⊗ B
    end
    return res
end

function ⊗(A::Array{T,3} where T<:Number, B::Array{T,4} where T<:Number)
    (eltype(A) <: Complex) | (eltype(B)<: Complex) ?
        dtype = ComplexF64 : dtype = Float64
    χ1 = size(A)[1]; χ2 = size(B)[1]; D = size(A)[3]
    res = zeros(dtype,(χ1*χ2, χ1*χ2, D))
    for d = 1:D
        res[:,:,d] = A ⊗ B[:,:,:,d]
    end
    return res
end

function ⊗(A::Array{T,4} where T<:Number, B::Array{T,4} where T<:Number)
    (eltype(A) <: Complex) | (eltype(B)<: Complex) ?
        dtype = ComplexF64 : dtype = Float64
    χ1 = size(A)[1]; χ2 = size(B)[1]; D = size(A)[3]
    res = zeros(dtype,(χ1*χ2, χ1*χ2, D, D))
    for d1 = 1:D, d2 = 1:D
        res[:,:,d1, d2] = A[:,:,d1,:] ⊗ B[:,:,:,d2]
    end
    return res
end

function symmetrize(A::AbstractMatrix)
    (A + A')/2
end

struct trexp{T<:Number}
    max::T
    res::T
end

function value(x::trexp)
    exp(x.max) * x.res
end

function trexp(A::AbstractMatrix)
    if ishermitian == false
        error("The input matrix should be hermitian")
    end
    A = symmetrize(A) |> Hermitian
    val= eigvals(A)
    max = maximum(val)
    res = exp.(val .- max) |> sum
    trexp(max, res)
end

function logtrexp(A::AbstractMatrix)
    if ishermitian == false
        error("The input matrix should be hermitian")
    end
    A = symmetrize(A) |> Hermitian
    eigvals(A) |> logsumexp
end

"""function manipulation"""
function grad_num(f::Function, var::AbstractArray)
    ϵ = 1.e-5
    g = similar(var)
    for i = 1:length(var)
        var[i] -= ϵ
        f1 = f(var)

        var[i] += 2ϵ
        f2 = f(var)

        g[i] = (f2 - f1)/ 2ϵ
        var[i] -= ϵ
    end
    return g
end

function grad_func(f::Function, var::AbstractArray)
    function gf(gx::AbstractArray, var::AbstractArray)
        gx[1:end] = gradient(var -> f(var),var)[1][1:end]
    end
    gf
end

#end  # module utilities
