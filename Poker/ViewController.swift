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
		var tabs = String()
		
		for idx in 0..<depth {
			tabs += "\t"
		}
		println("\(tabs)-\(self)")
		
		for view in self.subviews {
			view.dumpViews(depth: depth + 1)
		}
	}
}

// HUH? WHY IS THIS NECESSARY!?
func == (lhs: UIRectEdge, rhs: UIRectEdge) -> Bool     { return lhs.toRaw() == rhs.toRaw() }

class ViewController: UIViewController {
	// MARK: - Variables

	@IBOutlet var betLabel				: UILabel!
	@IBOutlet var creditsLabel			: UILabel!
	@IBOutlet var winLabel				: UILabel!
	@IBOutlet var dealDrawButton		: UIButton!
	@IBOutlet var betMaxButton			: UIButton!
	@IBOutlet var betOneButton			: UIButton!
	@IBOutlet var cardContainer			: UIView!
	@IBOutlet var hCardCenterConstraint	: NSLayoutConstraint!
	var cardViews						: [CardView]?
	let kCardViewTagStart				: Int = 1000
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Game.sharedGame().betHandler = { (newBet: Int) -> () in
			self.updateElements(Game.sharedGame().state)
		}
		
		Game.sharedGame().stateHandler = { (newState: Game.State) -> () in
			// transitions here, while updateElements can be called at any point
			if var cardViews = self.cardViews {
				switch newState {
					case .Ready:
						for cardView in cardViews {
							cardView.card = nil
							cardView.revealed = false
						}
					case .Dealt:
						for cardView in cardViews {
							var card	= Game.sharedGame().playerCardAt(cardView.tag - self.kCardViewTagStart)
							
							cardView.card = card
						}
						self.positionCards(UIRectEdge.None, animated: true, completion: {
							for cardView in cardViews {
								cardView.setRevealed(true, animated: true)
								cardView.enabled = true
							}
						})
					case .Complete:
						var result			= Game.sharedGame().hand.evaluate()
						var revealCount		= 0
						var dispatchTime	: Int64 = 0
						
						for cardView in cardViews {
							cardView.enabled = false
							if !cardView.revealed {
								var card	= Game.sharedGame().playerCardAt(cardView.tag - self.kCardViewTagStart)
							
								cardView.card = card
								cardView.setRevealed(true, animated: true)
								revealCount++
							}
							else {
								cardView.card?.hold = false
								cardView.update()
							}
						}
						if revealCount > 0 {
							// card flip + a slight pause to allow player a moment to recognize before we do
							dispatchTime = Int64((0.25 + CardView.RevealTime()) * Double(NSEC_PER_SEC))
						}
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, dispatchTime), dispatch_get_main_queue(), {
							for cardView in cardViews {
								cardView.animatePinned()
							}
						})
				}
			}
		
			self.updateElements(newState)
		}

		self.resetViews()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		self.positionCards(UIRectEdge.Left, animated: false, completion: nil)	// better place for this?
	}
	
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	func resetViews() {
		if self.cardViews == nil {
			var cardViews = [CardView]()
			for cardTag in self.kCardViewTagStart..<self.kCardViewTagStart + 5 {
				if var cardView = self.view.viewWithTag(cardTag) as? CardView {
					cardViews.append(cardView)
					cardView.update()
				}
			}
			
			self.cardViews = cardViews
			self.updateElements(Game.sharedGame().state)
		}
		
		self.betLabel.text = String(Game.sharedGame().bet)
		self.creditsLabel.text = String(Game.sharedGame().credits)
		self.winLabel.text = String(Game.sharedGame().lastWin)
	}
	
	func positionCards(position: UIRectEdge, animated: Bool = false, completion: (() -> ())?) {
		var offset			: CGFloat = 0.0
		var animationDelay	: NSTimeInterval = 0.0
		
		if position != UIRectEdge.None {
			animationDelay = CardView.RevealTime()
			offset = CGRectGetWidth(self.cardContainer.frame)
			
			if position == UIRectEdge.Left {
				offset *= -1.0
			}
		}

		self.hCardCenterConstraint.constant = offset
		if animated {
			UIView.animateWithDuration(0.25, animations: {
				self.cardContainer.layoutIfNeeded()
			}, completion: { (finished: Bool) -> () in
				if position != UIRectEdge.None {
					self.resetAllCards()
				}
				if let completion = completion {
					completion()
				}
			})
		}
		else {
			if position != UIRectEdge.None {
				self.resetAllCards()
			}
			self.cardContainer.layoutIfNeeded()
		}
	}
	
	func resetAllCards(animated: Bool = false) {
		if let cardViews = self.cardViews {
			for cardView in cardViews {
				cardView.setRevealed(false, animated: animated)
				cardView.resetPinned()
			}
		}
	}
	
	func updateElements(gameState: Game.State) {
		switch gameState {
			case .Ready:
				self.betMaxButton.enabled = true
				self.betOneButton.enabled = true
				self.dealDrawButton.enabled = Game.sharedGame().bet > 0
			case .Dealt:
				self.betMaxButton.enabled = false
				self.betOneButton.enabled = false
				self.dealDrawButton.enabled = true
			case .Complete:
				self.betMaxButton.enabled = true
				self.betOneButton.enabled = true
				self.dealDrawButton.enabled = false
		}
		self.betLabel.text = String(Game.sharedGame().bet)
		self.creditsLabel.text = String(Game.sharedGame().credits)
		self.winLabel.text = String(Game.sharedGame().lastWin)
	}
	
	// MARK: - Handlers

	@IBAction func handleBetOne(sender: AnyObject) {
		if Game.sharedGame().state == Game.State.Complete {
			self.positionCards(UIRectEdge.Left, animated: true, completion: {
				Game.sharedGame().state = Game.State.Ready
				Game.sharedGame().incrementBet(amount: 1)
			})
		}
		else {
			Game.sharedGame().incrementBet(amount: 1)
		}
	}

	@IBAction func handleBetMax(sender: AnyObject) {
		if Game.sharedGame().state == Game.State.Complete {
			self.positionCards(UIRectEdge.Left, animated: true, completion: {
				Game.sharedGame().state = Game.State.Ready
				Game.sharedGame().betMax()
				Game.sharedGame().deal()
			})
		}
		else {
			Game.sharedGame().betMax()
			Game.sharedGame().deal()
		}
	}

	@IBAction func handleDealDraw(sender: AnyObject) {
		switch Game.sharedGame().state {
			case Game.State.Ready:
				Game.sharedGame().deal()

			case Game.State.Dealt:
				var hideCount		= 0
				var dispatchTime	: Int64 = 0
				
				if let cardViews = self.cardViews {
					for cardView in cardViews {
						if let card = cardView.card {
							if !card.hold {
								hideCount++
								cardView.setRevealed(false, animated: true)
							}
						}
					}
				}
				
				if hideCount > 0 {
					dispatchTime = Int64((0.15 + CardView.RevealTime()) * Double(NSEC_PER_SEC))	// card flip + a little extra time to "think"
				}
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, dispatchTime), dispatch_get_main_queue(), { Game.sharedGame().draw(); return })

			case Game.State.Complete:
				break
		}
	}
}
