//
//  Hand.swift
//  Poker
//
//  Created by Casey Fleser on 7/8/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Swift

extension Array  {
	func iterate(apply: (T) -> ()) {
		for item in self { apply(item) }
	}
	
	func indexOf(test: (T) -> Bool) -> Int? {
		var itemIndex: Int? = nil
		
		for (index, value) in enumerate(self) {
			if (test(value)) {
				itemIndex = index;
				break;
			}
		}
		
		return itemIndex
	}
}

class Hand : Printable {
	let		capacity	= 5
	var		cards		= [Card]()
	
    var description: String {
		get {
			var desc	= String()
			
			if (self.cards.isEmpty) {
				desc = "no cards"
			}
			else {
				for card in self.cards {
					if (!desc.isEmpty) {
						desc += ","
					}
					desc += card.description
				}
				
				desc += " - \(self.evaluate())"
			}
			
			return desc;
		}
	}
	
	func evaluate() -> Category {
		var	category		= Category.None;

		if self.cards.count > 1 {	// at least 2 cards required to make a hand
			var	sortedCards		= self.cards.sorted{ $0 > $1 }
			var	sortedRanks		= [[Card]]()
			var	sortedSuits		= [[Card]]()
			var isStraight		: Bool = true
			var isFlush			: Bool
			var lastCard		: Card? = nil
			
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
					lastCard = card;
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
							category = Category.Pair
						}
					}
				}
			}
		}

		return category;
	}

	func initialDrawFromDeck(deck: Deck) {
		self.cards = [Card]()
		self.drawFromDeck(deck)
	}
	
	func drawFromDeck(deck: Deck) {
		self.cards += deck.draw(self.capacity - self.cards.count)
	}
	
	func discard(discards: Array<Card>) {
		self.cards = self.cards.filter {
			(card: Card) -> Bool in
			return find(discards, card) ? false : true
		}
	}
	
	func discard(discards: Array<Int>) {
		var	cards = [Card]()
		
		for cardIdx in discards {
			cards.append(self.cards[cardIdx])
		}
		self.discard(cards)
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
	}
}
