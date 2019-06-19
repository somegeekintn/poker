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
}
