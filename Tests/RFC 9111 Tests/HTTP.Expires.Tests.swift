// HTTP.Expires.Tests.swift
// swift-rfc-9111

import Testing
@testable import RFC_9111

@Suite("HTTP.Expires Tests")
struct HTTPExpiresTests {

    @Test("Expires creation")
    func expiresCreation() async throws {
        let date = Date(timeIntervalSince1970: 1445412480)
        let expires = HTTP.Expires(date: date)

        #expect(expires.date == date)
    }

    @Test("Header value format")
    func headerValueFormat() async throws {
        let date = Date(timeIntervalSince1970: 784111777) // Sun, 06 Nov 1994 08:49:37 GMT
        let expires = HTTP.Expires(date: date)

        let headerValue = expires.headerValue

        #expect(headerValue.contains("Sun"))
        #expect(headerValue.contains("06 Nov 1994"))
        #expect(headerValue.contains("GMT"))
    }

    @Test("Parse valid expires")
    func parseValidExpires() async throws {
        let parsed = HTTP.Expires.parse("Sun, 06 Nov 1994 08:49:37 GMT")

        #expect(parsed != nil)

        let expectedDate = Date(timeIntervalSince1970: 784111777)
        let diff = abs(parsed!.date.timeIntervalSince(expectedDate))
        #expect(diff < 1.0) // Within 1 second
    }

    @Test("Parse invalid expires")
    func parseInvalidExpires() async throws {
        #expect(HTTP.Expires.parse("invalid") == nil)
        #expect(HTTP.Expires.parse("") == nil)
        #expect(HTTP.Expires.parse("2024-11-16") == nil) // Wrong format
    }

    @Test("isExpired - past date")
    func isExpiredPast() async throws {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let expires = HTTP.Expires(date: pastDate)

        #expect(expires.isExpired())
    }

    @Test("isExpired - future date")
    func isExpiredFuture() async throws {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let expires = HTTP.Expires(date: futureDate)

        #expect(!expires.isExpired())
    }

    @Test("isExpired - custom now")
    func isExpiredCustomNow() async throws {
        let expirationDate = Date(timeIntervalSince1970: 1000000)
        let expires = HTTP.Expires(date: expirationDate)

        let beforeExpiration = Date(timeIntervalSince1970: 999999)
        let afterExpiration = Date(timeIntervalSince1970: 1000001)

        #expect(!expires.isExpired(at: beforeExpiration))
        #expect(expires.isExpired(at: afterExpiration))
    }

    @Test("timeRemaining - positive")
    func timeRemainingPositive() async throws {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let expires = HTTP.Expires(date: futureDate)

        let remaining = expires.timeRemaining()

        #expect(remaining > 3500) // Approximately 3600, allowing for test execution time
        #expect(remaining < 3700)
    }

    @Test("timeRemaining - negative")
    func timeRemainingNegative() async throws {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let expires = HTTP.Expires(date: pastDate)

        let remaining = expires.timeRemaining()

        #expect(remaining < -3500) // Negative value
        #expect(remaining > -3700)
    }

    @Test("Equality")
    func equality() async throws {
        let date1 = Date(timeIntervalSince1970: 784111777)
        let date2 = Date(timeIntervalSince1970: 784111777)
        let date3 = Date(timeIntervalSince1970: 784111778)

        let expires1 = HTTP.Expires(date: date1)
        let expires2 = HTTP.Expires(date: date2)
        let expires3 = HTTP.Expires(date: date3)

        #expect(expires1 == expires2)
        #expect(expires1 != expires3)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.Expires> = []
        let date = Date(timeIntervalSince1970: 784111777)

        set.insert(HTTP.Expires(date: date))
        set.insert(HTTP.Expires(date: date)) // Duplicate
        set.insert(HTTP.Expires(date: Date(timeIntervalSince1970: 784111778)))

        #expect(set.count == 2)
    }

    @Test("Comparable")
    func comparable() async throws {
        let earlier = HTTP.Expires(date: Date(timeIntervalSince1970: 1000))
        let later = HTTP.Expires(date: Date(timeIntervalSince1970: 2000))

        #expect(earlier < later)
        #expect(later > earlier)
    }

    @Test("Codable")
    func codable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let date = Date(timeIntervalSince1970: 784111777)
        let expires = HTTP.Expires(date: date)

        let encoded = try encoder.encode(expires)
        let decoded = try decoder.decode(HTTP.Expires.self, from: encoded)

        let diff = abs(decoded.date.timeIntervalSince(expires.date))
        #expect(diff < 1.0) // Within 1 second
    }

    @Test("Description")
    func description() async throws {
        let date = Date(timeIntervalSince1970: 784111777)
        let expires = HTTP.Expires(date: date)

        let description = expires.description

        #expect(description.contains("Sun"))
        #expect(description.contains("GMT"))
    }

    @Test("LosslessStringConvertible")
    func losslessStringConvertible() async throws {
        let expires = HTTP.Expires("Sun, 06 Nov 1994 08:49:37 GMT")

        #expect(expires != nil)

        let expectedDate = Date(timeIntervalSince1970: 784111777)
        let diff = abs(expires!.date.timeIntervalSince(expectedDate))
        #expect(diff < 1.0)
    }

    @Test("Round trip - format and parse")
    func roundTrip() async throws {
        let original = Date(timeIntervalSince1970: 784111777)
        let expires = HTTP.Expires(date: original)

        let headerValue = expires.headerValue
        let parsed = HTTP.Expires.parse(headerValue)

        #expect(parsed != nil)
        let diff = abs(parsed!.date.timeIntervalSince(original))
        #expect(diff < 1.0) // Within 1 second
    }
}
