//
//  PayTableView.swift
//  Poker
//
//  Created by Casey Fleser on 9/16/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import UIKit

class PayTableView : UIView {
	var borderColor		= UIColor(hue: 50.0 / 360.0, saturation: 0.85, brightness: 0.90, alpha: 1.0)
	
	var bet : Int = 0 {
		didSet(oldBet) {
			self.setNeedsDisplay()
		}
	}
	
	var category : Hand.Category = Hand.Category.none {
		didSet(oldCategory) {
			self.setNeedsDisplay()
		}
	}

	func textAttributesForRowHeight(_ height: CGFloat) -> [NSAttributedString.Key : AnyObject] {
		let maxHeight		= height - 2.0
		guard var font		= UIFont(name: "Futura", size: maxHeight) else { return [:] }
		var textAttributes	= [NSAttributedString.Key : AnyObject]()
		let textShadow		= NSShadow()

		while (font.lineHeight > maxHeight) {
			font = font.withSize(font.pointSize - 1.0)
		}
		
		textShadow.shadowOffset = CGSize(width: 1.0, height: 1.0)
		textShadow.shadowColor = UIColor.black
		textAttributes = [ .font : font, .foregroundColor : self.borderColor, .shadow : textShadow ]
		
		return textAttributes
	}

	override func draw(_ rect: CGRect) {
		let	categoryCount	= Hand.Category.WinningCategories.count
		var rowFrame		= self.bounds
		let payStyle		= NSMutableParagraphStyle.forDefaultStyle()
		var payAttrs		: [NSAttributedString.Key : AnyObject]
		var textAttrs		: [NSAttributedString.Key : AnyObject]
		var payColumnWidth	: CGFloat
		var descFrame		: CGRect
		var payFrame		: CGRect
		let columnOutline	= UIBezierPath()
		
		rowFrame.size.height = floor(self.bounds.height / CGFloat(categoryCount))
		
		// ~1/3 of view reserved for description, other ~2/3 is 5 pay columns
		payColumnWidth = floor(self.bounds.width * 2.0 / 3.0 / 5.0)
		(descFrame, payFrame) = self.bounds.divided(atDistance: self.bounds.width - payColumnWidth * 5.0, from: .minXEdge)
		payFrame.size.width = payColumnWidth
		for column in 0..<5 {
			let columnFrame		= payFrame.offsetBy(dx: payFrame.width * CGFloat(column), dy: 0.0)

			columnOutline.move(to: CGPoint(x: columnFrame.minX, y: columnFrame.minY))
			columnOutline.addLine(to: CGPoint(x: columnFrame.minX, y: columnFrame.maxY))
		}
		
		if self.bet > 0 {
			let columnFrame		= payFrame.offsetBy(dx: payFrame.width * CGFloat(self.bet - 1), dy: 0.0)
			
			UIColor(hue: 120.0 / 360.0, saturation: 1.00, brightness: 0.50, alpha: 0.75).set()
			UIRectFillUsingBlendMode(columnFrame, .screen)
		}
		if self.category != Hand.Category.none {
			let catFrame		= rowFrame.offsetBy(dx: 0.0, dy: rowFrame.height * CGFloat(Hand.Category.NumCategories - (self.category.rawValue + 1)))
			
			UIColor(hue: 120.0 / 360.0, saturation: 1.00, brightness: 0.50, alpha: 0.75).set()
			UIRectFillUsingBlendMode(catFrame, .screen)
		}
		
		textAttrs = self.textAttributesForRowHeight(rowFrame.height)
		payAttrs = textAttrs
		payStyle.alignment = .right
		payAttrs[.paragraphStyle] = payStyle
					
		for category in Hand.Category.WinningCategories {
			let catString	: NSString = category.description as NSString
			var textFrame	= descFrame.intersection(rowFrame)
			var textSize	= catString.size(withAttributes: textAttrs)
			
			textAttrs[.foregroundColor] = category == self.category ? UIColor.white : self.borderColor
			textFrame = textFrame.insetBy(dx: 4.0, dy: (textFrame.height - textSize.height) / 2.0)
			catString.size(withAttributes: textAttrs)
			catString.draw(in: textFrame, withAttributes: textAttrs)

			for column in 0..<5 {
				let columnFrame		= payFrame.offsetBy(dx: payFrame.width * CGFloat(column), dy: 0.0)
				let payString		= String(category.payoutForBet(column + 1))

				payAttrs[.foregroundColor] = column + 1 == self.bet && category == self.category ? UIColor.white : self.borderColor
				textFrame = columnFrame.intersection(rowFrame)
				textFrame = textFrame.insetBy(dx: 4.0, dy: (textFrame.height - textSize.height) / 2.0)
				textSize = payString.size(withAttributes: payAttrs)
				payString.draw(in: textFrame, withAttributes: payAttrs)
			}
			
			rowFrame = rowFrame.offsetBy(dx: 0.0, dy: rowFrame.height)
		}

		self.borderColor.set()
		UIRectFrame(self.bounds)
		columnOutline.stroke()
	}
}
