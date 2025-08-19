//
//  SearchViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/10/25.
//

// SearchViewModel.swift
import Foundation
import Combine
import Moya

@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: - Input
    @Published var query: String = ""
    
    // MARK: - Output
    @Published var items: [CategoryItem] = []
    @Published var searchResults: [SearchResults] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let provider = MoyaProvider<SearchAPITarget>()
    
    /// 현재 in-flight Moya 요청 토큰
    private var currentRequest: Moya.Cancellable?
    
    init() {
        // Combine으로 디바운스 + 중복 제거
        $query
            .dropFirst()                                     // 초기 빈 문자열 무시
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()                              // 같은 텍스트 중복 요청 방지
            .sink { [weak self] text in
                self?.fetch(query: text)
            }
            .store(in: &cancellables)
    }
    
    private func fetch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 빈 검색어일 땐 이전 요청 취소하고 리셋
        guard !trimmed.isEmpty else {
            currentRequest?.cancel()
            items = []
            errorMessage = nil
            isLoading = false
            return
        }
        
        // 새 요청 전에 이전 요청이 있으면 취소
        currentRequest?.cancel()
        
        isLoading = true
        errorMessage = nil
        
        // 실제 요청 시작 → 반환된 Cancellable을 보관
        currentRequest = provider.request(.search(query: trimmed)) { [weak self] result in
            guard let self = self else { return }
            // Moya 콜백은 background 스레드이므로, UI 업데이트는 메인에서
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    do {
                        self.searchResults.removeAll()
                        let filtered = try response.filterSuccessfulStatusCodes()
                        let decoded = try JSONDecoder()
                            .decode(SearchResponseDto.self, from: filtered.data)
                        DispatchQueue.main.async {
                            self.searchResults.append(contentsOf: decoded.searchResults)
                        }
                    } catch {
                        self.errorMessage = "디코딩 오류: \(error)"
                    }
                    
                case .failure(let error):
                    self.errorMessage = "네트워크 오류: \(error)"
                }
            }
        }
    }
}
