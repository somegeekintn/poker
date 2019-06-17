//
//  Deck.swift
//  Poker
//
//  Created by Casey Fleser on 7/3/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation
import Swift

class Deck : CustomStringConvertible {
	var cards		= [Card]()
	var position	= 0
	
	init() {
		for rawSuit in Card.Suit.MinSuit.rawValue...Card.Suit.MaxSuit.rawValue {
			for rawRank in Card.Rank.MinRank.rawValue...Card.Rank.MaxRank.rawValue {
#warning("force unwrap")
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
		self.position = 0
		self.cards.shuffle()
	}
	
	func drawCard() -> Card {
		let card = self.cards[self.position]
		
		self.position += 1
		card.reset()

		return card
	}
}

