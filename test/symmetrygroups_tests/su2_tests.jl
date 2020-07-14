α = U1(rand() * 2pi)
β = U1(rand() * 2pi)
a = SU2(α, β)
b = SU2(U1(rand() * 2pi), U1(rand() * 2pi))
M = Matrix(a)
N = [α -conj(β); β conj(α)]


@test a == SU2(M)
@test size(Matrix(a)) == (2, 2)
@test a + b isa Array{Complex,2}
@test a + M isa Array{Complex,2}
@test M + a isa Array{Complex,2}
@test a + N isa Array{Complex,2}
@test N + a isa Array{Complex,2}
@test a * b isa SU2
@test a * M isa SU2
@test M * a isa SU2
@test a * N isa Array{Complex,2}
@test N * a isa Array{Complex,2}
@test a .* α isa SU2
@test α .* a isa SU2
