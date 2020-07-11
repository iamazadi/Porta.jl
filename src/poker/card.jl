import Base.isless
export Card


const suitnames = ["♣", "♢", "♡", "♠"]
const rank_names = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]


"""
    Represents a card.

fields: suit and rank.
"""
struct Card
    suit::Int64
    rank::Int64
    function Card(suit::Int64, rank::Int64)
        @assert(1 ≤ suit ≤ 4, "Suit is not between 1 and 4.")
        @assert(1 ≤ rank ≤ 13, "Rank is not between 1 and 13.")
        new(suit, rank)
    end
end


"""
    Base.show(io::IO, card::Card)

Print a string representation of a Card.
"""
function Base.show(io::IO, card::Card)
    print(io, rank_names[card.rank], suitnames[card.suit])
end


"""
    isless(c1::Card, c2::Card)

Compare two cards and see if one is less than the other
with the given Cards. Here, suit is more important than rank.
"""
function isless(c1::Card, c2::Card)
    (c1.suit, c1.rank) < (c2.suit, c2.rank)
end
