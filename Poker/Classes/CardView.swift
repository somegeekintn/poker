//
//  CardView.swift
//  Poker
//
//  Created by Casey Fleser on 8/5/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit
import QuartzCore

class CardView: UIView {
	@IBOutlet var cardImage		: UIImageView!
	@IBOutlet var holdLabel		: UIView!
	var enabled					: Bool = false
	var card					: Card?
	var revealed				: Bool = false
	
	required init(coder aDecoder: NSCoder) {
		var tapRecognizer	: UITapGestureRecognizer
		
		super.init(coder: aDecoder)
		
		tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
		self.addGestureRecognizer(tapRecognizer)
	}
	
	func imageNameFor(card: Card) -> String {
		var imageName = "card_"
		
		imageName += card.rank.identifier + card.suit.identifier
		
		return imageName
	}
	
	func update() {
		if self.card != nil && self.revealed {
			let card = self.card!
			self.holdLabel.hidden = !card.hold
			self.cardImage.image = UIImage(named: self.imageNameFor(card))
		}
		else {
			self.holdLabel.hidden = true
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
				UIView.animateWithDuration(Consts.Views.PinAnimationTime, animations: {
					self.alpha = 0.40
				})
			}
		}
	}
	
	func resetPinned() {
		self.alpha = 1.00
	}
	
	func handleTap(recognizer: UIGestureRecognizer) {
		if self.enabled {
			if let card = self.card {
				card.hold = !card.hold
				self.update()
				
				NSNotificationCenter.defaultCenter().postNotificationName(Consts.Notifications.RefreshEV, object: card)
			}
		}
	}
	
	func beginReveal(clockwise: Bool = true) {
		var flipAnimation	= CABasicAnimation(keyPath: "transform")
		var endTransform	= CATransform3DIdentity
		var endAngle		= CGFloat(M_PI_2) * (clockwise ? 1.0 : -1.0)
		
		endTransform.m34 = -1.0 / 500.0
		endTransform = CATransform3DRotate(endTransform, endAngle, 0, 1, 0)
		flipAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
		flipAnimation.toValue = NSValue(CATransform3D: endTransform)
		flipAnimation.duration = Consts.Views.RevealAnimationTime / 2.0
		flipAnimation.setValue(NSNumber(bool: clockwise), forKey: "clockwise")
		flipAnimation.delegate = self
		self.cardImage.layer.transform = endTransform
		self.cardImage.layer.addAnimation(flipAnimation, forKey: "begin_reveal")
	}
	
	func finishReveal(clockwise: Bool = true) {
		var flipAnimation	= CABasicAnimation(keyPath: "transform")
		var startTransform	= CATransform3DIdentity
		var endTransform	= CATransform3DIdentity
		var startAngle		= CGFloat(M_PI_2) * (clockwise ? -1.0 : 1.0)
		
		self.update()
		startTransform.m34 = -1.0 / 500.0
		startTransform = CATransform3DRotate(startTransform, startAngle, 0, 1, 0)
		flipAnimation.fromValue = NSValue(CATransform3D: startTransform)
		flipAnimation.toValue = NSValue(CATransform3D: endTransform)
		flipAnimation.duration = Consts.Views.RevealAnimationTime / 2.0
		self.cardImage.layer.transform = endTransform
		self.cardImage.layer.addAnimation(flipAnimation, forKey: "end_reveal")
	}
	
    override func animationDidStop(animation: CAAnimation!, finished flag: Bool) {
		if let clockwise = animation.valueForKey("clockwise") as? NSNumber {
			self.finishReveal(clockwise: clockwise.boolValue)
		}
	}
}
