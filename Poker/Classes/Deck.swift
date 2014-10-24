//
//  Deck.swift
//  Poker
//
//  Created by Casey Fleser on 7/3/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation
import Swift

class Deck : Printable {
	var cards		= [Card]()
	var position	= 0
	
	init() {
		for rawSuit in Card.Suit.MinSuit.rawValue...Card.Suit.MaxSuit.rawValue {
			for rawRank in Card.Rank.MinRank.rawValue...Card.Rank.MaxRank.rawValue {
				self.cards.append(Card(rank: Card.Rank(rawValue: rawRank)!, suit: Card.Suit(rawValue: rawSuit)!))
			}
		}
	}
	
    var description: String {
		get {
			var desc	= String()
			
			for card in self.cards {
				if (!desc.isEmpty) {
					desc += ","
				}
				desc += card.description
			}
			
			return desc
		}
	}
	
    final subscript (position: Int) -> Card {
		get {
			return self.cards[position]
		}
	}
	
	func shuffle() {
		let cardCount	= self.cards.count
		
		self.position = 0
		for var cardIdx=0; cardIdx<cardCount; cardIdx++ {
			var targetIdx	: Int
			var savedCard	: Card

			do {
				targetIdx = Int(arc4random_uniform(UInt32(cardCount)))
			} while (targetIdx == cardIdx)

			savedCard = self.cards[cardIdx]
			self.cards[cardIdx] = self.cards[targetIdx]
			self.cards[targetIdx] = savedCard
		}
	}
	
	func drawCard() -> Card {
		var card = self.cards[self.position++]

		card.reset()

		return card
	}
}

