//
//  Game.swift
//  Poker
//
//  Created by Casey Fleser on 7/14/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

class Game : Printable {
	var deck		= Deck()
	var hand		= Hand()
	var state		= State.Ready
	var actualBet	= 0
	let maxBet		: Int = 5
	
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
	
    var bet : Int {
		// Swift's handling of getters / setters leaves something to be desired
		set(newValue) {
			self.actualBet = (newValue > self.maxBet) ? self.maxBet : newValue
		}
	
		get {
			return self.actualBet;
		}
	}
	
	func canDeal() -> Bool {
		return self.bet != 0 && self.state == State.Ready
	}
	
	func deal() {
		if (self.canDeal()) {
			self.deck.shuffle()
			self.hand.initialDrawFromDeck(self.deck)
			self.state = State.Dealt
		}
	}

	enum State: Int, Printable {
		case Ready = 0
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
