a = ℂ(rand(), rand())
b = ℂ(rand(), rand())
c = ℂ(rand(), rand())

## Properties of Addition ##
@test a + (-a) == 𝟎 # Identity
@test a + b == b + a # Commutativity
@test (a + b) + c == a + (b + c) # Associativity

## Properties of Multiplication ##
@test a * (𝟏 / a) == 𝟏 # Identity
@test a * b == b * a # Commutativity
@test (a * b) * c == a * (b * c) # Associativity
@test a * (b + c) == a * b + a * c # Distributive property
