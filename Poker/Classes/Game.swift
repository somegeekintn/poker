//
//  Game.swift
//  Poker
//
//  Created by Casey Fleser on 7/14/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation

class Game : CustomStringConvertible {
	typealias betCallback = (_ nnewBet: Int) -> ()
	typealias evCallback = (_ newEv: Double?) -> ()
	typealias stateCallback = (_ newState: State) -> ()

	static var shared			= Game()
	class var maxBet			: Int { return 5 }

	var deck					= Deck()
	var hand					= Hand()
	var evCalcState				= EvCalcState.Stopped
	var gameData				: GameData?
	var betHandler				: betCallback? = nil
	var evHandler				: evCallback? = nil
	var stateHandler			: stateCallback? = nil
	var lastWin					: Int = 0

	var actualBet				: Int = 0 {
		didSet(oldValue) {
			self.betHandler?(self.bet)
		}
	}
	
    var bet						: Int {
		set (newValue) {
			var actualValue		= (newValue > Game.maxBet) ? Game.maxBet : newValue
			var betDelta		= actualValue - self.actualBet
			
			if (betDelta > self.credits) {
				actualValue -= betDelta - self.credits
				betDelta = actualValue - self.actualBet
			}
			
			if actualValue > 0 && self.state == State.Complete {
				self.state = State.Ready
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
	
	var canDeal: Bool {
		get {
			return self.bet != 0 && self.state == State.Ready
		}
	}
	
	var credits : Int {
		var credits = 0
		
		if let gameData = self.gameData {
			credits = gameData.credits.intValue
		}
		
		return credits
	}
	
	var ev : Double? = nil {
		willSet(newValue) {
			if let evHandler = self.evHandler {
				DispatchQueue.main.async { evHandler(newValue) }
			}
		}
	}
	
	var state : State = State.Ready {
		willSet(newValue) {
			if newValue == State.Ready {
				self.actualBet = 0
				self.lastWin = 0
				self.ev = nil
			}
			else if (newValue == State.Dealt) {
				self.calculateEV()
			}
			
			self.stateHandler?(newValue)
		}
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

	// MARK: - Lifecycle
	
	required init() {
		self.gameData = GameData.gameData()
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name(Consts.Notifications.RefreshEV), object: nil, queue: nil) { [weak self] _ in
			self?.calculateEV()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Betting
	
	func incrementBet(amount: Int = Game.maxBet) {
		if self.state == State.Complete {
			self.state = State.Ready
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
			self.state = State.Dealt
			dealt = true
		}
		
		return dealt
	}

	@discardableResult func draw() -> Bool {
		var drew	: Bool = false
		
		if self.state == State.Dealt {
			var handCategory	: Hand.Category
			
			self.hand.drawFromDeck(self.deck)
			handCategory = self.hand.evaluate()
			self.lastWin = handCategory.payoutForBet(self.actualBet)
			if self.lastWin > 0 {
				self.gameData?.winCredits(amount: self.lastWin)
			}
			self.state = State.Complete
			drew = true
		}
		
		return drew
	}

	func calculateEV() {
		if self.evCalcState != EvCalcState.Stopped {
			self.evCalcState = EvCalcState.Canceled
			delay(0.1) { self.calculateEV() }
		}
		else {
			self.ev = nil
			self.evCalcState = EvCalcState.Running
			dispatch_async(.default) {
				let heldCards	= self.hand.heldCards()
//				var startTime	= NSDate()
				
				if heldCards.count < Consts.Game.MaxHandCards {
					var iterator	: DeckIterator
					let evHand		= Hand()
					var evCategory	: Hand.Category
					var ev			: Double = 0
					var count		= 0
					
					for (index, card) in heldCards.enumerated() {
						evHand[index] = card
					}

					iterator = DeckIterator(hand: evHand, deck: self.deck, drawCount: Consts.Game.MaxHandCards - heldCards.count)
					while iterator.advanceWithHand(hand: evHand, deck: self.deck) && self.evCalcState != EvCalcState.Canceled {
						evCategory = evHand.fastEval()

						ev += Double(evCategory.payoutForBet(self.actualBet))
						count += 1
					}
					
					if self.evCalcState != EvCalcState.Canceled {
						self.ev = ev / Double(count)
					}
				}
				else {
					self.ev = Double(self.hand.evaluate().payoutForBet(self.actualBet))
				}
//				
//				var dur		= NSDate().timeIntervalSinceDate(startTime)
//				println("ev dur: \(dur)")
				
				self.evCalcState = EvCalcState.Stopped
			}
		}
	}

	// MARK: - Debugging
	
	func stress() {
		self.betMax()
		for idx in 0..<100 {
			self.deal()
			if self.hand.evaluate() != Hand.Category.None {
				print("\(idx): \(self)")
			}
			
			self.state = Game.State.Ready
		}
	}

	enum State: Int, CustomStringConvertible {
		case Ready
		case Dealt
		case Complete

		var description: String {
			get {
				switch self {
					case .Ready:	return "Ready"
					case .Dealt:	return "Deal Complete"
					case .Complete:	return "Game Complete"
				}
			}
		}
	}
	
	enum EvCalcState: Int {
		case Stopped
		case Running
		case Canceled
	}
}
