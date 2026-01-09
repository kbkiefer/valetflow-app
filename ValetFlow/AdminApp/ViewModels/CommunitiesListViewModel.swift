import Foundation
import SwiftUI

@MainActor
class CommunitiesListViewModel: ObservableObject {
    @Published var communities: [Community] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let firebaseService = FirebaseService.shared

    var filteredCommunities: [Community] {
        if searchText.isEmpty {
            return communities
        }
        return communities.filter { community in
            community.name.localizedCaseInsensitiveContains(searchText) ||
            community.address.street.localizedCaseInsensitiveContains(searchText) ||
            community.address.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var hasNoCommunities: Bool {
        !isLoading && communities.isEmpty
    }

    var hasNoSearchResults: Bool {
        !isLoading && !communities.isEmpty && filteredCommunities.isEmpty
    }

    func loadCommunities() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedCommunities: [Community] = try await firebaseService.fetchAll(
                collection: Constants.Collections.communities
            )
            communities = fetchedCommunities.sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func deleteCommunity(_ community: Community) async {
        guard let communityId = community.id else {
            errorMessage = "Cannot delete community: missing ID"
            showError = true
            return
        }

        do {
            try await firebaseService.delete(
                collection: Constants.Collections.communities,
                documentId: communityId
            )
            communities.removeAll { $0.id == communityId }
        } catch {
            errorMessage = "Failed to delete community: \(error.localizedDescription)"
            showError = true
        }
    }

    func refresh() async {
        await loadCommunities()
    }
}
