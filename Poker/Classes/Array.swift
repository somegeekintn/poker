//
//  Array.swift
//  Poker
//
//  Created by Casey Fleser on 10/3/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

extension Array {
	func iterate(apply: (T) -> ()) {
		for item in self { apply(item) }
	}
}

