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

// HUH? WHY IS THIS NECESSARY!?
func == (lhs: UIRectEdge, rhs: UIRectEdge) -> Bool     { return lhs.toRaw() == rhs.toRaw() }

class ViewController: UIViewController {
	@IBOutlet var betLabel				: UILabel!
	@IBOutlet var creditsLabel			: UILabel!
	@IBOutlet var winLabel				: UILabel!
	@IBOutlet var dealDrawButton		: UIButton!
	@IBOutlet var betMaxButton			: UIButton!
	@IBOutlet var betOneButton			: UIButton!
	@IBOutlet var cardContainer			: UIView!
	@IBOutlet var hCardCenterConstraint	: NSLayoutConstraint!
	var hasPerformedInitialLayout		= false
	var cardViews						: [CardView]?
	let cCardViewTagStart				: Int = 1000
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Game.sharedGame().betHandler = {
			(newBet: Int) -> () in
				self.updateElements(Game.sharedGame().state);
		}
		
		Game.sharedGame().stateHandler = {
			(newState: Game.State) -> () in
				// transitions here, while updateElements can be called at any point

				if var cardViews = self.cardViews {
					switch newState {
						case Game.State.Ready:
							for cardView in cardViews {
								cardView.card = nil
								cardView.revealed = false
							}
						case .Dealt:
							for cardView in cardViews {
								var card	= Game.sharedGame().playerCardAt(cardView.tag - self.cCardViewTagStart)
								
								cardView.card = card;
							}
							self.positionCards(UIRectEdge.None, animated: true, completion: {
								for cardView in cardViews {
									cardView.revealed = true
								}
						})
						case .Complete:
							for cardView in cardViews {
								var card	= Game.sharedGame().playerCardAt(cardView.tag - self.cCardViewTagStart)
								
								cardView.card = card;
							}
					}
				}
			
				self.updateElements(newState)
		}
	}

	override func viewDidLayoutSubviews()  {
		super.viewDidLayoutSubviews()
		
		self.performInitialLayout()
	}

	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> Int {
		return Int(UIInterfaceOrientationMask.Landscape.toRaw())
	}
	
	// Needed because for some reason, all subviews aren't actually loaded in viewDidLoad
	// Not sure if that's related to Swift or what exactly.
	func performInitialLayout() {
		if !self.hasPerformedInitialLayout {
			if self.cardViews == nil {
				var cardViews = [CardView]();
				for cardTag in self.cCardViewTagStart..<self.cCardViewTagStart + 5 {
					if var cardView = self.view.viewWithTag(cardTag) as? CardView {
						cardViews.append(cardView)
					}
				}
				
				self.cardViews = cardViews;
				self.updateElements(Game.sharedGame().state);
			}
			self.positionCards(UIRectEdge.Left, animated: false, completion: nil)

			self.betLabel.text = "0"
			self.creditsLabel.text = "0"
			self.winLabel.text = "0"
			self.hasPerformedInitialLayout = true
		}
	}
	
	func positionCards(position: UIRectEdge, animated: Bool = false, completion: (() -> ())?) {
		var offset : CGFloat = 0.0
		
		if position != UIRectEdge.None {
			offset = CGRectGetWidth(self.cardContainer.frame)
			
			if position == UIRectEdge.Left {
				offset *= -1.0
			}
		}
		
		self.hCardCenterConstraint.constant = offset;
		if animated {
			UIView.animateWithDuration(0.3, animations: {
				self.cardContainer.layoutIfNeeded()
			}, completion: {
				(finished: Bool) -> () in
				if let completion = completion {
					completion();
				}
			})
		}
		else {
			self.cardContainer.layoutIfNeeded()
		}
	}
	
	func updateElements(gameState: Game.State) {
		switch gameState {
			case Game.State.Ready:
				self.betMaxButton.enabled = true
				self.betOneButton.enabled = true
				self.dealDrawButton.enabled = Game.sharedGame().bet > 0
			case .Dealt:
				self.betMaxButton.enabled = false
				self.betOneButton.enabled = false
				self.dealDrawButton.enabled = true
			case .Complete:
				self.betMaxButton.enabled = false
				self.betOneButton.enabled = false
				self.dealDrawButton.enabled = false
		}
		self.betLabel.text = String(Game.sharedGame().bet)
	}
	
	// MARK: - Handlers
	
	@IBAction func handleBetOne(sender: AnyObject) {
		Game.sharedGame().incrementBet(amount: 1)
	}

	@IBAction func handleBetMax(sender: AnyObject) {
		if Game.sharedGame().state == Game.State.Ready {
			Game.sharedGame().betMax()
			Game.sharedGame().deal()
		}
	}

	@IBAction func handleDealDraw(sender: AnyObject) {
		switch Game.sharedGame().state {
			case Game.State.Ready:
				Game.sharedGame().deal()

			case Game.State.Dealt:
				Game.sharedGame().draw()

			case Game.State.Complete:
				break
		}
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
