decka = Deck()
deckb = Deck()
shuffle!(decka)
sort!(decka)
sort!(deckb)

@test decka.cards == deckb.cards

deck = Deck()
deckcopy = deepcopy(deck)
card = pop!(deckcopy)
push!(deckcopy, card)

@test deck.cards == deckcopy.cards

deck = Deck()
hand = Hand()
n = rand(1:52)
move!(deck, hand, n)

@test length(hand.cards) == n && length(deck.cards) == 52 - n

deck = Deck()
handsnumber = 4
cardsperhand = 13
hands = deal!(deck, handsnumber, cardsperhand)

@test length(deck.cards) == 0
@test length(hands) == handsnumber
@test length(hands[1].cards) == cardsperhand
