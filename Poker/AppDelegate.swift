//
//  AppDelegate.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window								: UIWindow?

	// MARK: - Core Data stack

#warning("Real app would handle Core Data errors")

	lazy var applicationDocumentsDirectory	: URL? = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		
		return urls.last
	}()

	lazy var managedObjectModel				: NSManagedObjectModel? = {
		guard let modelURL = Bundle.main.url(forResource: "Poker", withExtension: "momd") else { return nil }
		
		return NSManagedObjectModel(contentsOf: modelURL)
	}()

	lazy var persistentStoreCoordinator		: NSPersistentStoreCoordinator? = {
		guard let managedObjectModel	= self.managedObjectModel else { return nil }
		let url							= self.applicationDocumentsDirectory?.appendingPathComponent("Poker.sqlite")
	    var coordinator					= NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

		do {
			try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
		}
		catch (let error as NSError) {
	        abort()
		}
		
		return coordinator
	}()
	
	lazy var managedObjectContext			: NSManagedObjectContext? = {
	    guard let coordinator		= self.persistentStoreCoordinator else { return nil }
	    var managedObjectContext	= NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		
	    managedObjectContext.persistentStoreCoordinator = coordinator
		
	    return managedObjectContext
	}()

	private func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
		self.saveContext()
	}

	// MARK: - Core Data Saving support

	func saveContext() {
		guard let moc	= self.managedObjectContext else { return }
		
		if moc.hasChanges {
			do {
				try moc.save()
			}
			catch (let error as NSError) {
				NSLog("Unresolved error \(error), \(error.userInfo)")
			}
		}
	}
}

