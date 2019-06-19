//
//  EVCalculator.swift
//  Poker
//
//  Created by Casey Fleser on 6/19/19.
//  Copyright © 2019 Quiet Spark. All rights reserved.
//
//  A smart person probably knows a faast mathy way to do this versus the
//  brute force approach we're taking here.

import Foundation

class EVCalculator {
	enum State {
		case stopped
		case running
		case canceled
	}

	var state					= State.stopped
	var handler					: ((_ newEV: Double?) -> ())? = nil
	
	func calculateEV(heldCards: [Card], inDeck deck: Deck, withBet bet: Int) {
		if self.state != .stopped {
			self.state = .canceled
			delay(0.1) { self.calculateEV(heldCards: heldCards, inDeck: deck, withBet: bet) }
		}
		else {
			dispatch_on_main { self.handler?(nil) }
			self.state = .running
			dispatch_async(.default) { self.beginEVCalculation(heldCards: heldCards, inDeck: deck, withBet: bet) }
		}
	}

	func beginEVCalculation(heldCards: [Card], inDeck deck: Deck, withBet bet: Int) {
		let startTime	= Date()
		let testHand	= Hand()
		
		for (index, card) in heldCards.enumerated() { testHand[index] = card }
		if heldCards.count < Consts.Game.MaxHandCards {
			var iterator	: DeckIterator
			var evCategory	: Hand.Category
			var ev			: Double = 0
			var count		= 0
			
			iterator = DeckIterator(hand: testHand, deck: deck, drawCount: Consts.Game.MaxHandCards - heldCards.count)
			while iterator.advanceWithHand(hand: testHand, deck: deck) != nil && self.state != .canceled {
				evCategory = testHand.cardSet.eval().category

				ev += Double(evCategory.payoutForBet(bet))
				count += 1
			}
			
			if self.state != .canceled {
				dispatch_on_main { self.handler?(ev / Double(count)) }
			}
		}
		else {
			dispatch_on_main { self.handler?(Double(testHand.evaluate().payoutForBet(bet))) }
		}

		if self.state != .canceled {
			Trace.debug("ev dur: \(String(format: "%2.5fs", Date().timeIntervalSince(startTime)))")
		}

		self.state = .stopped
	}
}

