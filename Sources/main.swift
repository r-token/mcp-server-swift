//
//  main.swift
//  SwiftMCPServer
//
//  Created by Ryan Token on 2/14/26.
//

import Foundation
import Logging
import MCP
import ServiceLifecycle

final class App: Sendable {
	let log = {
		var logger = Logger(label: "com.ryantoken.swiftmcpserver")
		logger.logLevel = .debug
		return logger
	}()

	/// Create and start our MCP service, we make use of a ServiceGroup to handle launching and shutting down the server
	func start() async throws {
		log.info("MCP server has started")

		// Create the configured server with registered Tools and the MCP service
		let transport = StdioTransport(logger: log)
		let server = await MCPServerFactory.makeServer(with: log)
		let mcpService = MCPService(server: server, transport: transport)

		// Create service group with signal handling
		let serviceGroup = ServiceGroup(
			services: [mcpService],
			gracefulShutdownSignals: [.sigterm, .sigint],
			logger: log
		)

		// Run the service group - this blocks until shutdown
		try await serviceGroup.run()
	}
}

// Start the app
try! await App().start()
