//
//  GameController.swift
//  Poker
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit
import Combine

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
	@IBOutlet weak var evBusy				: UIActivityIndicatorView!
	@IBOutlet var hCardCenterConstraint		: NSLayoutConstraint!
	var cardViews							: [CardView]?
	
	override var preferredStatusBarStyle	: UIStatusBarStyle { return UIStatusBarStyle.lightContent }

	private var betMonitor					: AnyCancellable?
	private var evMonitor					: AnyCancellable?
	private var stateMonitor				: AnyCancellable?
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.betMonitor = Game.shared.$actualBet.sink(receiveValue: self.handleBetChange)
		self.evMonitor = Game.shared.evPublisher.receive(on: DispatchQueue.main).sink(receiveValue: self.handleEVChange)
		self.stateMonitor = Game.shared.$state.sink(receiveValue: self.handleStateChange)
		
		self.resetViews()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.positionCards(position: UIRectEdge.left, animated: false, completion: nil)	// better place for this?
	}

	func handleBetChange(_ newBet: Int) {
		self.updateElements(gameState: Game.shared.state)
		self.paytableView.bet = newBet
	}
	
	func handleEVChange(_ state: EVCalculator.State) {
		var evText: String?
		
		switch state {
			case .ready:
				evText = "-"
				
			case .calculating:
				self.evBusy.startAnimating()
				self.evLabel.isHidden = true
				self.evLabel.text = ""
				
			case .complete(let ev):
				evText = String(format: "%0.3f", ev)
				
			case .cancelling:
				break
		}
		
		evText.map { result in
			self.evBusy.stopAnimating()
			self.evLabel.isHidden = false
			
			UIView.animate(withDuration: 0.2, animations: {
				self.evLabel.alpha = 0.0
			}, completion: { (didFinish) -> Void in
				if didFinish {
					self.evLabel.text = result
					UIView.animate(withDuration: 0.2) { self.evLabel.alpha = 1.0 }
				}
			})
		}
	}
	
	func handleStateChange(_ state: Game.State) {
		// transitions here, while updateElements can be called at any point
		if let cardViews = self.cardViews {
			switch state {
				case .ready:
					self.paytableView.category = .none
					for cardView in cardViews {
						cardView.card = nil
						cardView.revealed = false
					}
				case .dealt:
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
				case .complete(let result):
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
	
		self.updateElements(gameState: state)
	}
	
	func resetViews() {
		if self.cardViews == nil {
			let viewTag		= Consts.Views.CardViewTagStart
			let cardViews	= (viewTag..<viewTag + 5).compactMap({ self.view.viewWithTag($0) as? CardView })
			
			for cardView in cardViews {
				cardView.update()
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
		guard let cardViews	= self.cardViews else { return }
		
		for cardView in cardViews {
			cardView.setRevealed(value: false, animated: animated)
			cardView.resetPinned()
		}
	}
	
	func updateElements(gameState: Game.State) {
		switch gameState {
			case .ready:
				self.betMaxButton.isEnabled = true
				self.betOneButton.isEnabled = true
				self.dealDrawButton.isEnabled = Game.shared.bet > 0
				self.evContainer.isHidden = true
			case .dealt:
				self.betMaxButton.isEnabled = false
				self.betOneButton.isEnabled = false
				self.dealDrawButton.isEnabled = true
				self.evContainer.isHidden = false
			case .complete:
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
		if case .complete = Game.shared.state  {
			self.positionCards(position: UIRectEdge.left, animated: true, completion: {
				Game.shared.state = .ready
				Game.shared.incrementBet(amount: 1)
			})
		}
		else {
			Game.shared.incrementBet(amount: 1)
		}
	}

	@IBAction func handleBetMax(_ sender: AnyObject?) {
		if case .complete = Game.shared.state  {
			self.positionCards(position: UIRectEdge.left, animated: true, completion: {
				Game.shared.state = .ready
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
			case .ready:
				Game.shared.deal()

			case .dealt:
				var hideCount		= 0
				var dispatchTime	= TimeInterval(0.0)
				
				if let cardViews = self.cardViews {
					for cardView in cardViews {
						guard let card = cardView.card else { continue }
						
						if !card.hold {
							hideCount += 1
							cardView.setRevealed(value: false, animated: true)
						}
					}
				}
				
				if hideCount > 0 {
					dispatchTime = 0.15 + Consts.Views.RevealAnimationTime	// card flip + a little extra time to "think"
				}
				delay(dispatchTime) { Game.shared.draw() }

			case .complete:
				break
		}
	}
}
