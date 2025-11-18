// HTTP.Freshness.Tests.swift
// swift-rfc-9111

import Testing
@testable import RFC_9111

@Suite("HTTP.Freshness Tests")
struct HTTPFreshnessTests {

    @Test("calculateFreshnessLifetime - max-age")
    func calculateFreshnessLifetimeMaxAge() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600")
            ]
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(response: response)

        #expect(lifetime == 3600)
    }

    @Test("calculateFreshnessLifetime - s-maxage for shared cache")
    func calculateFreshnessLifetimeSMaxage() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600, s-maxage=7200")
            ]
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(
            response: response,
            isSharedCache: true
        )

        #expect(lifetime == 7200) // s-maxage takes precedence for shared caches
    }

    @Test("calculateFreshnessLifetime - s-maxage ignored for private cache")
    func calculateFreshnessLifetimeSMaxagePrivate() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600, s-maxage=7200")
            ]
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(
            response: response,
            isSharedCache: false
        )

        #expect(lifetime == 3600) // s-maxage ignored for private caches
    }

    @Test("calculateFreshnessLifetime - Expires header")
    func calculateFreshnessLifetimeExpires() async throws {
        let date = Date()
        let expiresDate = date.addingTimeInterval(3600)

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(date).headerValue),
                try .init(name: "Expires", value: HTTP.Date(expiresDate).headerValue)
            ]
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(response: response)

        #expect(lifetime > 3550)
        #expect(lifetime < 3650)
    }

    @Test("calculateFreshnessLifetime - max-age overrides Expires")
    func calculateFreshnessLifetimeMaxAgeOverridesExpires() async throws {
        let date = Date()
        let expiresDate = date.addingTimeInterval(7200)

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600"),
                try .init(name: "Date", value: HTTP.Date(date).headerValue),
                try .init(name: "Expires", value: HTTP.Date(expiresDate).headerValue)
            ]
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(response: response)

        #expect(lifetime == 3600) // max-age takes precedence
    }

    @Test("calculateFreshnessLifetime - no freshness info")
    func calculateFreshnessLifetimeNoInfo() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: []
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(response: response)

        #expect(lifetime == 0)
    }

    @Test("calculateAge - with Age header")
    func calculateAgeWithAgeHeader() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Age", value: "120"),
                try .init(name: "Date", value: HTTP.Date(Date()).headerValue)
            ]
        )

        let age = HTTP.Freshness.calculateAge(response: response)

        #expect(age >= 120)
    }

    @Test("calculateAge - without Age header")
    func calculateAgeWithoutAgeHeader() async throws {
        let now = Date()
        let responseTime = now.addingTimeInterval(-300) // Received 5 minutes ago
        let pastDate = now.addingTimeInterval(-310) // Date header 10 seconds before response

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(pastDate).headerValue)
            ]
        )

        let age = HTTP.Freshness.calculateAge(
            response: response,
            now: now,
            responseTime: responseTime
        )

        #expect(age >= 290) // Close to 300 seconds
        #expect(age <= 320)
    }

    @Test("calculateAge - with request and response times")
    func calculateAgeWithTimes() async throws {
        let now = Date()
        let requestTime = now.addingTimeInterval(-10)
        let responseTime = now.addingTimeInterval(-5)
        let dateValue = now.addingTimeInterval(-7)

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(dateValue).headerValue)
            ]
        )

        let age = HTTP.Freshness.calculateAge(
            response: response,
            now: now,
            requestTime: requestTime,
            responseTime: responseTime
        )

        #expect(age > 0)
    }

    @Test("isFresh - fresh response")
    func isFreshTrue() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600"),
                try .init(name: "Date", value: HTTP.Date(Date()).headerValue)
            ]
        )

        #expect(HTTP.Freshness.isFresh(response: response))
    }

    @Test("isFresh - stale response")
    func isFreshFalse() async throws {
        let now = Date()
        let responseTime = now.addingTimeInterval(-7200) // Received 2 hours ago

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600"),
                try .init(name: "Date", value: HTTP.Date(responseTime).headerValue)
            ]
        )

        #expect(!HTTP.Freshness.isFresh(
            response: response,
            now: now,
            responseTime: responseTime
        ))
    }

    @Test("isFresh - with custom times")
    func isFreshCustomTimes() async throws {
        let responseTime = Date(timeIntervalSince1970: 1000000)
        let now = Date(timeIntervalSince1970: 1004000) // 4000 seconds later (exceeds max-age of 3600)

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600"),
                try .init(name: "Date", value: HTTP.Date(responseTime).headerValue)
            ]
        )

        #expect(!HTTP.Freshness.isFresh(
            response: response,
            now: now,
            responseTime: responseTime
        ))
    }

    @Test("staleDate - valid lifetime")
    func staleDateValid() async throws {
        let responseTime = Date()

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Cache-Control", value: "max-age=3600"),
                try .init(name: "Date", value: HTTP.Date(responseTime).headerValue)
            ]
        )

        let staleDate = HTTP.Freshness.staleDate(
            response: response,
            responseTime: responseTime
        )

        #expect(staleDate != nil)

        let expectedStaleDate = responseTime.addingTimeInterval(3600)
        let diff = abs(staleDate!.timeIntervalSince(expectedStaleDate))
        #expect(diff < 1.0)
    }

    @Test("staleDate - zero lifetime")
    func staleDateZeroLifetime() async throws {
        let responseTime = Date()

        let response = HTTP.Response(
            status: .ok,
            headers: []
        )

        let staleDate = HTTP.Freshness.staleDate(
            response: response,
            responseTime: responseTime
        )

        #expect(staleDate == nil)
    }

    @Test("calculateHeuristicFreshness - with Last-Modified")
    func calculateHeuristicFreshnessValid() async throws {
        let now = Date()
        let lastModified = now.addingTimeInterval(-864000) // 10 days ago

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(now).headerValue),
                try .init(name: "Last-Modified", value: HTTP.Date(lastModified).headerValue)
            ]
        )

        let heuristicFreshness = HTTP.Freshness.calculateHeuristicFreshness(response: response)

        // Should be 10% of 10 days = 1 day = 86400 seconds
        #expect(heuristicFreshness > 86300)
        #expect(heuristicFreshness <= 86400) // Capped at 24 hours
    }

    @Test("calculateHeuristicFreshness - without Last-Modified")
    func calculateHeuristicFreshnessNoLastModified() async throws {
        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(Date()).headerValue)
            ]
        )

        let heuristicFreshness = HTTP.Freshness.calculateHeuristicFreshness(response: response)

        #expect(heuristicFreshness == 0)
    }

    @Test("calculateHeuristicFreshness - capped at 24 hours")
    func calculateHeuristicFreshnessCapped() async throws {
        let now = Date()
        let lastModified = now.addingTimeInterval(-8640000) // 100 days ago

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(now).headerValue),
                try .init(name: "Last-Modified", value: HTTP.Date(lastModified).headerValue)
            ]
        )

        let heuristicFreshness = HTTP.Freshness.calculateHeuristicFreshness(response: response)

        // Should be capped at 24 hours = 86400 seconds
        #expect(heuristicFreshness == 86400)
    }

    @Test("Freshness with heuristics allowed")
    func freshnessWithHeuristics() async throws {
        let now = Date()
        let lastModified = now.addingTimeInterval(-864000) // 10 days ago

        let response = HTTP.Response(
            status: .ok,
            headers: [
                try .init(name: "Date", value: HTTP.Date(now).headerValue),
                try .init(name: "Last-Modified", value: HTTP.Date(lastModified).headerValue)
            ]
        )

        let lifetime = HTTP.Freshness.calculateFreshnessLifetime(
            response: response,
            allowHeuristics: true
        )

        #expect(lifetime > 0)
        #expect(lifetime <= 86400) // Heuristic capped at 24 hours
    }
}
