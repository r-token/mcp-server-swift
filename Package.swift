// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftMCPServer",
	platforms: [.macOS(.v26)],
	dependencies: [
		// MCP Swift SDK - the core library for implementing the Model Context Protocol
		.package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.2"),

		// Service Lifecycle for managing the server lifecycle
		.package(
			url: "https://github.com/swift-server/swift-service-lifecycle.git",
			from: "2.9.1"
		),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "SwiftMCPServer",
			dependencies: [
				.product(
					name: "ServiceLifecycle",
					package: "swift-service-lifecycle"
				),
				.product(name: "MCP", package: "swift-sdk"),
			]
		),
		.testTarget(
			name: "SwiftMCPServerTests",
			dependencies: [
				"SwiftMCPServer",
				.product(
					name: "ServiceLifecycle",
					package: "swift-service-lifecycle"
				),
				.product(name: "MCP", package: "swift-sdk"),
			],
			path: "Tests"
		),
	]
)
