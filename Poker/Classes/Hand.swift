//
//  Hand.swift
//  Poker
//
//  Created by Casey Fleser on 7/8/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Swift

extension Array {
	func iterate(apply: (T) -> ()) {
		for item in self { apply(item) }
	}
	
	func filteredCount(apply: (T) -> Bool) -> Int {
		var count = 0
		for item in self {
			if apply(item) {
				count++
			}
		}
		return count
	}

	func indexOf(test: (T) -> Bool) -> Int? {
		var itemIndex: Int? = nil
		
		for (index, value) in enumerate(self) {
			if (test(value)) {
				itemIndex = index
				break
			}
		}
		
		return itemIndex
	}
}

class Hand : Printable {
	let capacity	= 5
	var cardSlots	= [Card?](count: 5, repeatedValue: nil)
	
    var description: String {
		get {
			var desc = String()
			var cards = self.cards
			
			if (cards.count == 0) {
				desc = "no cards"
			}
			else {
				for card in cards {
					if !desc.isEmpty {
						desc += ","
					}
					desc += card.description
				}
				
				desc += " - \(self.evaluate())"
			}
			
			return desc
		}
	}
	
	var cards : [Card] {
		get {
			var	cards = [Card]()
			
			for card in self.cardSlots {
				if let card = card {
					cards.append(card)
				}
			}
			
			return cards
		}
	}
	
	func evaluate() -> Category {
		var	category		= Category.None
		var	sortedCards		= self.cards

		if sortedCards.count > 1 {	// at least 2 cards required to make a hand
			var	sortedRanks		= [[Card]]()
			var	sortedSuits		= [[Card]]()
			var isStraight		: Bool = true
			var isFlush			: Bool
			var lastCard		: Card? = nil
			
			sortedCards.sort{ $0 > $1 }
			for card in sortedCards {
				// --->>> count ranks
				if var itemIdx = (sortedRanks.indexOf { rankList in return rankList[0].rank == card.rank }) {
					sortedRanks[itemIdx].append(card)
				}
				else {
					sortedRanks.append([card])
				}

				// --->>> count suits
				if var itemIdx = (sortedSuits.indexOf { suitList in return suitList[0].suit == card.suit }) {
					sortedSuits[itemIdx].append(card)
				}
				else {
					sortedSuits.append([card])
				}

				// --->>> straight test
				if (isStraight) {
					if let lastCard = lastCard {
						if let nextExpected = lastCard.rank.nextLower() {
							if card.rank != nextExpected {
								// test special case for the ace. if last was an
								if lastCard.rank != Card.Rank.Ace || lastCard.rank != Card.Rank.Five {
									isStraight = false
								}
							}
						}
						else {
							isStraight = false
						}
					}
					lastCard = card
				}
			}

			// --->>> Sort ranks and suits
			sortedRanks.sort { (p1, p2) in p1.count > p2.count || (p1.count == p2.count && p1[0].rank > p2[0].rank) }
			sortedSuits.sort { (p1, p2) in p1.count > p2.count }

//			println("rankCounts: \(sortedRanks)\nsuitCounts: \(sortedSuits)")

			// --->>> Flush?
			isFlush = sortedSuits[0].count == self.capacity
			
			// --->>> Straight Flush?
			if isFlush && isStraight {
				sortedCards.iterate { $0.pin = true }	// pin all
				category = sortedCards[0].rank == Card.Rank.Ace ? Category.RoyalFlush : Category.StraightFlush
			}
			else {
				let highestRankCount	= sortedRanks[0].count
				
				if highestRankCount == 4 {
					sortedRanks[0].iterate { $0.pin = true }
					category = Category.FourOfAKind
				}
				else {
					if sortedRanks.count > 1 && highestRankCount == 3 && sortedRanks[1].count == 2 {
						sortedRanks[0].iterate { $0.pin = true }
						sortedRanks[1].iterate { $0.pin = true }
						category = Category.FullHouse
					}
					else if isFlush {
						sortedCards.iterate { $0.pin = true }	// pin all
						category = Category.Flush
					}
					else if isStraight {
						sortedCards.iterate { $0.pin = true }	// pin all
						category = Category.Straight
					}
					else if highestRankCount == 3 {
						sortedRanks[0].iterate { $0.pin = true }
						category = Category.ThreeOfAKind
					}
					else if highestRankCount == 2 {
						if sortedRanks[1].count == 2 {
							sortedRanks[0].iterate { $0.pin = true }
							sortedRanks[1].iterate { $0.pin = true }
							category = Category.TwoPair
						}
						else if sortedRanks[0][0].rank >= Card.Rank.Jack {
							sortedRanks[0].iterate { $0.pin = true }
							category = Category.Pair
						}
					}
				}
			}
		}

		return category
	}

	func initialDrawFromDeck(deck: Deck) {
		self.cardSlots = [Card?](count: 5, repeatedValue: nil)
		self.drawFromDeck(deck)
	}
	
	func drawFromDeck(deck: Deck) {
		for (index, value) in enumerate(self.cardSlots) {
			if (value == nil || !value!.hold) {
				self.cardSlots[index] = deck.drawCard()
			}
		}
	}
	
	func cardAt(position: Int) -> Card? {
		return self.cardSlots[position]
	}

	/* --- Category --- */

	enum Category: Int, Printable {
		case None = 0
		case Pair
		case TwoPair
		case ThreeOfAKind
		case Straight
		case Flush
		case FullHouse
		case FourOfAKind
		case StraightFlush
		case RoyalFlush
		var description: String {
			get {
				switch self {
					case .None:
						return "None"
					case .Pair:
						return "Pair"
					case .TwoPair:
						return "Two Pair"
					case .ThreeOfAKind:
						return "Three of a Kind"
					case .Straight:
						return "Straight"
					case .Flush:
						return "Flush"
					case .FullHouse:
						return "Full House"
					case .FourOfAKind:
						return "Four of a Kind"
					case .StraightFlush:
						return "Straight Flush"
					case .RoyalFlush:
						return "Royal Flush"
				}
			}
		}
		
		func payoutForBet(bet: Int) -> Int {
			var payout = 0;
			
			switch self {
				case .None:
					payout = 0
				case .Pair:
					payout = 1
				case .TwoPair:
					payout = 2
				case .ThreeOfAKind:
					payout = 3
				case .Straight:
					payout = 4
				case .Flush:
					payout = 6
				case .FullHouse:
					payout = 9
				case .FourOfAKind:
					payout = 25
				case .StraightFlush:
					payout = 50
				case .RoyalFlush:
					payout = 250
			}
			
			payout *= bet
			if self == .RoyalFlush && bet == 5 {
				payout = 4000
			}
			
			return payout
		}
	}
}
