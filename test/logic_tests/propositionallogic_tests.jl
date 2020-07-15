propositions = [T, F]
p = Proposition(rand(propositions))
q = Proposition(rand(propositions))
r = Proposition(rand(propositions))


## Axiom 1.1 [Commutativity] ##

@test (p * q ↔ q * p) == T
@test (p + q ↔ q + p) == T
@test ((p ↔ q) ↔ (q ↔ p)) == T


## Axiom 1.2 [Associativity] ##

@test (p * (q * r) ↔ (p * q) * r) == T
@test (p + (q + r) ↔ (p + q) + r) == T


## Axiom 1.3 [Distributivity] ##

@test (p + (q * r) ↔ (p + q) * (p + r)) == T
@test (p * (q + r) ↔ (p * q) + (p * r)) == T


## Axiom 1.4 [De Morgan]

@test (!(p * q) ↔ !p + !q) == T
@test (!(p + q) ↔ !p * !q) == T


## Axiom 1.5 [Negation] ##

@test (!!p ↔ p) == T


## Axiom 1.6 [Excluded Middle] ##

@test (p + !p ↔ T) == T


## Axiom 1.7 [Contradiction] ##

@test (p * !p ↔ F) == T


## Axiom 1.8 [Implication] ##

@test (p ⟹ q ↔ !p + q) == T


## Axiom 1.9 [Equality] ##

@test ((p ↔ q) ↔ (p ⟹ q) * (q ⟹ p)) == T


## Axiom 1.10 [or-simplification] ##

@test (p + p ↔ p) == T
@test (p + T ↔ T) == T
@test (p + F ↔ p) == T
@test (p + (p * q) ↔ p) == T


## Axiom 1.11 [and-simplification] ##

@test (p * p ↔ p) == T
@test (p * T ↔ p) == T
@test (p * F ↔ F) == T
@test (p * (p + q) ↔ p) == T


## Axiom 1.12 [Identity] ##

@test (p ↔ p) == T
