#module Setup
#using LinearAlgebra

"""
Tool Functions
"""
function symmetrize(A::AbstractArray)
    return (A + A')/2
end

function TrExp(A::AbstractMatrix, β::Real)
    A = symmetrize(A)
    vals = eigvals(A)
    res = exp.(-β * vals) |> sum |> real
    if res < 0.
        println("Warnning: Negative tr_exp!")
    end
    return res
end

function LogTrExp(A::AbstractMatrix, β::Real)
    A = symmetrize(A)
    vals = eigvals(A)
    res = logsumexp(-β * vals) |> real
    return res
end



"""
    D: Virtual bond dimension (depends on Hamitonian)
    χ: Imaginary-time bond dimension
    d: Physical bond dimension （degrees of freedom on one Lattice site)
"""

"""
cMPS -        -
     | 1 + ϵQ |
     |  √ϵR   |
     -        -
     Q: χ × χ matrix
     R: χ × χ × (D-1) array
"""
struct cmps{T<:AbstractArray}
    Q::T
    R::T
end

function toarray(ψ::cmps)
    # size(Q) == size(R)
    (r,c) = size(ψ.Q)
    x = zeros(r,c,2)
    x[:,:,1] = ψ.Q
    x[:,:,2] = ψ.R
    return x
end

function init_cmps(χ::Integer; hermition = true)
    Q = rand(χ, χ)
    R = rand(χ, χ)
    if hermition
        Q = symmetrize(Q)
        R = symmetrize(R)
    end
    return cmps(Q,R)
end

function LinearAlgebra.dot(sl::cmps, sr::cmps, β::Real)
    li = Matrix(1.0I,size(sl.Q))
    ri = Matrix(1.0I,size(sr.Q))
    K = kron(li , sr.Q) + kron(sl.Q , ri) + kron(sl.R, sr.R)
    return TrExp(-K, β)
end

function *(sl::cmps, sr::cmps)
    li = Matrix(1.0I,size(sl.Q))
    ri = Matrix(1.0I,size(sr.Q))
    K = kron(li , sr.Q) + kron(sl.Q , ri) + kron(sl.R, sr.R)
    return -K
end

"""
cMPO -              -
     | 1 + ϵQ   √ϵL |
     |  √ϵR      P  |
     -              -
     Q: d × d matrix : Onsite terms
     R: d × d × (D-1) array   : NN interaction terms
     L: d × d × (D-1) array   : NN interaction terms
     R: d × d × (D-1) × (D-1) array : long-range interaction terms
"""
struct cmpo{T<:AbstractArray}
    Q::T  # onsite
    R::T  # interaction
    L::T  # interaction
    P::T  # long-range
end

function *(O::cmpo, S::cmps)
    Oi = Matrix(1.0I,size(O.Q))
    Si = Matrix(1.0I,size(S.Q))
    Q = kron(Oi , S.Q) + kron(O.Q , Si) + kron(O.L , S.R)
    R = kron(O.R , Si) + kron(O.P , S.R)
    return cmps(Q, R)
end

function init_cmps(χ::Integer, W::cmpo)
    # r = 0 case
    d = size(W.Q)[1];  (q,r) = divrem(log(d,χ), 1)
    ψ = cmps(W.Q, W.R)
    if r == 0
        for i = 1:Integer(q-1)  ψ = W * ψ  end
    else
        println("Not support yet :)")
        return
    end
    return ψ
end
#end # module
