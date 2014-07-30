//
//  ViewController.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit

extension UIView {
	func dumpViews(depth: Int = 0) {
		var tabs = String();
		
		for idx in 0..<depth {
			tabs += "\t"
		}
		println("\(tabs)-\(self)")
		
		for view in self.subviews {
			view.dumpViews(depth: depth + 1);
		}
	}
}

class ViewController: UIViewController {
	@IBOutlet var betField: UILabel!
	var holdButtons: [UIButton]?
	let cHoldButtonTagStart: Int = 1000
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Game.sharedGame().betHandler = {
			(newBet: Int) -> () in
				println("handler: \(newBet)")
				self.betField.text = "Bet: \(newBet)"
		}
		
		Game.sharedGame().stateHandler = {
			(newState: Game.State) -> () in
				println("new state: \(newState)")
				self.updateElements()
		}
	}

	override func viewDidLayoutSubviews()  {
		super.viewDidLayoutSubviews()
		
		// We do this here because for some reason, all subviews aren't actually loaded in viewDidLoad
		// Not sure if that's related to Swift or what exactly. Not ideal, but unsure what else to do
		if !self.holdButtons {
			var buttons = [UIButton]();
			for buttonTag in self.cHoldButtonTagStart..<self.cHoldButtonTagStart + 5 {
				if var buttonView = self.view.viewWithTag(buttonTag) as? UIButton {
					buttons.append(buttonView)
				}
			}
			
			self.holdButtons = buttons;
			updateElements();
		}
	}

	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> Int {
		return Int(UIInterfaceOrientationMask.Landscape.toRaw())
	}
	
	func updateElements() {
		if var holdButtons = self.holdButtons {
			for button in holdButtons {
				var card = Game.sharedGame().playerCardAt(button.tag - 1000)
				let enabled: Bool = card != nil
				let held: Bool = !card?.hold

				button.enabled = enabled
				button.setTitle("Hold", forState: UIControlState.Normal)
			}
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
				Game.sharedGame().deal()

			case Game.State.Dealt:
				Game.sharedGame().draw()

			case Game.State.Complete:
				break
		}
		
		println("deal:\n\(Game.sharedGame())")
	}
	
	@IBAction func toggleHold(sender: AnyObject) {
		let button = sender as? UIButton
		
		if let button = button {
			var card	= Game.sharedGame().playerCardAt(button.tag - 1000)
			
			if var card = card {
				card.hold = !card.hold
				button.setTitle(card.hold ? "Discard" : "Hold", forState: UIControlState.Normal)
				println("card: \(button.tag) hold: \(card.hold)")
			}
		}
	}
}
