//
//  DeckIterator.swift
//  Poker
//
//  Created by Casey Fleser on 10/15/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation

class DeckIterator : CustomStringConvertible {
	var next			: DeckIterator?
	var range			: ClosedRange<Int>
	var generator		: IndexingIterator<ClosedRange<Int>>
	var selection		: Int?
	let handPosition	: Int
	
    var description: String {
		get {
			var desc = "\(self.range.lowerBound)..<\(self.range.upperBound): \(self.selection?.description ?? "no selection" )"
			
			if let next = self.next {
				desc += " | "
				desc += next.description
			}
			
			return desc
		}
	}

	init(hand: Hand, deck: Deck, drawCount: Int, endRange: Int = Consts.Game.MaxDeckCards - 1) {
		let startPosition	= Consts.Game.MaxHandCards + (drawCount - 1)

		self.handPosition = Consts.Game.MaxHandCards - drawCount
		self.range = startPosition...endRange
		self.generator = self.range.makeIterator()
		hand[self.handPosition] = deck[startPosition]
		
		if (drawCount > 1) {
			let nextIterator	= DeckIterator(hand: hand, deck: deck, drawCount: drawCount - 1, endRange: endRange - 1)
			
			// prep next nextIterator
			nextIterator.selection = nextIterator.generator.next()
			self.next = nextIterator
		}
	}
	
	final func advanceWithHand(hand: Hand, deck: Deck) -> Int? {
		var selection	= self.generator.next()
		
		if let nextSelection = selection {
			hand[self.handPosition] = deck[nextSelection]
			self.selection = nextSelection
		}
		else {
			if let nextIterator = self.next, let nextNextSelection = nextIterator.advanceWithHand(hand: hand, deck: deck) {
				self.range = nextNextSelection + 1 ... self.range.upperBound
				self.generator = self.range.makeIterator()
				selection = self.generator.next()
				if let nextSelection = selection {
					hand[self.handPosition] = deck[nextSelection]
					self.selection = nextSelection
				}
			}
		}
		
		return selection
	}
}
