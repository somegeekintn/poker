//
//  Card.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

/* --- Globals --- */

func ==(lhs: Card, rhs: Card) -> Bool {
	return lhs.rank == rhs.rank && lhs.suit == rhs.suit;
}

func <(lhs: Card, rhs: Card) -> Bool {
	return lhs.rank < rhs.rank;
}

func <(lhs: Card.Rank, rhs: Card.Rank) -> Bool {
	return lhs.toRaw() < rhs.toRaw();
}

/* --- Card --- */

class Card : Comparable, Printable {
	let rank		: Rank
	let suit		: Suit
	var pin			: Bool = false		// indicates a card that is part of the current hand's category
	var hold		: Bool = false

	init(rank: Card.Rank, suit: Card.Suit) {
		self.rank = rank
		self.suit = suit
	}

	func reset() {
		self.pin = false
		self.hold = false
	}
	
    var description: String {
		get {
			return rank.description + suit.description
		}
	}

    var fullDescription: String {
		get {
			return rank.fullDescription + suit.fullDescription
		}
	}

	/* --- Rank --- */
	
	enum Rank: Int, Comparable, Printable {
		case Two = 0, Three, Four, Five, Six, Seven, Eight, Nine, Ten
		case Jack, Queen, King, Ace

		static let MinRank = Two
		static let MaxRank = Ace
		static let RankCount = MaxRank.toRaw() + 1
		
		var description: String {
			get {
				switch self {
					case .Ace:
						return "A"
					case .King:
						return "K"
					case .Queen:
						return "Q"
					case .Jack:
						return "J"
					case .Ten:
						return "T"
					case let someRank where someRank.toRaw() >= Two.toRaw() && someRank.toRaw() <= Nine.toRaw():
						return String(someRank.toRaw() + 2)
					default:
						return "?"
				}
			}
		}

		var fullDescription: String {
			get {
				switch self {
					case .Ace:
						return "Ace"
					case .King:
						return "King"
					case .Queen:
						return "Queen"
					case .Jack:
						return "Jack"
					case let someRank where someRank.toRaw() >= Two.toRaw() && someRank.toRaw() <= Ten.toRaw():
						return String(someRank.toRaw() + 2)
					default:
						return "?"
				}
			}
		}
		
		func nextHigher() -> Rank? {
			var next	: Rank? = nil;
			
			if (self != Ace) {
				next = Rank.fromRaw(self.toRaw() + 1)
			}
			
			return next;
		}
		
		func nextLower() -> Rank? {
			var prev	: Rank? = nil;
			
			if (self != Two) {
				prev = Rank.fromRaw(self.toRaw() - 1)
			}
			
			return prev;
		}
	}

	/* --- Suit --- */

	enum Suit: Int, Printable {
		case Club = 0, Diamond, Heart, Spade
		
		static let MinSuit		= Club
		static let MaxSuit		= Spade
		static let SuitCount	= MaxSuit.toRaw() + 1

		var description: String {
			get {
				switch self {
					case .Club:
						return "♣︎"
					case .Diamond:
						return "♦︎"
					case .Heart:
						return "♥︎"
					case .Spade:
						return "♠︎"
				}
			}
		}

		var fullDescription: String {
			get {
				switch self {
					case .Club:
						return "Club"
					case .Diamond:
						return "Diamond"
					case .Heart:
						return "Heart"
					case .Spade:
						return "Spade"
				}
			}
		}
	}
}

