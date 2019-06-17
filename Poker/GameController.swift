//
//  GameController.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit

class GameController: UIViewController {
	// MARK: - Variables

	@IBOutlet weak var paytableView			: PayTableView!
	@IBOutlet weak var betLabel				: UILabel!
	@IBOutlet weak var creditsLabel			: UILabel!
	@IBOutlet weak var winLabel				: UILabel!
	@IBOutlet weak var dealDrawButton		: UIButton!
	@IBOutlet weak var betMaxButton			: UIButton!
	@IBOutlet weak var betOneButton			: UIButton!
	@IBOutlet weak var cardContainer		: UIView!
	@IBOutlet weak var evContainer			: UIView!
	@IBOutlet weak var evLabel				: UILabel!
	@IBOutlet var hCardCenterConstraint		: NSLayoutConstraint!
	var cardViews							: [CardView]?
	
	override var preferredStatusBarStyle	: UIStatusBarStyle { return UIStatusBarStyle.lightContent }

	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Game.shared.betHandler = { (newBet: Int) -> () in
			self.updateElements(gameState: Game.shared.state)
			self.paytableView.bet = newBet
		}
		
		Game.shared.evHandler = { (newEV: Double?) -> () in
			var evLabel : String
			
			if let ev = newEV {
				evLabel = String(format: "%0.3f", ev)
			}
			else {
				evLabel = "..."
			}
			
			if (self.evLabel.text != evLabel) {
				UIView.animate(withDuration: 0.2, animations: {
					self.evLabel.alpha = 0.0
				}, completion: { (didFinish) -> Void in
					if didFinish {
						self.evLabel.text = evLabel
						UIView.animate(withDuration: 0.2) { self.evLabel.alpha = 1.0 }
					}
				})
			}
		}
		
		Game.shared.stateHandler = { (newState: Game.State) -> () in
			// transitions here, while updateElements can be called at any point
			if let cardViews = self.cardViews {
				switch newState {
					case .Ready:
						self.paytableView.category = .none
						for cardView in cardViews {
							cardView.card = nil
							cardView.revealed = false
						}
					case .Dealt:
						self.evLabel.text = "..."
						for cardView in cardViews {
							let card	= Game.shared.playerCardAt(cardIndex: cardView.tag - Consts.Views.CardViewTagStart)
							
							cardView.card = card
						}
						self.positionCards(position: [], animated: true, completion: {
							for cardView in cardViews {
								cardView.setRevealed(value: true, animated: true)
								cardView.enabled = true
							}
						})
					case .Complete:
						let result			= Game.shared.hand.evaluate()
						var revealCount		= 0
						var dispatchTime	= TimeInterval(0.0)
						
						for cardView in cardViews {
							cardView.enabled = false
							if !cardView.revealed {
								let card	= Game.shared.playerCardAt(cardIndex: cardView.tag - Consts.Views.CardViewTagStart)
							
								cardView.card = card
								cardView.setRevealed(value: true, animated: true)
								revealCount += 1
							}
							else {
								cardView.card?.hold = false
								cardView.update()
							}
						}
						if revealCount > 0 {
							// card flip + a slight pause to allow player a moment to recognize before we do
							dispatchTime = (0.25 + Consts.Views.RevealAnimationTime)
						}
						delay(dispatchTime) {
							self.paytableView.category = result
							for cardView in cardViews {
								cardView.animatePinned()
							}
						}
				}
			}
		
			self.updateElements(gameState: newState)
		}

		self.resetViews()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.positionCards(position: UIRectEdge.left, animated: false, completion: nil)	// better place for this?
	}

	func resetViews() {
		if self.cardViews == nil {
			var cardViews	= [CardView]()
			let viewTag		= Consts.Views.CardViewTagStart
			
			for cardTag in viewTag..<viewTag + 5 {
				if let cardView = self.view.viewWithTag(cardTag) as? CardView {
					cardViews.append(cardView)
					cardView.update()
				}
			}
			
			self.cardViews = cardViews
			self.updateElements(gameState: Game.shared.state)
		}
		
		self.betLabel.text = String(Game.shared.bet)
		self.creditsLabel.text = String(Game.shared.credits)
		self.winLabel.text = String(Game.shared.lastWin)
		self.evContainer.isHidden = true
	}
	
	func positionCards(position: UIRectEdge, animated: Bool = false, completion: (() -> ())?) {
		var offset			: CGFloat = 0.0
		
		if !position.isEmpty {
			offset = self.cardContainer.frame.width
			
			if position == UIRectEdge.left {
				offset *= -1.0
			}
		}

		self.hCardCenterConstraint.constant = offset
		if animated {
			UIView.animate(withDuration: 0.25, animations: {
				self.cardContainer.layoutIfNeeded()
			}, completion: { (finished: Bool) -> () in
				if !position.isEmpty {
					self.resetAllCards()
				}
				if let completion = completion {
					completion()
				}
			})
		}
		else {
			if !position.isEmpty {
				self.resetAllCards()
			}
			self.cardContainer.layoutIfNeeded()
		}
	}
	
	func resetAllCards(animated: Bool = false) {
		if let cardViews = self.cardViews {
			for cardView in cardViews {
				cardView.setRevealed(value: false, animated: animated)
				cardView.resetPinned()
			}
		}
	}
	
	func updateElements(gameState: Game.State) {
		switch gameState {
			case .Ready:
				self.betMaxButton.isEnabled = true
				self.betOneButton.isEnabled = true
				self.dealDrawButton.isEnabled = Game.shared.bet > 0
				self.evContainer.isHidden = true
			case .Dealt:
				self.betMaxButton.isEnabled = false
				self.betOneButton.isEnabled = false
				self.dealDrawButton.isEnabled = true
				self.evContainer.isHidden = false
			case .Complete:
				self.betMaxButton.isEnabled = true
				self.betOneButton.isEnabled = true
				self.dealDrawButton.isEnabled = false
		}
		self.betLabel.text = String(Game.shared.bet)
		self.creditsLabel.text = String(Game.shared.credits)
		self.winLabel.text = String(Game.shared.lastWin)
	}
	
	// MARK: - Handlers

	@IBAction func handleBetOne(_ sender: AnyObject) {
		if Game.shared.state == Game.State.Complete {
			self.positionCards(position: UIRectEdge.left, animated: true, completion: {
				Game.shared.state = Game.State.Ready
				Game.shared.incrementBet(amount: 1)
			})
		}
		else {
			Game.shared.incrementBet(amount: 1)
		}
	}

	@IBAction func handleBetMax(_ sender: AnyObject?) {
		if Game.shared.state == Game.State.Complete {
			self.positionCards(position: UIRectEdge.left, animated: true, completion: {
				Game.shared.state = Game.State.Ready
				Game.shared.betMax()
				Game.shared.deal()
			})
		}
		else {
			Game.shared.betMax()
			Game.shared.deal()
		}
	}

	@IBAction func handleDealDraw(_ sender: AnyObject) {
		switch Game.shared.state {
			case Game.State.Ready:
				Game.shared.deal()

			case Game.State.Dealt:
				var hideCount		= 0
				var dispatchTime	= TimeInterval(0.0)
				
				if let cardViews = self.cardViews {
					for cardView in cardViews {
						if let card = cardView.card {
							if !card.hold {
								hideCount += 1
								cardView.setRevealed(value: false, animated: true)
							}
						}
					}
				}
				
				if hideCount > 0 {
					dispatchTime = 0.15 + Consts.Views.RevealAnimationTime	// card flip + a little extra time to "think"
				}
				delay(dispatchTime) { Game.shared.draw() }

			case Game.State.Complete:
				break
		}
	}
}
