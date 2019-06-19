//
//  Hand.swift
//  Poker
//
//  Created by Casey Fleser on 7/8/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Swift

class Hand : CustomStringConvertible {
	var cards				: [Card] { return self.cardSlots.compactMap({ $0 }) }
	var cardSet				: CardSet { return CardSet(rawValue: self.cardSlots.reduce(UInt64(0), { (result, slot) -> UInt64 in slot.map({ result | $0.cardSetValue }) ?? result })) }
	var heldCards			: [Card] { return self.cards.filter({ $0.hold })}
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

    subscript (position: Int) -> Card? {
		get { return self.cardSlots[position] }
		set { self.cardSlots[position] = newValue }
	}

	func initialDrawFromDeck(_ deck: Deck) {
		self.cardSlots = [Card?](repeating: nil, count: Consts.Game.MaxHandCards)
		self.drawFromDeck(deck)

		Trace.debug("draw: \(self.cards)")
	}
	
	func drawFromDeck(_ deck: Deck) {
		for (index, value) in self.cardSlots.enumerated() {
			if (value == nil || !value!.hold) {
				self.cardSlots[index] = deck.drawCard()
			}
		}
	}
	
	func evaluate() -> Category {
		let cardSet		= self.cardSet
		let evaluation	= cardSet.eval()

		Trace.debug("eval: \(self.cards) = \(evaluation)")
		
		if !evaluation.relevant.isEmpty {
			for card in self.cards {
				card.pin = evaluation.relevant.contains(CardSet(card: card))
			}
		}
		
		return evaluation.category
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
