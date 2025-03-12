using LinearAlgebra


export RecursiveLeastSquares
export predict


"""
    Represents a Recursive Least Squares (RLS) algorithm.

fields: x₀, P₀, R, timestep, estimates, estimationErrorCovarianceMatrices, gainMatrices, and errors.
"""
struct RecursiveLeastSquares
    x₀::Vector{Float64}
    P₀::Matrix{Float64}
    R::Matrix{Float64}
    timestep::Int
    estimates::Vector{Vector{Float64}}
    estimationErrorCovarianceMatrices::Vector{Matrix{Float64}}
    gainMatrices::Vector{Matrix{Float64}}
    errors::Vector{Float64}
    RecursiveLeastSquares(x₀::Vector{Float64}, P₀::Matrix{Float64}, R::Matrix{Float64}, timestep::Int,
                          estimates::Vector{Vector{Float64}},
                          estimationErrorCovarianceMatrices::Vector{Matrix{Float64}},
                          gainMatrices::Vector{Matrix{Float64}},
                          errors::Vector{Float64}) = new(x₀, P₀, R, timestep, estimates,
                                                         estimationErrorCovarianceMatrices,
                                                         gainMatrices, errors)
    RecursiveLeastSquares(x₀::Vector{Float64}, P₀::Matrix{Float64}, R::Matrix{Float64}) = begin
        timestep = 1
        estimates = Vector{Vector{Float64}}()
        estimationErrorCovarianceMatrices = Vector{Matrix{Float64}}()
        gainMatrices = Vector{Matrix{Float64}}()
        errors = Vector{Float64}()
        push!(estimates, x₀)
        push!(estimationErrorCovarianceMatrices, P₀)
        RecursiveLeastSquares(x₀, P₀, R, timestep, estimates, estimationErrorCovarianceMatrices, gainMatrices, errors)
    end
end


"""
    predict(algorithm, measurement, Cₖ)

Compute the estimation error covariance matrix, and then update the estimate, 
next compute the gain matrix, and finally the estimation error,
with the given current `measurement` and current measurement matrix `Cₖ`.
Also, fill the fields: estimates, estimationErrorCovarianceMatrices, gainMatrices, and errors
of the recursive least squares `algorithm` instance, before incrementing the time step by 1.

`algorithm`: the instantiation of a RecursiveLeastSquares algorithm
`measurement`: the measurement obtained at the time instant k
`Cₖ`: the measurement matrix at the time instant k
"""
function predict(algorithm::RecursiveLeastSquares, measurement::Float64, Cₖ::Vector{Float64})
    x₀ = algorithm.x₀
    P₀ = algorithm.P₀
    Rₖ = algorithm.R
    k = algorithm.timestep
    Pₖ₋₁ = algorithm.estimationErrorCovarianceMatrices[k]
    yₖ = measurement
    x̂ₖ₋₁ = algorithm.estimates[k]
    dimension = length(x₀)
    # compute the Lₖ matrix and its inverse
    Lₖ = Rₖ .+ transpose(Cₖ) * Pₖ₋₁ * Cₖ
    Lₖ⁻¹ = inv(Lₖ)
    # compute the gain matrix
    Kₖ = Pₖ₋₁ * Cₖ * Lₖ⁻¹
    # compute the estimation error
    error = yₖ - transpose(Cₖ) * x̂ₖ₋₁
    # compute the estimate
    x̂ₖ = vec(x̂ₖ₋₁ + Kₖ * error)
    # propagate the estimation error covariance matrix
    Pₖ = (I(dimension) - Kₖ * transpose(Cₖ)) * Pₖ₋₁
    # add computed elements to the list
    push!(algorithm.estimates, x̂ₖ)
    push!(algorithm.estimationErrorCovarianceMatrices, Pₖ)
    push!(algorithm.gainMatrices, Kₖ)
    push!(algorithm.errors, error)
    # increment the current time step
    k = k + 1
    # return the object with updated parameters
    RecursiveLeastSquares(x₀, P₀, Rₖ, k, algorithm.estimates,
                          algorithm.estimationErrorCovarianceMatrices, algorithm.gainMatrices, algorithm.errors)
end