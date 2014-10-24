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
	typealias evCallback = (newEv: Double?) -> ()
	typealias stateCallback = (newState: State) -> ()

	var deck					= Deck()
	var hand					= Hand()
	var evCalcState				= EvCalcState.Stopped
	var gameData				: GameData?
	var betHandler				: betCallback? = nil
	var evHandler				: evCallback? = nil
	var stateHandler			: stateCallback? = nil
	var lastWin					: Int = 0
	
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
	
	// MARK: - Var

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
	
	var credits : Int {
		var credits = 0
		
		if let gameData = self.gameData {
			credits = gameData.credits.integerValue
		}
		
		return credits
	}
	
	var ev : Double? = nil {
		willSet(newValue) {
			if var evHandler = self.evHandler {
				dispatch_async(dispatch_get_main_queue()) { evHandler(newEv: newValue) }
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
			
			if var stateHandler = self.stateHandler {
				stateHandler(newState: newValue)
			}
		}
	}
	
	// MARK: - Lifecycle
	
	required init() {
		self.gameData = GameData.gameData()
		
		NSNotificationCenter.defaultCenter().addObserverForName(Consts.Notifications.RefreshEV, object: nil, queue: nil) { (notification : NSNotification!) in
			self.calculateEV()
		}
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	// MARK: - Betting
	
	func incrementBet(amount: Int = Game.maxBet()) {
		if self.state == State.Complete {
			self.state = State.Ready
		}
		
		self.bet += amount
	}
	
	func betMax() {
		self.incrementBet(amount: Game.maxBet())
	}
	
	// MARK: - Cards
	
	func playerCardAt(cardIndex: Int) -> Card? {
		return self.hand[cardIndex]
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
			drew = true
		}
		
		return drew
	}

	func calculateEV() {
		if self.evCalcState != EvCalcState.Stopped {
			self.evCalcState = EvCalcState.Canceled
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { self.calculateEV() }
		}
		else {
			self.ev = nil
			self.evCalcState = EvCalcState.Running
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
				var heldCards	= self.hand.heldCards()
				var startTime	= NSDate()
				
				if heldCards.count < Consts.Game.MaxHandCards {
					var iterator	: DeckIterator
					var evHand		= Hand()
					var evCategory	: Hand.Category
					var ev			: Double = 0
					var count		= 0
					
					for (index, card) in enumerate(heldCards) {
						evHand[index] = card
					}

					iterator = DeckIterator(hand: evHand, deck: self.deck, drawCount: Consts.Game.MaxHandCards - heldCards.count)
					while iterator.advanceWithHand(evHand, deck: self.deck) && self.evCalcState != EvCalcState.Canceled {
						evCategory = evHand.fastEval()

						ev += Double(evCategory.payoutForBet(self.actualBet))
						count++
					}
					
					if self.evCalcState != EvCalcState.Canceled {
						self.ev = ev / Double(count)
					}
				}
				else {
					self.ev = Double(self.hand.evaluate().payoutForBet(self.actualBet))
				}
				
				var dur		= NSDate().timeIntervalSinceDate(startTime)
				println("ev dur: \(dur)")
				
				self.evCalcState = EvCalcState.Stopped
			}
		}
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
	
	enum EvCalcState: Int {
		case Stopped
		case Running
		case Canceled
	}
}
