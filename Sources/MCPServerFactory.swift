//
//  MCPServerFactory.swift
//  SwiftMCPServer
//
//  Created by Ryan Token on 2/14/26.
//

import Foundation
import Logging
import MCP
import MCPHelpers
import ServiceLifecycle
import SwiftyJsonSchema

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
		let unknownToolError = CallTool.Result(content: [.text("Unknown tool")], isError: true)

		// Convert tool name to our enum
		guard let tool = RegisteredTools(rawValue: params.name) else {
			return unknownToolError
		}

		switch tool {
		case RegisteredTools.echo:
			let input = try EchoToolInput(with: params)
			let result = echoHandler(input.echoText)
			return .init(
				content: [.text("You sent: \(result)")],
				isError: false
			)

		case RegisteredTools.selectRandom:
			let input = try PickRandomToolInput(with: params)
			let result = pickRandomNumberHandler(input.ints)
			return .init(
				content: [.text("I picked: \(result)")],
				isError: false
			)
		case RegisteredTools.swiftVersion:
			_ = try SwiftVersionToolInput(with: params)
			if let result = getSwiftVersion() {
				return .init(
					content: [.text("Swift version: \(result)")],
					isError: false
				)
			} else {
				return .init(
					content: [.text("Unable to retrieve Swift version")],
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
					inputSchema: try .produced(from: EchoToolInput.self)
				),
				Tool(
					name: RegisteredTools.selectRandom.rawValue,
					description:
						"Takes in a collection of numbers or strings and picks one at random",
					inputSchema: try .produced(from: PickRandomToolInput.self)
				),
				Tool(
					name: RegisteredTools.swiftVersion.rawValue,
					description: "Retrieves the current Swift version",
					inputSchema: try .produced(from: SwiftVersionToolInput.self)
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

// Uses SwiftyJsonSchema to generate the JSON schema that informs the LLM of how to structure the tool call
struct EchoToolInput: ProducesJSONSchema, ParamInitializable {
	static let exampleValue = EchoToolInput(echoText: "Echo...")
	
	var echoText: String = ""
}

struct PickRandomToolInput: ProducesJSONSchema, ParamInitializable {
	static let exampleValue = PickRandomToolInput(ints: [5, 4, 6, 7, 123, 8411])

	var ints: [Int]? = nil
}

struct SwiftVersionToolInput: ProducesJSONSchema, ParamInitializable {
	static let exampleValue = SwiftVersionToolInput()
}

enum RegisteredTools: String {
	case echo
	case selectRandom
	case swiftVersion
}
