//
//  Hand.swift
//  Poker
//
//  Created by Casey Fleser on 7/8/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Swift

class Hand : CustomStringConvertible {
	private var cardSlots	= [Card?](repeating: nil, count: Consts.Game.MaxHandCards)
	
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

    subscript (position: Int) -> Card? {
		get {
			return self.cardSlots[position]
		}
		set (newValue) {
			self.cardSlots[position] = newValue
		}
	}

	func initialDrawFromDeck(_ deck: Deck) {
		self.cardSlots = [Card?](repeating: nil, count: Consts.Game.MaxHandCards)
		self.drawFromDeck(deck)
	}
	
	func drawFromDeck(_ deck: Deck) {
		for (index, value) in self.cardSlots.enumerated() {
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
		var	category		= Category.none
		var	sortedCards		= self.cards

		if sortedCards.count > 1 {	// at least 2 cards required to make a hand
			var isStraight		: Bool = true
			var isFlush			: Bool
			var lastCard		: Card? = nil
			var sortedRanks		= [[Card]](repeating: [Card](), count: Card.Rank.numRanks)
			var sortedSuits		= [[Card]](repeating: [Card](), count: Card.Suit.numSuits)
			
			sortedCards.sort{ $0 > $1 }
			for card in sortedCards {
				// --->>> count ranks
				sortedRanks[card.rank.rawValue].append(card)

				// --->>> count suits
				sortedSuits[card.suit.rawValue].append(card)

				// --->>> straight test
				if isStraight {
					if let lastCard = lastCard {
						if let nextExpected = lastCard.rank.nextLower {
							if card.rank != nextExpected {
								// test special case for the ace. if last was an ace, this card should be a five
								if lastCard.rank != .ace || card.rank != .five {
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
			sortedRanks.sort { (p1, p2) -> Bool in
				var orderedBefore = p1.count > p2.count
				
				if !orderedBefore {
					orderedBefore = p1.count > 0 && p1.count == p2.count && p1[0].rank > p2[0].rank
				}
				
				return orderedBefore
			}
			sortedSuits.sort { (p1, p2) in p1.count > p2.count }

	//			println("rankCounts: \(sortedRanks)\nsuitCounts: \(sortedSuits)")

			// --->>> Flush?
			isFlush = sortedSuits[0].count == Consts.Game.MaxHandCards
			
			// --->>> Straight Flush?
			if isFlush && isStraight {
				sortedCards.forEach { $0.pin = true }		// pin all
				category = sortedCards[0].rank == .ace ? .royalFlush : .straightFlush
			}
			else {
				let highestRankCount	= sortedRanks[0].count
				
				if highestRankCount == 4 {
					sortedRanks[0].forEach { $0.pin = true }
					
					category = .fourOfAKind
				}
				else {
					if highestRankCount == 3 && sortedRanks[1].count == 2 {
						sortedRanks[0].forEach { $0.pin = true }
						sortedRanks[1].forEach { $0.pin = true }
						category = .fullHouse
					}
					else if isFlush {
						sortedCards.forEach { $0.pin = true }	// pin all
						category = .flush
					}
					else if isStraight {
						sortedCards.forEach { $0.pin = true }	// pin all
						category = .straight
					}
					else if highestRankCount == 3 {
						sortedRanks[0].forEach { $0.pin = true }
						category = .threeOfAKind
					}
					else if highestRankCount == 2 {
						if sortedRanks[1].count == 2 {
							sortedRanks[0].forEach { $0.pin = true }
							sortedRanks[1].forEach { $0.pin = true }
							category = .twoPair
						}
						else if sortedRanks[0][0].rank >= .jack {
							sortedRanks[0].forEach { $0.pin = true }
							category = .jacksOrBetter
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
		for suit in Card.Suit.allSuits {
			let suitRankBits	= UInt(workBits & Consts.Hands.SuitMask64)
			
			if suitRankBits != 0 {
				var straightMask	= Consts.Hands.RoyalStraightMask		// 0x1f00
				
				while straightMask >= Consts.Hands.To6StraightMask {		// >= 0x001f
					if suitRankBits == straightMask {
						return suitRankBits == Consts.Hands.RoyalStraightMask ? .royalFlush : .straightFlush
					}
					straightMask >>= 1
				}
				
				if suitRankBits == Consts.Hands.A5StraightMask {		// 0x100f
					return .straightFlush
				}
				
				if suitRankBits.bitCount() == Consts.Game.MaxHandCards {
					// if we have a flush that isn't a straight, the only higher hand is 4 of a kind or a full house which we can't have if we have a flush
					return .flush
				}
			
				// Why not use an array like a sane person? Well, arrays are slow and I've been unable to find a way to make them
				// as fast as I'd like. Also, assigning here using this switch is fractionally quicker than shifting and masking
				// later on
				switch suit {
					case .club:		cBits = suitRankBits
					case .diamond:	dBits = suitRankBits
					case .heart:	hBits = suitRankBits
					case .spade:	sBits = suitRankBits
				}
			}
			workBits >>= UInt64(Card.Rank.numRanks)
		}
		
		if (cBits & dBits & hBits & sBits) != 0 {
			return .fourOfAKind
		}
		else {
			let match3		= (cBits & dBits & hBits) | (cBits & dBits & sBits)	| (cBits & hBits & sBits) | (dBits & hBits & sBits)
			var match2		= (cBits & dBits) | (cBits & hBits) | (cBits & sBits)
			
			match2 |= (dBits & hBits) | (dBits & sBits) | (hBits & sBits)	// have to break this up otherwise the compiler complains
			match2 &= ~match3

			if match3 != 0 && match2 != 0 {
				return .fullHouse
			}
			else {
				var straightMask	= Consts.Hands.RoyalStraightMask		// 0x1f00
				let	allSuits		= cBits | dBits | hBits | sBits
				
				while straightMask >= Consts.Hands.To6StraightMask {		// >= 0x001f
					if allSuits == straightMask {
						return .straight
					}
					straightMask >>= 1
				}
				
				if allSuits == Consts.Hands.A5StraightMask {				// 0x100f
					return .straight
				}
				
				if match3 != 0 {
					return .threeOfAKind
				}
				else {
					let pairCount = match2.bitCount()
					
					if pairCount != 0 {
						if pairCount > 1 {
							return .twoPair
						}
						else {
							if match2 >= Card.Rank.jack.rankBit {
								return .jacksOrBetter
							}
						}
					}
				}
			}
		}
		
		return .none
	}
	
	/* --- Category --- */

	enum Category: Int, CustomStringConvertible {
		case none = 0
		case jacksOrBetter
		case twoPair
		case threeOfAKind
		case straight
		case flush
		case fullHouse
		case fourOfAKind
		case straightFlush
		case royalFlush

		static let WinningCategories	= [royalFlush, straightFlush, fourOfAKind, fullHouse, flush, straight, threeOfAKind, twoPair, jacksOrBetter]
		static let NumCategories		= royalFlush.rawValue + 1
		
		var description: String {
			get {
				switch self {
					case .none:				return "None"
					case .jacksOrBetter:	return "Jacks or Better"
					case .twoPair:			return "Two Pair"
					case .threeOfAKind:		return "Three of a Kind"
					case .straight:			return "Straight"
					case .flush:			return "Flush"
					case .fullHouse:		return "Full House"
					case .fourOfAKind:		return "Four of a Kind"
					case .straightFlush:	return "Straight Flush"
					case .royalFlush:		return "Royal Flush"
				}
			}
		}
		
		func payoutForBet(_ bet: Int) -> Int {
			var payout = 0
			
			switch self {
				case .none:				payout = 0
				case .jacksOrBetter:	payout = 1
				case .twoPair:			payout = 2
				case .threeOfAKind:		payout = 3
				case .straight:			payout = 4
				case .flush:			payout = 6
				case .fullHouse:		payout = 9
				case .fourOfAKind:		payout = 25
				case .straightFlush:	payout = 50
				case .royalFlush:		payout = 250
			}
			
			payout *= bet
			if self == .royalFlush && bet == 5 {
				payout = 4000
			}
			
			return payout
		}
	}
}
