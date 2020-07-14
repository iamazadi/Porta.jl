θ = rand() * -2π + π
a = U1(θ)
b = U1(rand())
c = U1(rand())

## Properties of the Group ##
@test isapprox(arg(a), θ)
@test isapprox(len(a), 1)

## Properties of the Unary Operators ##

@test a == +a
@test a == -(-a)

## Properties of Multiplication ##

@test a * (U1(π / 2) / a) == U1(π / 2) # Identity
@test a * b == b * a # Commutativity
@test (a * b) * c == a * (b * c) # Associativity
