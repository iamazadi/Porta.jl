# the Hilbert-Schmidt norm and inner product
# sometimes we call them Frobenius norm and inner product
norm(h::ℍ) = sqrt(sum(map(x -> abs(x)^2, SU2(h))))
dot(g::ℍ, h::ℍ) = sum(sum(map(*, SU2(g), SU2(h)), dims=1))
