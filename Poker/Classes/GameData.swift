//
//  GameData.swift
//  Poker
//
//  Created by Casey Fleser on 9/5/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class GameData: NSManagedObject {
    @NSManaged var credits		: NSNumber
    @NSManaged var totalBet		: NSNumber
    @NSManaged var totalWon		: NSNumber
	
    class func gameData() -> GameData? {
		guard let appDelegate	= UIApplication.shared.delegate as? AppDelegate else { return nil }
		guard let context		= appDelegate.managedObjectContext else { return nil }
		let request				= NSFetchRequest<GameData>(entityName: "GameData")
		var gameData			: GameData?
		
		if let results = try? context.fetch(request), results.count > 0 {
			gameData = results[0]
		}
		else {
			gameData = NSEntityDescription.insertNewObject(forEntityName: "GameData", into: context) as? GameData
			gameData?.credits = 1000
			appDelegate.saveContext()
		}
		
		return gameData
	}
	
	func saveData() {
		(UIApplication.shared.delegate as? AppDelegate)?.saveContext()
	}
	
	func betCredits(amount: Int) {
		self.credits = NSNumber(value: self.credits.intValue - amount)
		self.totalBet = NSNumber(value: self.totalBet.intValue + amount)
		self.saveData()
	}
	
	func winCredits(amount: Int) {
		self.credits = NSNumber(value: self.credits.intValue + amount)
		self.totalWon = NSNumber(value: self.totalWon.intValue + amount)
		self.saveData()
	}
}

