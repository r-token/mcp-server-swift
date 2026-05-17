//
//  MCPServerFactory.swift
//  SwiftMCPServer
//
//  Created by Ryan Token on 2/14/26.
//

import Foundation
import Logging
import MCP
import ServiceLifecycle

/// Creates and configures the MCP server and configures the tools
class MCPServerFactory {
	/// This creates a new instance of a configured MCP server with Tools ready to go
	static func makeServer(with logger: Logger) async -> Server {
		let server = Server(
			name: "SwiftMCPServer",
			version: "1.0",
			capabilities: .init(
				logging: Server.Capabilities.Logging(),
				resources: .init(subscribe: true, listChanged: true),
				tools: .init(listChanged: true)
			)
		)

		await registerTools(on: server)

		// Setup the code to handle the tool logic when we receive a request for that tool
		await server.withMethodHandler(CallTool.self, handler: toolsHandler)

		return server
	}

	static func toolsHandler(params: CallTool.Parameters) async throws -> CallTool.Result {
		let unknownToolError = CallTool.Result(
			content: [.text(text: "Unknown tool", annotations: nil, _meta: nil)],
			isError: true
		)

		// Convert tool name to our enum
		guard let tool = RegisteredTools(rawValue: params.name) else {
			return unknownToolError
		}

		switch tool {
		case RegisteredTools.echo:
			let input = try EchoToolInput(arguments: params.arguments)
			let result = echoHandler(input.echoText)
			return .init(
				content: [.text(text: "You sent: \(result)", annotations: nil, _meta: nil)],
				isError: false
			)

		case RegisteredTools.selectRandom:
			let input = try PickRandomToolInput(arguments: params.arguments)
			let result = pickRandomNumberHandler(input.ints)
			return .init(
				content: [.text(text: "I picked: \(result)", annotations: nil, _meta: nil)],
				isError: false
			)
		case RegisteredTools.swiftVersion:
			_ = SwiftVersionToolInput()
			if let result = getSwiftVersion() {
				return .init(
					content: [
						.text(text: "Swift version: \(result)", annotations: nil, _meta: nil)
					],
					isError: false
				)
			} else {
				return .init(
					content: [
						.text(
							text: "Unable to retrieve Swift version",
							annotations: nil,
							_meta: nil
						)
					],
					isError: true
				)
			}
		}
	}


	private static func registerTools(on server: Server) async {
		/// Register a tool list handler
		await server.withMethodHandler(ListTools.self) { _ in

			// Define the tools you want the server to be able to access
			let tools: [Tool] = [
				Tool(
					name: RegisteredTools.echo.rawValue,
					description: "Echo back any text that was sent",
					inputSchema: EchoToolInput.inputSchema
				),
				Tool(
					name: RegisteredTools.selectRandom.rawValue,
					description:
						"Takes in a collection of numbers or strings and picks one at random",
					inputSchema: PickRandomToolInput.inputSchema
				),
				Tool(
					name: RegisteredTools.swiftVersion.rawValue,
					description: "Retrieves the current Swift version",
					inputSchema: SwiftVersionToolInput.inputSchema
				),
			]
			return .init(tools: tools)
		}
	}

	// Echo tool handler implementation
	private static func echoHandler(_ text: String) -> String {
		return text
	}

	// Random selector tool handler implementation
	private static func pickRandomNumberHandler(_ numbers: [Int]?) -> Int {
		guard let numbers = numbers else {
			return .zero
		}
		return numbers.randomElement() ?? .zero
	}

	// Swift version tool handler implementation
	private static func getSwiftVersion() -> String? {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
		process.arguments = ["swift", "--version"]

		let outputPipe = Pipe()
		process.standardOutput = outputPipe

		do {
			try process.run()
			process.waitUntilExit()

			let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
			return String(data: data, encoding: .utf8)
		} catch {
			return "Error running swift-version: \(error)"
		}
	}
}

struct EchoToolInput {
	var echoText: String

	init(arguments: [String: Value]?) throws {
		guard case let .string(text) = arguments?["echoText"] else {
			throw MCPError.invalidParams("Missing or invalid 'echoText' string parameter")
		}
		self.echoText = text
	}

	static let inputSchema: Value = [
		"type": "object",
		"properties": [
			"echoText": [
				"type": "string",
				"description": "The text to echo back",
			]
		],
		"required": ["echoText"],
	]
}

struct PickRandomToolInput {
	var ints: [Int]?

	init(arguments: [String: Value]?) throws {
		guard let raw = arguments?["ints"] else {
			self.ints = nil
			return
		}
		guard case let .array(items) = raw else {
			throw MCPError.invalidParams("'ints' must be an array of integers")
		}
		self.ints = items.compactMap { Int($0) }
	}

	static let inputSchema: Value = [
		"type": "object",
		"properties": [
			"ints": [
				"type": "array",
				"items": ["type": "integer"],
				"description": "A collection of integers to pick from at random",
			]
		],
	]
}

struct SwiftVersionToolInput {
	static let inputSchema: Value = [
		"type": "object",
		"properties": [:],
	]
}

enum RegisteredTools: String {
	case echo
	case selectRandom = "select_random"
	case swiftVersion = "swift_version"
}
