// HTTP.Vary.Tests.swift
// swift-rfc-9111

import Testing
@testable import RFC_9111

@Suite("HTTP.Vary Tests")
struct HTTPVaryTests {

    @Test("Vary creation with field names")
    func varyCreation() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding", "Accept-Language"])

        #expect(vary.fieldNames == ["accept-encoding", "accept-language"]) // Lowercased
        #expect(!vary.variesOnAllAspects)
    }

    @Test("Vary.all - varies on all aspects")
    func varyAll() async throws {
        let vary = HTTP.Vary.all

        #expect(vary.fieldNames.isEmpty)
        #expect(vary.variesOnAllAspects)
    }

    @Test("Header value - field names")
    func headerValueFieldNames() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding", "Accept-Language"])

        #expect(vary.headerValue == "accept-encoding, accept-language")
    }

    @Test("Header value - all aspects")
    func headerValueAll() async throws {
        let vary = HTTP.Vary.all

        #expect(vary.headerValue == "*")
    }

    @Test("Parse field names")
    func parseFieldNames() async throws {
        let parsed = HTTP.Vary.parse("Accept-Encoding, User-Agent")

        #expect(parsed != nil)
        #expect(parsed?.fieldNames == ["accept-encoding", "user-agent"])
        #expect(parsed?.variesOnAllAspects == false)
    }

    @Test("Parse all aspects")
    func parseAllAspects() async throws {
        let parsed = HTTP.Vary.parse("*")

        #expect(parsed != nil)
        #expect(parsed?.variesOnAllAspects == true)
    }

    @Test("Parse with whitespace")
    func parseWithWhitespace() async throws {
        let parsed = HTTP.Vary.parse("  Accept-Encoding ,  User-Agent  ")

        #expect(parsed != nil)
        #expect(parsed?.fieldNames == ["accept-encoding", "user-agent"])
    }

    @Test("Parse empty string")
    func parseEmpty() async throws {
        #expect(HTTP.Vary.parse("") == nil)
        #expect(HTTP.Vary.parse("  ") == nil)
    }

    @Test("includes - field name present")
    func includesPresent() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding", "User-Agent"])

        #expect(vary.includes("Accept-Encoding"))
        #expect(vary.includes("accept-encoding")) // Case-insensitive
        #expect(vary.includes("User-Agent"))
    }

    @Test("includes - field name absent")
    func includesAbsent() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding"])

        #expect(!vary.includes("Cookie"))
        #expect(!vary.includes("User-Agent"))
    }

    @Test("includes - all aspects")
    func includesAllAspects() async throws {
        let vary = HTTP.Vary.all

        #expect(vary.includes("Accept-Encoding"))
        #expect(vary.includes("Cookie"))
        #expect(vary.includes("anything"))
    }

    @Test("matches - same headers")
    func matchesSameHeaders() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding"])

        let result = vary.matches(
            requestHeaders: ["accept-encoding": "gzip"],
            cachedRequestHeaders: ["accept-encoding": "gzip"]
        )

        #expect(result == true)
    }

    @Test("matches - different headers")
    func matchesDifferentHeaders() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding"])

        let result = vary.matches(
            requestHeaders: ["accept-encoding": "br"],
            cachedRequestHeaders: ["accept-encoding": "gzip"]
        )

        #expect(result == false)
    }

    @Test("matches - all aspects never matches")
    func matchesAllAspects() async throws {
        let vary = HTTP.Vary.all

        let result = vary.matches(
            requestHeaders: ["accept-encoding": "gzip"],
            cachedRequestHeaders: ["accept-encoding": "gzip"]
        )

        #expect(result == false)
    }

    @Test("matches - multiple fields")
    func matchesMultipleFields() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding", "User-Agent"])

        let result1 = vary.matches(
            requestHeaders: ["accept-encoding": "gzip", "user-agent": "Mozilla"],
            cachedRequestHeaders: ["accept-encoding": "gzip", "user-agent": "Mozilla"]
        )
        #expect(result1 == true)

        let result2 = vary.matches(
            requestHeaders: ["accept-encoding": "gzip", "user-agent": "Chrome"],
            cachedRequestHeaders: ["accept-encoding": "gzip", "user-agent": "Mozilla"]
        )
        #expect(result2 == false)
    }

    @Test("Equality")
    func equality() async throws {
        let vary1 = HTTP.Vary(fieldNames: ["Accept-Encoding"])
        let vary2 = HTTP.Vary(fieldNames: ["Accept-Encoding"])
        let vary3 = HTTP.Vary(fieldNames: ["User-Agent"])
        let vary4 = HTTP.Vary.all

        #expect(vary1 == vary2)
        #expect(vary1 != vary3)
        #expect(vary1 != vary4)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.Vary> = []

        set.insert(HTTP.Vary(fieldNames: ["Accept-Encoding"]))
        set.insert(HTTP.Vary(fieldNames: ["Accept-Encoding"])) // Duplicate
        set.insert(HTTP.Vary(fieldNames: ["User-Agent"]))
        set.insert(HTTP.Vary.all)

        #expect(set.count == 3)
    }

    @Test("Codable")
    func codable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding", "User-Agent"])
        let encoded = try encoder.encode(vary)
        let decoded = try decoder.decode(HTTP.Vary.self, from: encoded)

        #expect(decoded == vary)
    }

    @Test("Description")
    func description() async throws {
        let vary = HTTP.Vary(fieldNames: ["Accept-Encoding"])

        #expect(vary.description == "accept-encoding")
    }

    @Test("LosslessStringConvertible")
    func losslessStringConvertible() async throws {
        let vary = HTTP.Vary("Accept-Encoding, User-Agent")

        #expect(vary != nil)
        #expect(vary?.fieldNames == ["accept-encoding", "user-agent"])
    }

    @Test("ExpressibleByArrayLiteral")
    func expressibleByArrayLiteral() async throws {
        let vary: HTTP.Vary = ["Accept-Encoding", "User-Agent"]

        #expect(vary.fieldNames == ["accept-encoding", "user-agent"])
    }

    @Test("Round trip - format and parse")
    func roundTrip() async throws {
        let original = HTTP.Vary(fieldNames: ["Accept-Encoding", "User-Agent"])
        let headerValue = original.headerValue
        let parsed = HTTP.Vary.parse(headerValue)

        #expect(parsed != nil)
        #expect(parsed == original)
    }
}
