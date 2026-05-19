//
//  SearchViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

@Observable
class SearchViewModel {
    let provider: SearchUseCaseProviderProtocol
    
    var searchResults: [SearchResult] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var query: String = ""
    
    init(provider: SearchUseCaseProviderProtocol) {
        self.provider = provider
    }
    
    @MainActor
    func search(query: String) async {
        isLoading = true
        errorMessage = nil
        do {
            searchResults = try await provider.searchPhotos().execute(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
