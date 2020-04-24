//
//  EVCalculator.swift
//  Poker
//
//  Created by Casey Fleser on 6/19/19.
//  Copyright © 2019 Quiet Spark. All rights reserved.
//
//  A smart person probably knows a fast mathy way to do this versus the
//  brute force approach we're taking here.

import Foundation
import Combine

class EVCalculator {
	enum State {
		case ready
		case calculating
		case complete(ev: Double)
		case cancelling

		var shouldCancel	: Bool {
			switch self {
				case .cancelling:	return true
				default:			return false
			}
		}
	}

	@Published var state		= State.ready
	private var calcPrep		: AnyCancellable?
	
	func calculateEV(heldCards: [Card], inDeck deck: Deck, withBet bet: Int) {
		self.calcPrep = self.$state
			.filter { [weak self] (state) -> Bool in
				guard let this = self else { return false }
				switch state {
					case .ready, .complete:
						return true

					case .calculating:
						this.state = .cancelling
						fallthrough

					default:
						return false
				}
			}
			.sink { [weak self] _ in
				guard let this = self else { return }

				dispatch_async(.default) {
					this.calcPrep = nil
					this.beginEVCalculation(heldCards: heldCards, inDeck: deck, withBet: bet)
				}
			}
	}

	func beginEVCalculation(heldCards: [Card], inDeck deck: Deck, withBet bet: Int) {
		let startTime	= Date()
		let testHand	= Hand(cards: heldCards)
		
		self.state = .calculating
		
//		testHand.fillWithCards(heldCards)
		if heldCards.count < Consts.Game.MaxHandCards {
			var iterator	: DeckIterator
			var evCategory	: Hand.Category
			var ev			: Double = 0
			var count		= 0
			
			iterator = DeckIterator(hand: testHand, deck: deck, drawCount: Consts.Game.MaxHandCards - heldCards.count)
			while iterator.advanceWithHand(hand: testHand, deck: deck) != nil && !self.state.shouldCancel {
				evCategory = testHand.cardSet.eval().category

				ev += Double(evCategory.payoutForBet(bet))
				count += 1
			}
			
			if case .calculating = self.state {
				self.state = .complete(ev: ev / Double(count))
			}
		}
		else {
			self.state = .complete(ev: Double(testHand.evaluate().payoutForBet(bet)))
		}

		switch self.state {
			case .cancelling:
				self.state = .ready
			case .complete(let ev):
				Trace.debug("ev dur: \(String(format: "%2.5fs", Date().timeIntervalSince(startTime))) = \(ev)")
			default:
				break
		}
	}

	func reset() {
		switch self.state {
			case .calculating:
				self.state = .cancelling
			case .complete:
				self.state = .ready
			default:
				break
		}
	}
}

