//
//  CardView.swift
//  Poker
//
//  Created by Casey Fleser on 8/5/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit

class CardView: UIView {
	@IBOutlet var cardImage	: UIImageView!
	@IBOutlet var holdLabel	: UIView!
	var	enabled				: Bool = false
	
	var	card : Card? {
		didSet(value) {
			self.update(animated: false)
		}
	}

	var	revealed : Bool = false {
		didSet(value) {
			self.update(animated: false)
		}
	}

	required init(coder aDecoder: NSCoder!) {
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
	
	func update(animated: Bool = false) {
		if self.card != nil && self.revealed {
			let card = self.card!
			self.holdLabel.hidden = !card.hold
			self.cardImage.image = UIImage(named: self.imageNameFor(card))
		}
		else {
			self.holdLabel.hidden = true;
			self.cardImage.image = UIImage(named: "card_back")
		}
	}
	
	func handleTap(recognizer: UIGestureRecognizer) {
		if self.enabled {
			if let card = self.card {
				card.hold = !card.hold
				self.update(animated: false)
			}
		}
	}
}
