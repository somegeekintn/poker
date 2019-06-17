//
//  Consts.swift
//  Poker
//
//  Created by Casey Fleser on 10/3/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation

struct Consts {
	struct Notifications {
		static let RefreshEV			: String = "QS_EVRefreshNotification"
	}
	
	struct Game {
		static let MaxDeckCards			: Int = 52
		static let MaxHandCards			: Int = 5
	}
	
	struct Views {
		static let PinAnimationTime		: TimeInterval = 0.50
		static let RevealAnimationTime	: TimeInterval = 0.30
		static let CardViewTagStart		: Int = 1000
	}
	
	struct Hands {
		static let SuitMask				= UInt(0x1fff)		// 13 bits
		static let SuitMask64			= UInt64(0x1fff)	// 13 bits
		static let RoyalStraightMask	= UInt(Card.Rank.Ace.rankBit | Card.Rank.King.rankBit | Card.Rank.Queen.rankBit | Card.Rank.Jack.rankBit | Card.Rank.Ten.rankBit)
		static let To6StraightMask		= UInt(Card.Rank.Six.rankBit | Card.Rank.Five.rankBit | Card.Rank.Four.rankBit | Card.Rank.Three.rankBit | Card.Rank.Two.rankBit)
		static let A5StraightMask		= UInt(Card.Rank.Five.rankBit | Card.Rank.Four.rankBit | Card.Rank.Three.rankBit | Card.Rank.Two.rankBit | Card.Rank.Ace.rankBit)
		static let AllStraightMasks		: [UInt] = [
			RoyalStraightMask,
			UInt(Card.Rank.King.rankBit | Card.Rank.Queen.rankBit | Card.Rank.Jack.rankBit | Card.Rank.Ten.rankBit | Card.Rank.Nine.rankBit),
			UInt(Card.Rank.Queen.rankBit | Card.Rank.Jack.rankBit | Card.Rank.Ten.rankBit | Card.Rank.Nine.rankBit | Card.Rank.Eight.rankBit),
			UInt(Card.Rank.Jack.rankBit | Card.Rank.Ten.rankBit | Card.Rank.Nine.rankBit | Card.Rank.Eight.rankBit | Card.Rank.Seven.rankBit),
			UInt(Card.Rank.Ten.rankBit | Card.Rank.Nine.rankBit | Card.Rank.Eight.rankBit | Card.Rank.Seven.rankBit | Card.Rank.Six.rankBit),
			UInt(Card.Rank.Nine.rankBit | Card.Rank.Eight.rankBit | Card.Rank.Seven.rankBit | Card.Rank.Six.rankBit | Card.Rank.Five.rankBit),
			UInt(Card.Rank.Eight.rankBit | Card.Rank.Seven.rankBit | Card.Rank.Six.rankBit | Card.Rank.Five.rankBit | Card.Rank.Four.rankBit),
			UInt(Card.Rank.Seven.rankBit | Card.Rank.Six.rankBit | Card.Rank.Five.rankBit | Card.Rank.Four.rankBit | Card.Rank.Three.rankBit),
			To6StraightMask,
			A5StraightMask
		]
	}
}
