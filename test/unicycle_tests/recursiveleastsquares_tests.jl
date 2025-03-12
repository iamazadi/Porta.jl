using LinearAlgebra
using GLMakie


# true value of the parameters that will be estimated 
initialPosition = 10.0
acceleration = 5.0
initialVelocity = -2.0

# noise standard deviation
noiseStd = 1.0

# simulation time
simulationTime = collect(range(0.0, stop = 15.0, length = 2000))
# vector used to store the somulated position
position = zeros(length(simulationTime))

# simulate the system behavior
for i in eachindex(simulationTime)
    position[i] = initialPosition + initialVelocity * simulationTime[i] + (acceleration * simulationTime[i]^2) / 2.0
end

# add the measurement noise 
positionNoisy = position + noiseStd .* rand(length(simulationTime))

x₀ = rand(3)
P₀ = 100.0 .* convert(Matrix{Float64}, I(3))
Rₖ = 0.5 * convert(Matrix{Float64}, I(1))

# create a recursive least squares object
recursiceleastsquares = RecursiveLeastSquares(x₀, P₀, Rₖ)

# simulate online prediction
for j in eachindex(simulationTime)
    Cₖ = [1.0; simulationTime[j]; (simulationTime[j]^2) / 2.0]
    global recursiceleastsquares = predict(recursiceleastsquares, positionNoisy[j], Cₖ)
end


## Uncomment the following for functional verification
# verify the position vector by plotting the results
# f = Figure()
# Axis(f[1, 1])

# xs = simulationTime
# ys = position

# scatterlines!(xs, ys, label = "Ideal Position", color = :green)

# ys = positionNoisy
# scatterlines!(xs, ys, label = "Observed Position", color = :blue)

# # extract the estimates in order to plot the results
# estimate1 = []
# estimate2 = []
# estimate3 = []    
# for j in eachindex(simulationTime)
#     push!(estimate1, recursiceleastsquares.estimates[j][1])
#     push!(estimate2, recursiceleastsquares.estimates[j][2])
#     push!(estimate3, recursiceleastsquares.estimates[j][3])
# end
    
# # create vectors corresponding to the true values in order to plot the results
# estimate1true = initialPosition * ones(length(simulationTime))
# estimate2true = initialVelocity * ones(length(simulationTime))
# estimate3true = acceleration * ones(length(simulationTime))

# xs = collect(1:length(simulationTime))
# ys = estimate1
# scatterlines!(xs, ys, label = "True Value of Position", color = :pink)
# ys = estimate1true
# scatterlines!(xs, ys, label = "Estimated value of Position", color = :purple)

# ys = estimate2
# scatterlines!(xs, ys, label = "True Value of Velocity", color = :orange)
# ys = estimate2true
# scatterlines!(xs, ys, label = "Estimated value of Velocity", color = :red)

# ys = estimate3
# scatterlines!(xs, ys, label = "True Value of Acceleration", color = :gray)
# ys = estimate3true
# scatterlines!(xs, ys, label = "Estimated value of Acceleration", color = :black)