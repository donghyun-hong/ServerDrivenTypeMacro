// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(init))
public macro ServerDrivenType() = #externalMacro(module: "ServerDrivenTypeMacros", type: "ServerDrivenTypeMacro")
