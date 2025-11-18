// HTTP.Cache.StorageEligibility.Tests.swift
// swift-rfc-9111

import Testing
import RFC_3986
@testable import RFC_9111

@Suite("HTTP.Cache.StorageEligibility Tests")
struct HTTPCacheStorageEligibilityTests {

    @Test("Eligible - GET request with max-age")
    func eligibleGETWithMaxAge() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: []
        )

        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [
                try RFC_9110.Header.Field(name: "Cache-Control", value: "max-age=3600")
            ],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response
        )

        #expect(result.isEligible)
    }

    @Test("Ineligible - no-store directive")
    func ineligibleNoStore() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: []
        )

        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [
                try RFC_9110.Header.Field(name: "Cache-Control", value: "no-store")
            ],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response
        )

        #expect(!result.isEligible)
    }

    @Test("Ineligible - private in shared cache")
    func ineligiblePrivateShared() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: []
        )

        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [
                try RFC_9110.Header.Field(name: "Cache-Control", value: "private, max-age=3600")
            ],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response,
            isSharedCache: true
        )

        #expect(!result.isEligible)
    }

    @Test("Eligible - private in private cache")
    func eligiblePrivatePrivate() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: []
        )

        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [
                try RFC_9110.Header.Field(name: "Cache-Control", value: "private, max-age=3600")
            ],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response,
            isSharedCache: false
        )

        #expect(result.isEligible)
    }

    @Test("Eligible - heuristically cacheable status")
    func eligibleHeuristicallyCacheable() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: []
        )

        // 200 OK is heuristically cacheable even without explicit directives
        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response
        )

        #expect(result.isEligible)
    }

    @Test("Ineligible - informational status")
    func ineligibleInformationalStatus() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: []
        )

        // 100 Continue is not final
        let response = RFC_9110.Response(
            status: RFC_9110.Status(100),
            headers: [],
            body: nil
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response
        )

        #expect(!result.isEligible)
    }

    @Test("Eligible - authorized request with public directive")
    func eligibleAuthorizedWithPublic() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: [
                try RFC_9110.Header.Field(name: "Authorization", value: "Bearer token")
            ]
        )

        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [
                try RFC_9110.Header.Field(name: "Cache-Control", value: "public, max-age=3600")
            ],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response,
            isSharedCache: true
        )

        #expect(result.isEligible)
    }

    @Test("Ineligible - authorized request without sharing permission")
    func ineligibleAuthorizedWithoutPermission() async throws {
        let request = try RFC_9110.Request(
            method: .get,
            scheme: RFC_3986.URI.Scheme("http"),
            host: RFC_3986.URI.Host("example.com"),
            path: RFC_3986.URI.Path("/"),
            headers: [
                try RFC_9110.Header.Field(name: "Authorization", value: "Bearer token")
            ]
        )

        let response = RFC_9110.Response(
            status: RFC_9110.Status(200),
            headers: [
                try RFC_9110.Header.Field(name: "Cache-Control", value: "max-age=3600")
            ],
            body: Data("test".utf8)
        )

        let result = RFC_9110.Cache.StorageEligibility.isStorable(
            request: request,
            response: response,
            isSharedCache: true
        )

        #expect(!result.isEligible)
    }
}
