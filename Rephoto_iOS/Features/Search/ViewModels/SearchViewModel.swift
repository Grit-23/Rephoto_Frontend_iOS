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
    // Input
    @Published var query: String = ""
    // Output
    @Published var items: [CategoryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let provider = MoyaProvider<SearchAPITarget>()

    init() {
        // Combine으로 디바운스 처리
        $query
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.fetch(query: text)
            }
            .store(in: &cancellables)
    }

    private func fetch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // 빈 검색어일 땐 리셋
            items = []
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        // Moya 콜백 API 호출
        provider.request(.search(query: trimmed)) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    do {
                        let filtered = try response.filterSuccessfulStatusCodes()
                        let decoded = try JSONDecoder().decode([CategoryItem].self, from: filtered.data)
                        self.items = decoded
                    } catch {
                        self.errorMessage = "디코딩 오류: \(error.localizedDescription)"
                    }

                case .failure(let error):
                    self.errorMessage = "네트워크 오류: \(error.localizedDescription)"
                }
            }
        }
    }
}
