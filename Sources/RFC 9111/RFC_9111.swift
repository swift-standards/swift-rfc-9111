// RFC_9111.swift
// swift-rfc-9111
//
// RFC 9111: HTTP Caching
// https://www.rfc-editor.org/rfc/rfc9111.html
//
// HTTP cache mechanics including storage, retrieval, validation, and freshness


/// RFC 9111: HTTP Caching
///
/// This module implements HTTP caching mechanics as specified in RFC 9111,
/// which obsoletes RFC 7234. It defines how caches store, retrieve, and
/// validate HTTP responses to improve performance and reduce bandwidth.
///
/// ## Key Concepts
///
/// - **Freshness**: Responses have a freshness lifetime during which they can be served from cache
/// - **Validation**: Stale responses can be validated with conditional requests using ETags or Last-Modified
/// - **Cache Keys**: Composed of request method, target URI, and headers specified by Vary
///
/// ## Reference
///
/// - [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111.html)
public enum RFC_9111 {}

// Re-export RFC 9110 for convenience
@_exported import RFC_9110
