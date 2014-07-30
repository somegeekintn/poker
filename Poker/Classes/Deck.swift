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
		for rawSuit in Card.Suit.MinSuit.toRaw()...Card.Suit.MaxSuit.toRaw() {
			for rawRank in Card.Rank.MinRank.toRaw()...Card.Rank.MaxRank.toRaw() {
				cards += Card(rank: Card.Rank.fromRaw(rawRank)!, suit: Card.Suit.fromRaw(rawSuit)!)
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
	
	func shuffle() {
		let cardCount	= cards.count
		
		self.position = 0
		for var cardIdx=0; cardIdx<cardCount; cardIdx++ {
			var targetIdx	: Int
			var savedCard	: Card

			do {
				targetIdx = Int(arc4random_uniform(UInt32(cardCount)))
			} while (targetIdx == cardIdx)

			savedCard = cards[cardIdx]
			cards[cardIdx] = cards[targetIdx]
			cards[targetIdx] = savedCard
		}
	}
	
	func drawCard () -> Card {
		var card = self.cards[self.position++]

		card.reset()

		return card
	}
}
