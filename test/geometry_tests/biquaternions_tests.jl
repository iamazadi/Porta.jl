r = Quaternion(rand(), ℝ³(rand(3)))
t = 100ℝ³(rand(3))
dq1 = Biquaternion(r, t)

rotation = getrotation(dq1)
translation = gettranslation(dq1)

# Unit condition
@test isapprox(norm(dq1), 1)
@test isapprox(conj(conj(dq1)), dq1)
@test isapprox(rotation, normalize(r))
@test isapprox(translation, t)


qr = Quaternion(rand(), ℝ³(rand(3)))
qd = Quaternion([0; vec(100ℝ³(rand(3)))])
dq2 = Biquaternion(qr, qd)
q̂ = normalize(dq2)
dq3 = Biquaternion(2dq2)


@test isapprox(norm(q̂), 1)
@test isapprox(dq2, dq3) != true


## constructors

rotation = Quaternion(rand(4))
translation = ℝ³(rand(3))
q1 = Biquaternion(rotation)
q2 = Biquaternion(translation)
q = Biquaternion(rotation, translation)

@test isapprox(q2 * q1, q)
