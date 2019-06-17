//
//  Card.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

// MARK: - Globals

func ==(lhs: Card, rhs: Card) -> Bool {
	return lhs.rank == rhs.rank && lhs.suit == rhs.suit
}

func <(lhs: Card, rhs: Card) -> Bool {
	return lhs.rank < rhs.rank
}

func <(lhs: Card.Rank, rhs: Card.Rank) -> Bool {
	return lhs.rawValue < rhs.rawValue
}

// MARK: - Card

class Card : Comparable, CustomStringConvertible {
	final let rank		: Rank
	final let suit		: Suit
	final let bitFlag	: UInt64
	var pin				: Bool = false		// indicates a card that is part of the current hand's category
	var hold			: Bool = false
    var description		: String { return rank.description + suit.description }
    var fullDescription	: String { return rank.fullDescription + suit.fullDescription }

	init(rank: Card.Rank, suit: Card.Suit) {
		self.rank = rank
		self.suit = suit
		self.bitFlag = UInt64(self.rank.rankBit) << self.suit.shiftVal
	}

	func reset() {
		self.pin = false
		self.hold = false
	}
	
	// MARK: - Rank
	
	enum Rank: Int, Comparable, CustomStringConvertible {
		case two = 0, three, four, five, six, seven, eight, nine, ten
		case jack, queen, king, ace

		static let minRank	= Rank.two
		static let maxRank	= Rank.ace
		static let numRanks	= Rank.maxRank.rawValue + 1
		static let allRanks	: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace]

		var identifier		: String { return self.description }
		var rankBit			: UInt { return UInt(1 << self.rawValue) }
		var description		: String {
			get {
				switch self {
					case .ace:
						return "A"
					case .king:
						return "K"
					case .queen:
						return "Q"
					case .jack:
						return "J"
					case .ten:
						return "T"
					case let someRank where someRank.rawValue >= Rank.two.rawValue && someRank.rawValue <= Rank.nine.rawValue:
						return String(someRank.rawValue + 2)
					default:
						return "?"
				}
			}
		}

		var fullDescription	: String {
			get {
				switch self {
					case .ace:
						return "Ace"
					case .king:
						return "King"
					case .queen:
						return "Queen"
					case .jack:
						return "Jack"
					case let someRank where someRank.rawValue >= Rank.two.rawValue && someRank.rawValue <= Rank.nine.rawValue:
						return String(someRank.rawValue + 2)
					default:
						return "?"
				}
			}
		}

		var nextHigher		: Rank? { return self != Rank.ace ? Rank(rawValue: self.rawValue + 1) : nil }
		var nextLower		: Rank? { return self != Rank.two ? Rank(rawValue: self.rawValue - 1) : nil }
	}

	// MARK: - Suit

	enum Suit: Int, CustomStringConvertible {
		case club = 0, diamond, heart, spade
		
		static let minSuit		= Suit.club
		static let maxSuit		= Suit.spade
		static let numSuits		= Suit.maxSuit.rawValue + 1
		static let allSuits		: [Suit] = [.club, .diamond, .heart, .spade]
		
		var shiftVal			: UInt64 { return UInt64(self.rawValue * Card.Rank.numRanks) }
		var identifier			: String {
			get {
				switch self {
					case .club:		return "C"
					case .diamond:	return "D"
					case .heart:	return "H"
					case .spade:	return "S"
				}
			}
		}
		
		var description			: String {
			get {
				switch self {
					case .club:		return "♣︎"
					case .diamond:	return "♦︎"
					case .heart:	return "♥︎"
					case .spade:	return "♠︎"
				}
			}
		}

		var fullDescription		: String {
			get {
				switch self {
					case .club:		return "Club"
					case .diamond:	return "Diamond"
					case .heart:	return "Heart"
					case .spade:	return "Spade"
				}
			}
		}
	}
}

