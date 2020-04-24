//
//  Game.swift
//  Poker
//
//  Created by Casey Fleser on 7/14/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation
import Combine

class Game : CustomStringConvertible {
	enum State: CustomStringConvertible {
		case ready
		case dealt
		case complete(result: Hand.Category)

		var description: String {
			get {
				switch self {
					case .ready:				return "Ready"
					case .dealt:				return "Deal Complete"
					case .complete(let result):	return "Game Complete: \(result)"
				}
			}
		}
	}

	static var shared			= Game()
	static let maxBet			= 5

	var deck					= Deck()
	var hand					= Hand()
	var gameData				: GameData?
	let evCalculator			= EVCalculator()
	
	var lastWin					: Int = 0
	
	var evPublisher				: Published<EVCalculator.State>.Publisher { return self.evCalculator.$state }
	var canDeal					: Bool { if case .ready = self.state, self.bet != 0 { return true } else { return false } }
	var credits					: Int { return self.gameData?.credits.intValue ?? 0 }

	@Published var actualBet	: Int = 0
	private var evRefeshMonitor	: AnyCancellable?

    var bet						: Int {
		set (newValue) {
			var actualValue		= (newValue > Game.maxBet) ? Game.maxBet : newValue
			var betDelta		= actualValue - self.actualBet
			
			if (betDelta > self.credits) {
				actualValue -= betDelta - self.credits
				betDelta = actualValue - self.actualBet
			}
			
			if case .complete = self.state, actualValue > 0 {
				self.state = .ready
			}
			
			if self.actualBet != actualValue {
				self.gameData?.betCredits(amount: betDelta)
				self.actualBet = actualValue
			}
		}
	
		get {
			return self.actualBet
		}
	}
	
	@Published var state		: State = State.ready {
		willSet(newValue) {
			switch newValue {
				case .ready:
					self.actualBet = 0
					self.lastWin = 0
				
				case .dealt:
					self.calculateEV()
				
				case .complete:
					self.evCalculator.reset()
			}
		}
	}
	
	var description				: String {
		get {
			var desc = String()
			
			desc += "deck: \(self.deck)\n"
			desc += "hand: \(self.hand)\n"
			desc += "state: \(self.state)\n"
			desc += "bet: \(self.actualBet)"

			return desc
		}
	}

	// MARK: - Lifecycle
	
	required init() {
		self.gameData = GameData.gameData()
		self.evRefeshMonitor = NotificationCenter.default.publisher(for: NSNotification.Name(Consts.Notifications.RefreshEV)).sink { [weak self] _ in self?.calculateEV() }
	}
	
	// MARK: - Betting
	
	func incrementBet(amount: Int = Game.maxBet) {
		if case .complete = self.state  {
			self.state = .ready
		}
		
		self.bet += amount
	}
	
	func betMax() {
		self.incrementBet(amount: Game.maxBet)
	}
	
	// MARK: - Cards
	
	func playerCardAt(cardIndex: Int) -> Card? {
		return self.hand[cardIndex]
	}
	
	@discardableResult func deal() -> Bool {
		var dealt	: Bool = false
		
		if self.canDeal {
			self.deck.shuffle()
			self.hand.initialDrawFromDeck(self.deck)
			self.state = .dealt
			dealt = true
		}
		
		return dealt
	}

	@discardableResult func draw() -> Bool {
		var drew	: Bool = false
		
		if case .dealt = self.state {
			let result	: Hand.Category
			
			self.hand.drawFromDeck(self.deck)
			result = self.hand.evaluate()
			self.lastWin = result.payoutForBet(self.actualBet)
			if self.lastWin > 0 {
				self.gameData?.winCredits(amount: self.lastWin)
			}
			self.state = .complete(result: result)
			drew = true
		}
		
		return drew
	}
	var calculator	: AnyCancellable?
	
	func calculateEV() {
		self.evCalculator.calculateEV(heldCards: self.hand.heldCards, inDeck: self.deck, withBet: self.actualBet)
//
//		self.calculator = EVCalculator.Publisher(cards: self.hand.heldCards, inDeck: self.deck, withBet: self.actualBet).sink { (state) in
//			print("published state: \(state)")
//		}
	}

	// MARK: - Debugging
	
	func stress() {
		self.betMax()
		for idx in 0..<100 {
			self.deal()
			if self.hand.evaluate() != .none {
				print("\(idx): \(self)")
			}
			
			self.state = .ready
		}
	}
}
