//
//  Trace.swift
//  Poker
//
//  Created by Casey Fleser on 6/18/19.
//  Copyright © 2019 Quiet Spark. All rights reserved.
//

import Foundation

struct Trace {
	static let traceFormatter	: DateFormatter = { let formatter = DateFormatter(); formatter.dateFormat = "hh:mm:ss.SSS"; return formatter }()
	static var activeKinds		= Kind.all
	static var activeSections	= Section.all
	static var traceHandler		: ((Trace) -> ())?

	struct Kind : OptionSet, CustomStringConvertible {
		let rawValue			: Int
		
		static let debug		= Kind(rawValue: 1 << 0)
		static let todo			= Kind(rawValue: 1 << 1)
		static let info			= Kind(rawValue: 1 << 2)
		static let success		= Kind(rawValue: 1 << 3)
		static let warning		= Kind(rawValue: 1 << 4)
		static let error		= Kind(rawValue: 1 << 5)
		static let mark			= Kind(rawValue: 1 << 6)
		static let shout		= Kind(rawValue: 1 << 7)
		
		static let all			: Kind = [.debug, .todo, .info, .success, .warning, .error, .mark, .shout]
		static let issues		: Kind = [.warning, .error]
		
		var description			: String {
			switch self.rawValue {
				case 1 << 0:	return "⚙"
				case 1 << 1:	return "📝"
				case 1 << 2:	return "📘"
				case 1 << 3:	return "📗"
				case 1 << 4:	return "📙"
				case 1 << 5:	return "📕"
				case 1 << 6:	return "✏️"
				case 1 << 7:	return "😱"
				default:		return "❓"
			}
		}
	}
	
	struct Section : OptionSet, CustomStringConvertible {
		let rawValue			: Int

		static let action		= Section(rawValue: 1 << 0)
		static let general		= Section(rawValue: 1 << 1)
		static let navigation	= Section(rawValue: 1 << 2)

		static let all			: Section = [.action, .general, .navigation]

		var description	: String {
			switch self.rawValue {
				case 1 << 0:	return "Action"
				case 1 << 1:	return "General"
				case 1 << 2:	return "Navigation"
				case 1 << 3:	return "Render"
				case 1 << 4:	return "Storage"
				default:		return "?"
			}
		}
	}
	
	let kind					: Trace.Kind
	let section					: Trace.Section
	let message					: String
	let filename				: String
	let line					: Int
	let timestamp				= Date()
	let tid						: Int

	var formattedTime			: String { return Trace.traceFormatter.string(from: self.timestamp) }
	var formattedOutput			: String { return "\(self.kind) [<\(String(format: "%08x", self.tid))> \(self.formattedTime) \(self.section)] - \(self.message) | \(self.filename) (\(self.line))" }

	init(section: Trace.Section, message: String, kind: Trace.Kind, filepath: String, line: Int) {
		self.section = section
		self.kind = kind
		self.message = message
		self.filename = URL(fileURLWithPath: filepath).lastPathComponent
		self.line = line
		self.tid = Thread.current.hash
	}

	static func output(_ section: Trace.Section, message: @autoclosure () -> String, kind: Trace.Kind = .info, filepath: String = #file, line: Int = #line) {
#if DEBUG
		if Trace.activeKinds.contains(kind) && Trace.activeSections.contains(section) {
			let trace		= Trace(section: section, message: message(), kind: kind, filepath: filepath, line: line)
			
			print(trace.formattedOutput)
			DispatchQueue.main.async { Trace.traceHandler?(trace) }
		}
#endif
	}

	static func debug(_ message: @autoclosure () -> String, filepath: String = #file, line: Int = #line) {
		Trace.output(Trace.Section.general, message: message(), kind: .debug, filepath: filepath, line: line)
	}

	static func error(_ message: @autoclosure () -> String, filepath: String = #file, line: Int = #line) {
		Trace.output(Trace.Section.general, message: message(), kind: .error, filepath: filepath, line: line)
	}

	static func todo(_ message: @autoclosure () -> String, filepath: String = #file, line: Int = #line) {
		Trace.output(Trace.Section.general, message: message(), kind: .todo, filepath: filepath, line: line)
	}

	static func shout(_ message: @autoclosure () -> String, filepath: String = #file, line: Int = #line) {
		Trace.output(Trace.Section.general, message: message().uppercased(), kind: .shout, filepath: filepath, line: line)
	}

	static func mark(filepath: String = #file, line: Int = #line, funcname: String = #function) {
		Trace.output(Trace.Section.general, message: funcname, kind: .mark, filepath: filepath, line: line)
	}
}
