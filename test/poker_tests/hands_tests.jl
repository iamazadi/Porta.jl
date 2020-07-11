hand_pair = Hand([Card(rand(1:4), 1),
                  Card(rand(1:4), 2),
                  Card(rand(1:4), 3),
                  Card(rand(1:4), 5),
                  Card(rand(1:4), 3)], "")
shuffle!(hand_pair)
hand_nopair = Hand([Card(rand(1:4), 1),
                    Card(rand(1:4), 2),
                    Card(rand(1:4), 3),
                    Card(rand(1:4), 4),
                    Card(rand(1:4), 5)], "")
shuffle!(hand_nopair)

@test haspair(hand_pair)
@test !haspair(hand_nopair)

hand_twopair = Hand([Card(rand(1:4), 7),
                     Card(rand(1:4), 2),
                     Card(rand(1:4), 13),
                     Card(rand(1:4), 13),
                     Card(rand(1:4), 7)], "")
shuffle!(hand_twopair)
hand_notwopair = Hand([Card(rand(1:4), 1),
                       Card(rand(1:4), 2),
                       Card(rand(1:4), 4),
                       Card(rand(1:4), 4),
                       Card(rand(1:4), 5)], "")
shuffle!(hand_notwopair)

@test hastwopair(hand_twopair)
@test !hastwopair(hand_notwopair)

hand_threeofakind = Hand([Card(rand(1:4), 7),
                          Card(rand(1:4), 7),
                          Card(rand(1:4), 13),
                          Card(rand(1:4), 1),
                          Card(rand(1:4), 7)], "")
shuffle!(hand_threeofakind)
hand_nothreeofakind = Hand([Card(rand(1:4), 1),
                            Card(rand(1:4), 2),
                            Card(rand(1:4), 4),
                            Card(rand(1:4), 4),
                            Card(rand(1:4), 5)], "")
shuffle!(hand_nothreeofakind)

@test hasthreeofakind(hand_threeofakind)
@test !hasthreeofakind(hand_nothreeofakind)

lspace = range(ranktoangle(1), stop = ranktoangle(13), length = 13)

@test angletorank(ranktoangle(1:13)) == 1:13
@test isapprox(u1toangle(angletou1(lspace)), collect(lspace))

hand_straight1 = Hand([Card(rand(1:4), 1),
                       Card(rand(1:4), 2),
                       Card(rand(1:4), 3),
                       Card(rand(1:4), 4),
                       Card(rand(1:4), 5)], "")
shuffle!(hand_straight1)
hand_straight2 = Hand([Card(rand(1:4), 10),
                       Card(rand(1:4), 11),
                       Card(rand(1:4), 12),
                       Card(rand(1:4), 13),
                       Card(rand(1:4), 1)], "")
shuffle!(hand_straight2)
hand_nostraight = Hand([Card(rand(1:4), 12),
                        Card(rand(1:4), 13),
                        Card(rand(1:4), 1),
                        Card(rand(1:4), 2),
                        Card(rand(1:4), 3)], "")
shuffle!(hand_nostraight)

@test_broken hasstraight(hand_straight1)
@test_broken hasstraight(hand_straight2)
@test_broken !hasstraight(hand_nostraight)
