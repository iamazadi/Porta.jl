export haspair
export hastwopair
export hasthreeofakind
export hasstraight
export ranktoangle
export angletorank
export angletou1
export u1toangle


"""
    haspair(hand::Hand)

Check whether there are two Cards with the same rank
with the given Hand.
"""
function haspair(hand::Hand)
    ranks = [card.rank for card in hand.cards]
    first = firstindex(ranks)
    last = lastindex(ranks)
    for i in first:last
        for j in i+1:last
            if ranks[i] == ranks[j]
                return true
            end
        end
    end
    false
end


"""
    hastwopair(hand::Hand)

Check whether there are two pairs of Cards with the same rank
with the given Hand.
"""
function hastwopair(hand::Hand)
    pairs = 0
    ranks = [card.rank for card in hand.cards]
    first = firstindex(ranks)
    last = lastindex(ranks)
    for i in first:last
        for j in i+1:last
            if ranks[i] == ranks[j]
                pairs += 1
            end
        end
    end
    pairs == 2 ? true : false
end


"""
    hasthreeofakind(hand::Hand)

Check whether there are three Cards with the same rank
with the given Hand.
"""
function hasthreeofakind(hand::Hand)
    ranks = [card.rank for card in hand.cards]
    first = firstindex(ranks)
    last = lastindex(ranks)
    for i in first:last
        for j in i+1:last
            for k in j+1:last
                if ranks[i] == ranks[j] == ranks[k]
                    return true
                end
            end
        end
    end
    false
end


"""
    ranktoangle(x, n=13)

Map {1 ≤ x ≤ n | x ∈ ℕ} to {0 < y ≤ 2π | y ∈ ℝ}.
"""
ranktoangle(x, n=13) = 2pi .* (x ./ n)


"""
    angletorank(x, n=13)

Map {0 < y ≤ 2π | y ∈ ℝ} to {1 ≤ x ≤ n | x ∈ ℕ}.
"""
angletorank(x, n=13) = Int.(round.(n .* x ./ 2pi))


"""
    angletou1(x)

Map {0 < x ≤ 2π | x ∈ ℝ} to {|y|² = 1 | y ∈ ℂ}.
"""
angletou1(x) = exp.(im .* (x .- pi))


"""
    u1toangle(x)

Map {|x|² = 1 | x ∈ ℂ} to {0 < y ≤ 2π | y ∈ ℝ}.
"""
u1toangle(x) = real.(log.(x) ./ im) .+ pi


"""
    hasstraight(hand::Hand)

Check whether there are five Cards with the same rank
with the given Hand.
"""
function hasstraight(hand::Hand)
    maxoffset = length(hand.cards) - 5
    if maxoffset < 0
        return false
    end
    sequence = []
    ranks = sort([card.rank for card in hand.cards])
    θ = ranktoangle(ranks) # dθ ≤ θ ≤ 2π
    first = firstindex(θ)
    last = lastindex(θ)
    θ = [θ; θ[begin]]
    for offset in 0:maxoffset
        a = collect(1:5)
        b = angletorank(θ[first+offset:last+offset])
        b = angleorank(ranktoangle(b) .+ ranktoangle(1))
        if isapprox(a, b)
            sequence = b
            break
        end
    end
    if length(sequence) ≥ 4 # There is a straight sequence
        if 1 ∈ sequence # There is Ace in the Hand at the beginning or end
            if sequence[1] == 1
                return true
            end
        else
            return true
        end
    else
        return false
    end
end
