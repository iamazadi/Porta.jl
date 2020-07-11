import Base.isless
import Random


export Deck
export Hand
export shuffle!
export move!
export deal!


"""
    Represents a set of Cards.

It is an abstract type.
"""
abstract type CardSet end


"""
    Base.show(io::IO, cs::CardSet)

Print a string representation of a CardSet.
"""
function Base.show(io::IO, cs::CardSet)
    for card in cs.cards
        print(io, card, " ")
    end
    println()
end


"""
    Base.pop!(cs::CardSet)

Remove a Card and return it with the given CardSet.
"""
function Base.pop!(cs::CardSet)
    pop!(cs.cards)
end


"""
    Base.push!(cs::CardSet, card::Card)

Add a Card to a CardSet.
"""
function Base.push!(cs::CardSet, card::Card)
    push!(cs.cards, card)
    nothing
end


"""
    shuffle!(cs::CardSet)

Shuffle Cards in a CardSet.
"""
function shuffle!(cs::CardSet)
    Random.shuffle!(cs.cards)
end


"""
    Base.sort!(cs::CardSet)

Sort Cards in a CardSet.
"""
function Base.sort!(cs::CardSet)
    sort!(cs.cards)
end


"""
    move!(cs1::CardSet, cs2::CardSet, n::Int64)

Move Cards from a CardSet to another
with the given CardSets and the number of Cards to move.
"""
function move!(cs1::CardSet, cs2::CardSet, n::Int64)
    @assert 1 ≤ n ≤ length(cs1.cards)
    for i in 1:n
        card = pop!(cs1)
        push!(cs2, card)
    end
    nothing
end


"""
    Represents a deck of Cards.

fields: cards.
"""
struct Deck <: CardSet
    cards::Array{Card,1}
end


"""
    Deck()

Constructs a Deck of 52 Cards.
"""
function Deck()
    deck = Deck(Card[])
    for suit in 1:4
        for rank in 1:13
            push!(deck.cards, Card(suit, rank))
        end
    end
    deck
end


"""
    Represents a hand of Cards.

fields: cards and label.
"""
struct Hand <: CardSet
    cards::Array{Card,1}
    label::String
end


"""
    Hand(label::String="")

Construct a Hand with the given label.
"""
function Hand(label::String="")
    Hand(Card[], label)
end


"""
    Base.show(io::IO, hand::Hand)

Print a string representation of a Hand.
"""
function Base.show(io::IO, hand::Hand)
    for card in hand.cards
        print(io, card, " ")
    end
    println(hand.label)
end


"""
    deal!(deck::Deck, handsnumber::Int64, cardsperhand::Int64)

Create Hands and deal Cards with the given Deck, the number of Hands and Cards per Hand.
"""
function deal!(deck::Deck, handsnumber::Int64, cardsperhand::Int64)
    shuffle!(deck)
    hands = [Hand() for i in 1:handsnumber]
    for i in 1:cardsperhand
        for hand in hands
            move!(deck, hand, 1)
        end
    end
    hands
end
