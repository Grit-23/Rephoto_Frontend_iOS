//
//  StubURLProtocolSuites.swift
//  AlbumDomainTests
//
//  Created by Doyeon Kim on 11/9/26.
//

import Testing

/// StubURLProtocol의 전역 상태(handler/recordedRequests)를 공유하는 스위트들의 컨테이너.
///
/// Swift Testing은 스위트 간에도 병렬 실행하므로, 스텁 상태를 공유하는 스위트는
/// 이 컨테이너의 extension으로 선언해 전체를 직렬 실행시킨다 (.serialized는 자식에 재귀 적용).
@Suite(.serialized)
enum StubURLProtocolSuites {}
