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
		var gameData		: GameData?
		var appDelegate		= UIApplication.sharedApplication().delegate as! AppDelegate?
		
		if let appDelegate = appDelegate {
			if let context = appDelegate.managedObjectContext {
				var request =	NSFetchRequest(entityName: "GameData")
				
				if let results = context.executeFetchRequest(request, error: nil) {
					gameData = results.first as? GameData
				}

				if gameData == nil {
					gameData = NSEntityDescription.insertNewObjectForEntityForName("GameData", inManagedObjectContext: context) as? GameData
					gameData?.credits = 1000
					appDelegate.saveContext()
				}
			}
		}
		
		return gameData
	}
	
	func saveData() {
		var appDelegate		= UIApplication.sharedApplication().delegate as! AppDelegate?
		
		if let appDelegate = appDelegate {
			appDelegate.saveContext()
		}
	}
	
	func betCredits(amount: Int) {
		self.credits = self.credits.integerValue - amount
		self.totalBet = self.totalBet.integerValue + amount
		self.saveData()
	}
	
	func winCredits(amount: Int) {
		self.credits = self.credits.integerValue + amount
		self.totalWon = self.totalWon.integerValue + amount
		self.saveData()
	}
}

