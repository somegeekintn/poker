//
//  UInt.swift
//  Poker
//
//  Created by Casey Fleser on 10/23/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

extension UInt {
	func bitCount() -> Int {
		var workVal	= self
		var count	= 0
		
		while workVal != 0 {
			workVal &= workVal - 1
			count++
		}
		
		return count
	}
}
