//
//  CardView.swift
//  Poker
//
//  Created by Casey Fleser on 8/5/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit
import QuartzCore

class CardView: UIView, CAAnimationDelegate {
	@IBOutlet var cardImage		: UIImageView!
	@IBOutlet var holdLabel		: UIView!
	var enabled					: Bool = false
	var card					: Card?
	var revealed				: Bool = false
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CardView.handleTap(_:))))
	}
	
	func imageNameForCard(_ card: Card) -> String {
		var imageName = "card_"
		
		imageName += card.rank.identifier + card.suit.identifier
		
		return imageName
	}
	
	func update() {
		if let card = self.card, self.revealed {
			self.holdLabel.isHidden = !card.hold
			self.cardImage.image = UIImage(named: self.imageNameForCard(card))
		}
		else {
			self.holdLabel.isHidden = true
			self.cardImage.image = UIImage(named: "card_back")
		}
	}
	
	func setRevealed(value: Bool, animated: Bool = false) {
		if value != self.revealed {
			self.revealed = value
			if animated {
				self.beginReveal(clockwise: self.revealed)
			}
			else {
				self.update()
			}
		}
	}
	
	func animatePinned() {
		if let card = self.card {
			if !card.pin {
				UIView.animate(withDuration: Consts.Views.PinAnimationTime) {
					self.alpha = 0.40
				}
			}
		}
	}
	
	func resetPinned() {
		self.alpha = 1.00
	}
	
	@objc func handleTap(_ recognizer: UIGestureRecognizer) {
		if self.enabled {
			if let card = self.card {
				card.hold = !card.hold
				self.update()
				
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: Consts.Notifications.RefreshEV), object: card)
			}
		}
	}
	
	func beginReveal(clockwise: Bool = true) {
		let flipAnimation	= CABasicAnimation(keyPath: "transform")
		var endTransform	= CATransform3DIdentity
		let endAngle		= CGFloat.pi / (clockwise ? -2.0 : 2.0)
		
		endTransform.m34 = -1.0 / 500.0
		endTransform = CATransform3DRotate(endTransform, endAngle, 0, 1, 0)
		flipAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
		flipAnimation.toValue = NSValue(caTransform3D: endTransform)
		flipAnimation.duration = Consts.Views.RevealAnimationTime / 2.0
		flipAnimation.setValue(NSNumber(value: clockwise), forKey: "clockwise")
		flipAnimation.delegate = self
		self.cardImage.layer.transform = endTransform
		self.cardImage.layer.add(flipAnimation, forKey: "begin_reveal")
	}
	
	func finishReveal(clockwise: Bool = true) {
		let flipAnimation	= CABasicAnimation(keyPath: "transform")
		var startTransform	= CATransform3DIdentity
		let endTransform	= CATransform3DIdentity
		let startAngle		= CGFloat.pi / (clockwise ? -2.0 : 2.0)
		
		self.update()
		startTransform.m34 = -1.0 / 500.0
		startTransform = CATransform3DRotate(startTransform, startAngle, 0, 1, 0)
		flipAnimation.fromValue = NSValue(caTransform3D: startTransform)
		flipAnimation.toValue = NSValue(caTransform3D: endTransform)
		flipAnimation.duration = Consts.Views.RevealAnimationTime / 2.0
		self.cardImage.layer.transform = endTransform
		self.cardImage.layer.add(flipAnimation, forKey: "end_reveal")
	}
	
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		guard let clockwise = anim.value(forKey: "clockwise") as? NSNumber else { return }
		
		self.finishReveal(clockwise: clockwise.boolValue)
	}
}
