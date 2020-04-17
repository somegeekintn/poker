//
//  Deck.swift
//  Poker
//
//  Created by Casey Fleser on 7/3/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation

class Deck: Collection, CustomStringConvertible {
	var startIndex	= 0
	var endIndex	: Int { self.cards.count }
	var cards		= [Card]()
	var iterator	: IndexingIterator<[Card]>
	
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

	init() {
		let cards = Card.Suit.allCases.flatMap({ s in Card.Rank.allCases.map({ Card(rank: $0, suit: s) }) })
		
		self.cards = cards
		self.iterator = cards.makeIterator()
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
    final subscript (position: Int) -> Card {
		get {
			return self.cards[position]
		}
	}

	func shuffle() {
		self.cards.shuffle()
		self.iterator = self.cards.makeIterator()
	}
	
	func drawCard() -> Card? {
		let card = self.iterator.next()
		
		card?.reset()

		return card
	}
}

