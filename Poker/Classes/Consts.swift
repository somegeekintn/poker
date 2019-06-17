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
		static let RoyalStraightMask	= UInt(Card.Rank.ace.rankBit | Card.Rank.king.rankBit | Card.Rank.queen.rankBit | Card.Rank.jack.rankBit | Card.Rank.ten.rankBit)
		static let To6StraightMask		= UInt(Card.Rank.six.rankBit | Card.Rank.five.rankBit | Card.Rank.four.rankBit | Card.Rank.three.rankBit | Card.Rank.two.rankBit)
		static let A5StraightMask		= UInt(Card.Rank.five.rankBit | Card.Rank.four.rankBit | Card.Rank.three.rankBit | Card.Rank.two.rankBit | Card.Rank.ace.rankBit)
		static let AllStraightMasks		: [UInt] = [
			RoyalStraightMask,
			UInt(Card.Rank.king.rankBit | Card.Rank.queen.rankBit | Card.Rank.jack.rankBit | Card.Rank.ten.rankBit | Card.Rank.nine.rankBit),
			UInt(Card.Rank.queen.rankBit | Card.Rank.jack.rankBit | Card.Rank.ten.rankBit | Card.Rank.nine.rankBit | Card.Rank.eight.rankBit),
			UInt(Card.Rank.jack.rankBit | Card.Rank.ten.rankBit | Card.Rank.nine.rankBit | Card.Rank.eight.rankBit | Card.Rank.seven.rankBit),
			UInt(Card.Rank.ten.rankBit | Card.Rank.nine.rankBit | Card.Rank.eight.rankBit | Card.Rank.seven.rankBit | Card.Rank.six.rankBit),
			UInt(Card.Rank.nine.rankBit | Card.Rank.eight.rankBit | Card.Rank.seven.rankBit | Card.Rank.six.rankBit | Card.Rank.five.rankBit),
			UInt(Card.Rank.eight.rankBit | Card.Rank.seven.rankBit | Card.Rank.six.rankBit | Card.Rank.five.rankBit | Card.Rank.four.rankBit),
			UInt(Card.Rank.seven.rankBit | Card.Rank.six.rankBit | Card.Rank.five.rankBit | Card.Rank.four.rankBit | Card.Rank.three.rankBit),
			To6StraightMask,
			A5StraightMask
		]
	}
}
