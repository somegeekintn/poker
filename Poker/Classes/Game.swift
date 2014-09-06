//
//  Game.swift
//  Poker
//
//  Created by Casey Fleser on 7/14/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation

class Game : Printable {
	typealias betCallback = (newBet: Int) -> ()
	typealias stateCallback = (newState: State) -> ()

	var deck			= Deck()
	var hand			= Hand()
	var gameData		: GameData?
	var betHandler		: betCallback? = nil
	var stateHandler	: stateCallback? = nil
	var lastWin			: Int = 0
	
	class func sharedGame() -> Game! {
		struct Static {
			static var sSharedGame	: Game? = nil
			static var sOnceToken	: dispatch_once_t = 0
		}

		dispatch_once(&Static.sOnceToken) {
			Static.sSharedGame = self()
		}
		
		return Static.sSharedGame
	}
	
	class func maxBet() -> Int {
		return 5
	}
	
	var description: String {
		get {
			var desc = String()
			
			desc += "deck: \(self.deck)\n"
			desc += "hand: \(self.hand)\n"
			desc += "state: \(self.state)\n"
			desc += "bet: \(self.actualBet)"

			return desc
		}
	}
	
	var state : State = State.Ready {
		willSet(newValue) {
			if newValue == State.Ready {
				self.lastWin = 0
			}
			if var stateHandler = self.stateHandler {
				stateHandler(newState: newValue)
			}
		}
	}
	
	var credits : Int {
		var credits = 0
		
		if let gameData = self.gameData {
			credits = gameData.credits.integerValue
		}
		
		return credits
	}
	
	var actualBet : Int = 0 {
		didSet(oldValue) {
			if var betHandler = self.betHandler {
				betHandler(newBet: self.bet)
			}
		}
	}
	
    var bet : Int {
		// Swift's handling of getters / setters leaves something to be desired
		set (newValue) {
			var actualValue		= (newValue > Game.maxBet()) ? Game.maxBet() : newValue
			var betDelta		= actualValue - self.actualBet
			
			if (betDelta > self.credits) {
				actualValue -= betDelta - self.credits
				betDelta = actualValue - self.actualBet
			}
			
			if actualValue > 0 && self.state == State.Complete {
				self.state = State.Ready
			}
			
			if self.actualBet != actualValue {
				self.gameData?.betCredits(betDelta)
				self.actualBet = actualValue
			}
		}
	
		get {
			return self.actualBet
		}
	}
	
	var canDeal: Bool {
		get {
			return self.bet != 0 && self.state == State.Ready
		}
	}
	
	required init() {
		self.gameData = GameData.gameData()
	}
	
	// MARK: - Betting
	
	func incrementBet(amount: Int = Game.maxBet()) {
		self.bet += amount
	}
	
	func betMax() {
		self.incrementBet(amount: Game.maxBet())
	}
	
	// MARK: - Cards
	
	func playerCardAt(cardIndex: Int) -> Card? {
		return self.hand.cardAt(cardIndex)
	}
	
	func deal() -> Bool {
		var dealt	: Bool = false
		
		if self.canDeal {
			self.deck.shuffle()
			self.hand.initialDrawFromDeck(self.deck)
			self.state = State.Dealt
			dealt = true
		}
		
		return dealt
	}

	func draw() -> Bool {
		var drew	: Bool = false
		
		if self.state == State.Dealt {
			var winAmount		= 0
			var handCategory	: Hand.Category
			
			self.hand.drawFromDeck(self.deck)
			handCategory = self.hand.evaluate()
			self.lastWin = handCategory.payoutForBet(self.actualBet)
			if self.lastWin > 0 {
				self.gameData?.winCredits(self.lastWin)
			}
			self.state = State.Complete
			self.actualBet = 0
			drew = true
		}
		
		return drew
	}

	// MARK: - Debugging
	
	func stress() {
		self.betMax()
		for var idx=0; idx<100; idx++ {
			self.deal()
			if self.hand.evaluate() != Hand.Category.None {
				println("\(idx): \(self)")
			}
			
			self.state = Game.State.Ready
		}
	}

	enum State: Int, Printable {
		case Ready
		case Dealt
		case Complete

		var description: String {
			get {
				switch self {
					case .Ready:
						return "Ready"
					case .Dealt:
						return "Deal Complete"
					case .Complete:
						return "Game Complete"
				}
			}
		}
	}
}
