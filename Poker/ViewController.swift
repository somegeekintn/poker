//
//  ViewController.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet var holdButtons: [UIButton]!
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Game.sharedGame().betHandler = {
			(newBet) in println("handler: \(newBet)")
		}
	}

	override func shouldAutorotate() -> Bool {
		return true;
	}
	
	override func supportedInterfaceOrientations() -> Int {
		return Int(UIInterfaceOrientationMask.Landscape.toRaw());
	}
	
	func reset() {
		for button in self.holdButtons {
			button.setTitle("Hold", forState: UIControlState.Normal)
		}
	}
	
	// MARK: - Handlers

	@IBAction func bet1(sender: AnyObject) {
		Game.sharedGame().incrementBet(amount: 1)
		println("bet now: \(Game.sharedGame().bet)")
	}
	
	@IBAction func betMax(sender: AnyObject) {
		Game.sharedGame().betMax()
		println("bet now: \(Game.sharedGame().bet)")
	}
	
	@IBAction func deal(sender: AnyObject) {
		switch Game.sharedGame().state {
			case Game.State.Ready:
				Game.sharedGame().deal();

			case Game.State.Dealt:
				Game.sharedGame().draw();

			case Game.State.Complete:
				break;
		}
		
		println("deal:\n\(Game.sharedGame())")
	}
	
	@IBAction func toggleHold(sender: AnyObject) {
		let button = sender as? UIButton;
		
		if let button = button {
			var card	= Game.sharedGame().playerCardAt(button.tag)
			
			if var card = card {
				card.hold = !card.hold
				button.setTitle(card.hold ? "Discard" : "Hold", forState: UIControlState.Normal)
				println("card: \(button.tag) hold: \(card.hold)")
			}
		}
	}
}
