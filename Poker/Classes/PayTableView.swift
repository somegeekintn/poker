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
	var textAttributes	: [NSObject : AnyObject]?
	
	var bet : Int = 0 {
		didSet(oldBet) {
			self.setNeedsDisplay()
		}
	}
	
	var category : Hand.Category = Hand.Category.None {
		didSet(oldCategory) {
			self.setNeedsDisplay()
		}
	}

	func textAttributesForRowHeight(height: CGFloat) -> [NSObject : AnyObject] {
		if (self.textAttributes == nil) {
			var maxHeight	= height - 2.0
			var font		= UIFont(name: "Futura", size: maxHeight)
			
			while (font != nil && font!.lineHeight > maxHeight) {
				font = font!.fontWithSize(font!.pointSize - 1.0)
			}
			
			if let font = font {
				var textShadow	= NSShadow()
				
				textShadow.shadowOffset = CGSize(width: 1.0, height: 1.0)
				textShadow.shadowColor = UIColor.blackColor()
				self.textAttributes = [ NSFontAttributeName : font, NSForegroundColorAttributeName : self.borderColor, NSShadowAttributeName : textShadow ]
			}
		}
		
		return self.textAttributes!
	}
	
	override func drawRect(rect: CGRect) {
		var	categoryCount	= Hand.Category.WinningCategories.count
		var rowFrame		= self.bounds
		var payStyle		= NSParagraphStyle.defaultParagraphStyle().mutableCopy() as NSMutableParagraphStyle
		var payAttrs		: [NSObject : AnyObject]
		var textAttrs		: [NSObject : AnyObject]
		var payColumnWidth	: CGFloat
		var descFrame		: CGRect
		var payFrame		: CGRect
		var columnOutline	= UIBezierPath()
		
		rowFrame.size.height = floor(self.bounds.height / CGFloat(categoryCount))
		
		// ~1/3 of view reserved for description, other ~2/3 is 5 pay columns
		payColumnWidth = floor(self.bounds.width * 2.0 / 3.0 / 5.0)
		(descFrame, payFrame) = self.bounds.rectsByDividing(self.bounds.width - payColumnWidth * 5.0, fromEdge: CGRectEdge.MinXEdge)
		payFrame.size.width = payColumnWidth
		for var column=0; column<5; column++ {
			var columnFrame		= payFrame.rectByOffsetting(dx: payFrame.width * CGFloat(column), dy: 0.0)

			columnOutline.moveToPoint(CGPointMake(columnFrame.minX, columnFrame.minY))
			columnOutline.addLineToPoint(CGPointMake(columnFrame.minX, columnFrame.maxY))
		}
		
		if self.bet > 0 {
			var columnFrame		= payFrame.rectByOffsetting(dx: payFrame.width * CGFloat(self.bet - 1), dy: 0.0)
			
			UIColor(hue: 120.0 / 360.0, saturation: 1.00, brightness: 0.50, alpha: 0.75).set()
			UIRectFillUsingBlendMode(columnFrame, kCGBlendModeScreen)
		}
		if self.category != Hand.Category.None {
			var catFrame		= rowFrame.rectByOffsetting(dx: 0.0, dy: rowFrame.height * CGFloat(Hand.Category.NumCategories - (self.category.rawValue + 1)))
			
			UIColor(hue: 120.0 / 360.0, saturation: 1.00, brightness: 0.50, alpha: 0.75).set()
			UIRectFillUsingBlendMode(catFrame, kCGBlendModeScreen)
		}
		
		textAttrs = self.textAttributesForRowHeight(rowFrame.height)
		payAttrs = textAttrs
		payStyle.alignment = NSTextAlignment.Right
		payAttrs[NSParagraphStyleAttributeName] = payStyle
					
		for category in Hand.Category.WinningCategories {
			var catString	: NSString = category.description
			var textFrame	= descFrame.rectByIntersecting(rowFrame)
			var textSize	= catString.sizeWithAttributes(textAttrs)
			
			textAttrs[NSForegroundColorAttributeName] = category == self.category ? UIColor.whiteColor() : self.borderColor
			textFrame.inset(dx: 4.0, dy: (textFrame.height - textSize.height) / 2.0)
			catString.sizeWithAttributes(textAttrs)
			catString.drawInRect(textFrame, withAttributes: textAttrs)

			for var column=0; column<5; column++ {
				var columnFrame		= payFrame.rectByOffsetting(dx: payFrame.width * CGFloat(column), dy: 0.0)
				var payString		= String(category.payoutForBet(column + 1))

				payAttrs[NSForegroundColorAttributeName] = column + 1 == self.bet && category == self.category ? UIColor.whiteColor() : self.borderColor
				textFrame = columnFrame.rectByIntersecting(rowFrame)
				textFrame.inset(dx: 4.0, dy: (textFrame.height - textSize.height) / 2.0)
				textSize = payString.sizeWithAttributes(payAttrs)
				payString.drawInRect(textFrame, withAttributes: payAttrs)
			}
			
			rowFrame.offset(dx: 0.0, dy: rowFrame.height)
		}

		self.borderColor.set()
		UIRectFrame(self.bounds)
		columnOutline.stroke()
	}
}
