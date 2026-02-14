//
//  MCPTest.swift
//  SwiftMCPServer
//
//  Created by Ryan Token on 2/14/26.
//

import Logging
import MCP
import Testing

@testable import SwiftMCPServer

@Suite("MCP Tool Handler Tests")
struct MCPTest {

	@Test("Echo tool returns correct output")
	func echoTool() async throws {
		let echoToolParams = CallTool.Parameters(
			name: RegisteredTools.echo.rawValue,
			arguments: ["echoText": .string("Test Text To Echo")]
		)

		let echoResult = try await MCPServerFactory.toolsHandler(
			params: echoToolParams
		)

		// Extract text from the content array
		guard case .text(let textValue) = echoResult.content.first else {
			Issue.record("Expected text content")
			return
		}

		#expect(textValue == "You sent: Test Text To Echo")
		#expect(echoResult.isError == false)
	}

	@Test("Random selector tool picks from array")
	func randomSelectorTool() async throws {
		let testNumbers = [1, 2, 3, 4, 5]
		let randomToolParams = CallTool.Parameters(
			name: RegisteredTools.selectRandom.rawValue,
			arguments: ["ints": .array(testNumbers.map { .int($0) })]
		)

		let randomResult = try await MCPServerFactory.toolsHandler(
			params: randomToolParams
		)

		#expect(randomResult.isError == false)

		// Verify the result contains one of our test numbers
		guard case .text(let textValue) = randomResult.content.first else {
			Issue.record("Expected text content")
			return
		}

		#expect(textValue.hasPrefix("I picked: "))
	}

	@Test("Swift Version tool returns the current Swift version")
	func swiftVersionTool() async throws {
		let swiftToolParams = CallTool.Parameters(
			name: RegisteredTools.swiftVersion.rawValue,
			arguments: [:]
		)

		let swiftVersionResult = try await MCPServerFactory.toolsHandler(
			params: swiftToolParams
		)

		// Extract text from the content array
		guard case .text(let swiftVersion) = swiftVersionResult.content.first else {
			Issue.record("Could not retrieve Swift version")
			return
		}

		print(swiftVersion)

		#expect(!swiftVersion.isEmpty)
		#expect(swiftVersionResult.isError == false)
	}

	@Test("Unknown tool returns error")
	func unknownTool() async throws {
		let unknownToolParams = CallTool.Parameters(
			name: "unknownTool",
			arguments: [:]
		)

		let unknownResult = try await MCPServerFactory.toolsHandler(
			params: unknownToolParams
		)

		#expect(unknownResult.isError == true)
	}
}
