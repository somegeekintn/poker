//
//  Hand.swift
//  Poker
//
//  Created by Casey Fleser on 7/8/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Swift

class Hand : Printable {
	private var cardSlots	: [Card?]
	
    var description: String {
		get {
			var desc = String()
			
			for cardSlot in self.cardSlots {
				if let card = cardSlot {
					if !desc.isEmpty {
						desc += ","
					}
					desc += card.description
				}
			}
			
			desc += " - \(self.evaluate())"
			
			if desc.isEmpty {
				desc = "no cards"
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

	init() {
		self.cardSlots = [Card?](count: Consts.Game.MaxHandCards, repeatedValue: nil)
	}
	
    subscript (position: Int) -> Card? {
		get {
			return self.cardSlots[position]
		}
		set (newValue) {
			self.cardSlots[position] = newValue
		}
	}

	func initialDrawFromDeck(deck: Deck) {
		self.cardSlots = [Card?](count: Consts.Game.MaxHandCards, repeatedValue: nil)
		self.drawFromDeck(deck)
	}
	
	func drawFromDeck(deck: Deck) {
		for (index, value) in enumerate(self.cardSlots) {
			if (value == nil || !value!.hold) {
				self.cardSlots[index] = deck.drawCard()
			}
		}
	}
	
	func heldCards() -> [Card] {
		var heldCards	= [Card]()
		
		for cardSlot in self.cardSlots {
			if let card = cardSlot {
				if card.hold {
					heldCards.append(card)
				}
			}
		}

		return heldCards
	}

	func evaluate() -> Category {
		var	category		= Category.None
		var	sortedCards		= self.cards

		if sortedCards.count > 1 {	// at least 2 cards required to make a hand
			var isStraight		: Bool = true
			var isFlush			: Bool
			var lastCard		: Card? = nil
			var sortedRanks		= [[Card]](count: Card.Rank.NumRanks, repeatedValue: [Card]())
			var sortedSuits		= [[Card]](count: Card.Suit.NumSuits, repeatedValue: [Card]())
			
			sortedCards.sort{ $0 > $1 }
			for card in sortedCards {
				// --->>> count ranks
				sortedRanks[card.rank.rawValue].append(card)

				// --->>> count suits
				sortedSuits[card.suit.rawValue].append(card)

				// --->>> straight test
				if (isStraight) {
					if let lastCard = lastCard {
						if let nextExpected = lastCard.rank.nextLower() {
							if card.rank != nextExpected {
								// test special case for the ace. if last was an ace, this card should be a five
								if lastCard.rank != Card.Rank.Ace || card.rank != Card.Rank.Five {
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
			sortedRanks.sort { (p1, p2) in p1.count > p2.count || (p1.count > 0 && p1.count == p2.count && p1[0].rank > p2[0].rank) }
			sortedSuits.sort { (p1, p2) in p1.count > p2.count }

	//			println("rankCounts: \(sortedRanks)\nsuitCounts: \(sortedSuits)")

			// --->>> Flush?
			isFlush = sortedSuits[0].count == Consts.Game.MaxHandCards
			
			// --->>> Straight Flush?
			if isFlush && isStraight {
				sortedCards.iterate { $0.pin = true }	// pin all
				category = sortedCards[0].rank == Card.Rank.Ace ? Category.RoyalFlush : Category.StraightFlush
			}
			else {
				let highestRankCount	= sortedRanks[0].count
				
				if highestRankCount == 4 {
					sortedRanks[0].iterate { $0.pin = true }
					for card in sortedRanks[0] { card.pin = true }
					
					category = Category.FourOfAKind
				}
				else {
					if highestRankCount == 3 && sortedRanks[1].count == 2 {
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
							category = Category.JacksOrBetter
						}
					}
				}
			}
		}

		return category
	}

	func fastEval() -> Category {
		// normally I don't return in the middle of functions, but this just doesn't
		// look nice sprinkled with all the breaks and ifs we'd need otherwise
		var	rankBits		= UInt64(0)
		var	workBits		: UInt64
		var cBits			= UInt(0)
		var dBits			= UInt(0)
		var hBits			= UInt(0)
		var sBits			= UInt(0)
		
		for cardSlot in self.cardSlots {
			if let card = cardSlot {
				rankBits |= card.bitFlag
			}
		}
		
		workBits = rankBits
		for rawSuit in 0..<4 {
			var suitRankBits	= UInt(workBits & Consts.Hands.SuitMask64)
			
			if suitRankBits != 0 {
				var straightMask	= Consts.Hands.RoyalStraightMask		// 0x1f00
				
				while straightMask >= Consts.Hands.To6StraightMask {		// >= 0x001f
					if suitRankBits == straightMask {
						return suitRankBits == Consts.Hands.RoyalStraightMask ? Category.RoyalFlush : Category.StraightFlush
					}
					straightMask >>= 1
				}
				
				if suitRankBits == Consts.Hands.A5StraightMask {		// 0x100f
					return Category.StraightFlush
				}
				
				if suitRankBits.bitCount() == Consts.Game.MaxHandCards {
					// if we have a flush that isn't a straight, the only higher hand is 4 of a kind or a full house which we can't have if we have a flush
					return Category.Flush
				}
			
				// Why not use an array like a sane person? Well, arrays are slow and I've been unable to find a way to make them
				// as fast as I'd like. Also, assigning here using this switch is fractionally quicker than shifting and masking
				// later on
				switch rawSuit {
					case Card.Suit.Club.rawValue:		cBits = suitRankBits
					case Card.Suit.Diamond.rawValue:	dBits = suitRankBits
					case Card.Suit.Heart.rawValue:		hBits = suitRankBits
					case Card.Suit.Spade.rawValue:		sBits = suitRankBits
					default:							break
				}
			}
			workBits >>= UInt64(Card.Rank.NumRanks)
		}
		
		if (cBits & dBits & hBits & sBits) != 0 {
			return Category.FourOfAKind
		}
		else {
			let match3		= (cBits & dBits & hBits) | (cBits & dBits & sBits)	| (cBits & hBits & sBits) | (dBits & hBits & sBits)
			var match2		= (cBits & dBits) | (cBits & hBits) | (cBits & sBits)
			
			match2 |= (dBits & hBits) | (dBits & sBits) | (hBits & sBits)	// have to break this up otherwise the compiler complains
			match2 &= ~match3

			if match3 != 0 && match2 != 0 {
				return Category.FullHouse
			}
			else {
				var straightMask	= Consts.Hands.RoyalStraightMask		// 0x1f00
				var	allSuits		= cBits | dBits | hBits | sBits
				
				while straightMask >= Consts.Hands.To6StraightMask {		// >= 0x001f
					if allSuits == straightMask {
						return Category.Straight
					}
					straightMask >>= 1
				}
				
				if allSuits == Consts.Hands.A5StraightMask {				// 0x100f
					return Category.Straight
				}
				
				if match3 != 0 {
					return Category.ThreeOfAKind
				}
				else {
					var pairCount = match2.bitCount()
					
					if pairCount != 0 {
						if pairCount > 1 {
							return Category.TwoPair
						}
						else {
							if match2 >= Card.Rank.Jack.rankBit {
								return Category.JacksOrBetter
							}
						}
					}
				}
			}
		}
		
		return Category.None
	}
	
	/* --- Category --- */

	enum Category: Int, Printable {
		case None = 0
		case JacksOrBetter
		case TwoPair
		case ThreeOfAKind
		case Straight
		case Flush
		case FullHouse
		case FourOfAKind
		case StraightFlush
		case RoyalFlush

		static let WinningCategories = [RoyalFlush, StraightFlush, FourOfAKind, FullHouse, Flush, Straight, ThreeOfAKind, TwoPair, JacksOrBetter]
		
		var description: String {
			get {
				switch self {
					case .None:
						return "None"
					case .JacksOrBetter:
						return "Jacks or Better"
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
			var payout = 0
			
			switch self {
				case .None:
					payout = 0
				case .JacksOrBetter:
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
