// HTTP.Age.Tests.swift
// swift-rfc-9111

import Testing
@testable import RFC_9111

@Suite("HTTP.Age Tests")
struct HTTPAgeTests {

    @Test("Age creation with valid seconds")
    func ageCreation() async throws {
        let age = HTTP.Age(seconds: 120)

        #expect(age.seconds == 120)
    }

    @Test("Age creation with zero")
    func ageCreationZero() async throws {
        let age = HTTP.Age(seconds: 0)

        #expect(age.seconds == 0)
    }

    @Test("Header value format")
    func headerValueFormat() async throws {
        let age = HTTP.Age(seconds: 120)

        #expect(age.headerValue == "120")
    }

    @Test("Parse valid age")
    func parseValidAge() async throws {
        let parsed = HTTP.Age.parse("120")

        #expect(parsed != nil)
        #expect(parsed?.seconds == 120)
    }

    @Test("Parse age with whitespace")
    func parseWithWhitespace() async throws {
        let parsed = HTTP.Age.parse("  120  ")

        #expect(parsed != nil)
        #expect(parsed?.seconds == 120)
    }

    @Test("Parse invalid age")
    func parseInvalidAge() async throws {
        #expect(HTTP.Age.parse("invalid") == nil)
        #expect(HTTP.Age.parse("") == nil)
        #expect(HTTP.Age.parse("-5") == nil) // Negative ages invalid
        #expect(HTTP.Age.parse("120.5") == nil) // No decimals
    }

    @Test("Equality")
    func equality() async throws {
        let age1 = HTTP.Age(seconds: 120)
        let age2 = HTTP.Age(seconds: 120)
        let age3 = HTTP.Age(seconds: 121)

        #expect(age1 == age2)
        #expect(age1 != age3)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.Age> = []

        set.insert(HTTP.Age(seconds: 120))
        set.insert(HTTP.Age(seconds: 120)) // Duplicate
        set.insert(HTTP.Age(seconds: 121))

        #expect(set.count == 2)
    }

    @Test("Comparable")
    func comparable() async throws {
        let younger = HTTP.Age(seconds: 100)
        let older = HTTP.Age(seconds: 200)

        #expect(younger < older)
        #expect(older > younger)
    }

    @Test("Codable")
    func codable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let age = HTTP.Age(seconds: 120)
        let encoded = try encoder.encode(age)
        let decoded = try decoder.decode(HTTP.Age.self, from: encoded)

        #expect(decoded == age)
    }

    @Test("Description")
    func description() async throws {
        let age = HTTP.Age(seconds: 120)

        #expect(age.description == "120")
    }

    @Test("LosslessStringConvertible")
    func losslessStringConvertible() async throws {
        let age = HTTP.Age("120")

        #expect(age != nil)
        #expect(age?.seconds == 120)
        #expect(String(age!) == "120")
    }

    @Test("ExpressibleByIntegerLiteral")
    func expressibleByIntegerLiteral() async throws {
        let age: HTTP.Age = 120

        #expect(age.seconds == 120)
    }

    @Test("Round trip - format and parse")
    func roundTrip() async throws {
        let original = HTTP.Age(seconds: 120)
        let headerValue = original.headerValue
        let parsed = HTTP.Age.parse(headerValue)

        #expect(parsed != nil)
        #expect(parsed == original)
    }
}
