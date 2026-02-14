//
//  MCPService.swift
//  SwiftMCPServer
//
//  Created by Ryan Token on 2/14/26.
//

import MCP
import ServiceLifecycle
import Logging

struct MCPService: Service {
	let server: Server
	let transport: StdioTransport

	init(server: Server, transport: StdioTransport) {
		self.server = server
		self.transport = transport
	}

	func run() async throws {
		// Start the server
		try await server.start(transport: transport)

		// Keep running until external cancellation
		try await Task.sleep(for: .seconds(10000))
	}

	func shutdown() async throws {
		// Gracefully shutdown the server
		await server.stop()
	}
}
