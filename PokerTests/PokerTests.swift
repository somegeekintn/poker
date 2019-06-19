//
//  PokerTests.swift
//  PokerTests
//
//  Created by Casey Fleser on 7/2/14.
//  Copyright (c) 2014 Quiet Spark. All rights reserved.
//

import XCTest

// Operators: ♣️, ♦️, ♥️, ♠️

class PokerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
	
    func testNoHand() {
		let case1 = CardSet(cards: [9♠️, 2♦️, 6♦️, 6♣️, T♠️])
    	let case2 = CardSet(cards: [4♠️, A♦️, 7♦️, K♣️, 8♠️])

		XCTAssertEqual(case1.eval().category, .none)
		XCTAssertEqual(case2.eval().category, .none)
    }
	
    func testJacksOrBetter() {
    	let case1 = CardSet(cards: [4♦️, K♦️, 5♥️, K♥️, J♠️])
    	let case2 = CardSet(cards: [2♦️, T♦️, 5♠️, J♥️, J♠️])
    	let case3 = CardSet(cards: [Q♦️, T♣️, T♥️, 5♣️, 2♥️])

		XCTAssertEqual(case1.eval().category, .jacksOrBetter, "Cards: \(case1)")
		XCTAssertEqual(case2.eval().category, .jacksOrBetter, "Cards: \(case2)")
		XCTAssertNotEqual(case3.eval().category, .jacksOrBetter, "Cards: \(case3)")
    }
	
    func testTwoPair() {
    	let case1 = CardSet(cards: [4♦️, K♦️, 4♥️, K♥️, J♠️])

		XCTAssertEqual(case1.eval().category, .twoPair, "Cards: \(case1)")
    }
	
    func testThreeOfAKind() {
    	let case1 = CardSet(cards: [4♦️, K♦️, 4♥️, Q♥️, 4♠️])

		XCTAssertEqual(case1.eval().category, .threeOfAKind, "Cards: \(case1)")
    }

    func testStraight() {
    	let case1 = CardSet(cards: [4♦️, 5♦️, 6♥️, 7♥️, 8♠️])

		XCTAssertEqual(case1.eval().category, .straight, "Cards: \(case1)")
    }

    func testFlush() {
    	let case1 = CardSet(cards: [4♦️, 5♦️, 9♦️, Q♦️, A♦️])

		XCTAssertEqual(case1.eval().category, .flush, "Cards: \(case1)")
    }

    func testFullHouse() {
    	let case1 = CardSet(cards: [4♦️, K♦️, 4♥️, K♥️, 4♠️])

		XCTAssertEqual(case1.eval().category, .fullHouse, "Cards: \(case1)")
    }

    func testFourOfAKind() {
    	let case1 = CardSet(cards: [4♦️, K♦️, 4♥️, 4♣️, 4♠️])

		XCTAssertEqual(case1.eval().category, .fourOfAKind, "Cards: \(case1)")
    }

    func testStraightFlush() {
    	let case1 = CardSet(cards: [4♦️, 5♦️, 6♦️, 7♦️, 8♦️])

		XCTAssertEqual(case1.eval().category, .straightFlush, "Cards: \(case1)")
    }

    func testRoyalFlush() {
    	let case1 = CardSet(cards: [T♦️, J♦️, Q♦️, K♦️, A♦️])

		XCTAssertEqual(case1.eval().category, .royalFlush, "Cards: \(case1)")
    }

    func testEVCalculatorSpeed() {
    	let deck		= Deck()
		let hand		= Hand()
		let calculator	= EVCalculator()
		
		deck.shuffle()
		hand.initialDrawFromDeck(deck)
		// Takes forever if we don't hold a card or two
		hand.cards[0].hold = true
		hand.cards[1].hold = true
		self.measure {
			calculator.beginEVCalculation(heldCards: hand.heldCards, inDeck: deck, withBet: 5)
		}
    }
}
