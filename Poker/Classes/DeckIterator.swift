//
//  DeckIterator.swift
//  Poker
//
//  Created by Casey Fleser on 10/15/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

class DeckIterator : Printable {
	var next			: DeckIterator?
	var range			: Range<Int>
	var generator		: RangeGenerator<Int>
	var selection		: Int?
	var handPosition	: Int
	
    var description: String {
		get {
			var desc = "\(self.range.startIndex)..<\(self.range.endIndex): \(self.selection)"
			
			if let next = self.next {
				desc += " | "
				desc += next.description
			}
			
			return desc
		}
	}

	init(hand: Hand, deck: Deck, drawCount: Int, endRange: Int = Consts.Game.MaxDeckCards - 1) {
		var startPosition	= Consts.Game.MaxHandCards + (drawCount - 1)

		self.handPosition = Consts.Game.MaxHandCards - drawCount
		self.range = startPosition...endRange
		self.generator = self.range.generate()
		hand[self.handPosition] = deck[startPosition]
		
		if (drawCount > 1) {
			var nextIterator	= DeckIterator(hand: hand, deck: deck, drawCount: drawCount - 1, endRange: endRange - 1)
			
			// prep next nextIterator
			nextIterator.selection = nextIterator.generator.next()
			self.next = nextIterator
		}
	}
	
	final func advanceWithHand(hand: Hand, deck: Deck) -> Bool {
		var didAdvance	= true
		
		if let nextSelection = self.generator.next() {
			hand[self.handPosition] = deck[nextSelection]
			self.selection = nextSelection
		}
		else {
			if let next = self.next {
				didAdvance = next.advanceWithHand(hand, deck: deck)
				
				if didAdvance {
					self.range = next.selection! + 1..<self.range.endIndex
					self.generator = self.range.generate()
					self.selection = self.generator.next()
					hand[self.handPosition] = deck[self.selection!]
				}
			}
			else {
				didAdvance = false;
			}
		}
		
		return didAdvance
	}
}
