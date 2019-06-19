//
//  CardSet.swift
//  Poker
//
//  Created by Casey Fleser on 6/18/19.
//  Copyright © 2019 Quiet Spark. All rights reserved.
//

import Foundation

struct CardSet: OptionSet, CustomStringConvertible {
	static let royalStraight	= CardSet(ranks: [.ace, .king, .queen, .jack, .ten])
	static let allStraights		: [CardSet] = [
									royalStraight,
									CardSet(ranks: [.king, .queen, .jack, .ten, .nine]),
									CardSet(ranks: [.queen, .jack, .ten, .nine, .eight]),
									CardSet(ranks: [.jack, .ten, .nine, .eight, .seven]),
									CardSet(ranks: [.ten, .nine, .eight, .seven, .six]),
									CardSet(ranks: [.nine, .eight, .seven, .six, .five]),
									CardSet(ranks: [.eight, .seven, .six, .five, .four]),
									CardSet(ranks: [.seven, .six, .five, .four, .three]),
									CardSet(ranks: [.six, .five, .four, .three, .two]),
									CardSet(ranks: [.five, .four, .three, .two, .ace])
								]
	
	let rawValue				: UInt64

	var cards					: [Card] {
		var setBits		= self.rawValue
		var cards		= [Card]()
		var bitCount	= 0
		
		while setBits != 0 {
			if setBits & 1 != 0 {
				if let rank = Card.Rank(rawValue: bitCount % Card.Rank.numRanks), let suit = Card.Suit(rawValue: bitCount / Card.Rank.numRanks) {
					cards.append(Card(rank: rank, suit: suit))
				}
			}
			bitCount += 1
			setBits >>= 1
		}
		
		return cards
	}
	
	var description				: String {
		return self.cards.description
	}
	
	init(rawValue: UInt64) {
		self.rawValue = rawValue
	}
	
	init(card: Card) {
		self = CardSet(rawValue: card.cardSetValue)
	}
	
	init(cards: [Card]) {
		self = CardSet(rawValue: cards.reduce(0, { (result, card) -> UInt64 in result | card.cardSetValue }))
	}
	
	init(ranks: [Card.Rank]) {		// mask maker
		self = CardSet(rawValue: ranks.reduce(0, { (result, rank) -> UInt64 in result | UInt64(rank.rankBit) }))
	}
	
    func eval() -> (category: Hand.Category, relevant: CardSet) {
		let suitRanks 	: [UInt64] = [	// Unrolling is faster than Card.Suit.allSuits.map...
							(self.rawValue >> Card.Suit.club.shiftVal) & Card.Suit.rankMask,
							(self.rawValue >> Card.Suit.diamond.shiftVal) & Card.Suit.rankMask,
							(self.rawValue >> Card.Suit.heart.shiftVal) & Card.Suit.rankMask,
							(self.rawValue >> Card.Suit.spade.shiftVal) & Card.Suit.rankMask
						]
		let any2Raw 	: [UInt64] = [
							suitRanks[Card.Suit.club.rawValue] & suitRanks[Card.Suit.diamond.rawValue],
							suitRanks[Card.Suit.club.rawValue] & suitRanks[Card.Suit.heart.rawValue],
							suitRanks[Card.Suit.club.rawValue] & suitRanks[Card.Suit.spade.rawValue],
							suitRanks[Card.Suit.diamond.rawValue] & suitRanks[Card.Suit.heart.rawValue],
							suitRanks[Card.Suit.diamond.rawValue] & suitRanks[Card.Suit.spade.rawValue],
							suitRanks[Card.Suit.heart.rawValue] & suitRanks[Card.Suit.spade.rawValue],
						]
		var any2		= CardSet(rawValue: any2Raw.reduce(0, { (result, rawValue) -> UInt64 in result | rawValue }))

		if !any2.isEmpty {
			let any3		: CardSet
			var any4		= CardSet(rawValue: 0)
			let any3Raw 	: [UInt64] = [
								any2Raw[0] & suitRanks[Card.Suit.heart.rawValue],
								any2Raw[0] & suitRanks[Card.Suit.spade.rawValue],
								any2Raw[5] & suitRanks[Card.Suit.club.rawValue],
								any2Raw[5] & suitRanks[Card.Suit.diamond.rawValue]
							]

			any3 = CardSet(rawValue: any3Raw.reduce(0, { (result, rawValue) -> UInt64 in result | rawValue }))
			if !any3.isEmpty {
				any4 = CardSet(rawValue: any3Raw[0] & suitRanks[Card.Suit.spade.rawValue])
				
				if !any4.isEmpty {
					return (category: .fourOfAKind, relevant: CardSet(rawValue: Card.Suit.allSuits.reduce(UInt64(0), { $0 | (any4.rawValue << $1.shiftVal) })))
				}
				else {
					any2.subtract(any3)
					
					if !any2.isEmpty {
						return (category: .fullHouse, relevant: self)
					}
					else {
						let rankValue = any3.rawValue.firstNonzeroBitPosition
						
						return (category: .threeOfAKind, relevant: CardSet(cards: self.cards.filter({ $0.rank.rawValue == rankValue })))
					}
				}
			}
			else {
				if any2.rawValue.nonzeroBitCount > 1 {
					let rankValues = any2.rawValue.nonzeroBitPositions

					return (category: .twoPair, relevant: CardSet(cards: self.cards.filter({ card in rankValues.contains(where: { card.rank.rawValue == $0 }) })))
				}
				else {
					if any2.rawValue >= (1 << Card.Rank.jack.rawValue) {
						if let rankValue = any2.rawValue.firstNonzeroBitPosition {
							return (category: .jacksOrBetter, relevant: CardSet(cards: self.cards.filter({ $0.rank.rawValue == rankValue })))
						}
						else {	// shouldn't be possible
							return (category: .none, relevant: [])
						}
					}
					else {
						return (category: .none, relevant: [])
					}
				}
			}
		}
		else {				// Only bother with this if there are no pairs or better
			let allSuitBits	= Card.Suit.allSuits.reduce(UInt64(0), { (result, suit) -> UInt64 in result | suitRanks[suit.rawValue] })
			let hasStraight	= CardSet.allStraights.contains(where: { allSuitBits == $0.rawValue })

			for suitBits in suitRanks {
				if hasStraight {
					for straight in CardSet.allStraights {
						let rawValue	= straight.rawValue

						if suitBits == rawValue {
							return (category: straight == CardSet.royalStraight ? .royalFlush : .straightFlush, relevant: self)
						}
					}
				}
				else if suitBits.nonzeroBitCount == Consts.Game.MaxHandCards {
					return (category: .flush, relevant: self)
				}
			}
			
			return hasStraight ? (category: .straight, relevant: self) : (category: .none, relevant: [])
		}
    }
}

