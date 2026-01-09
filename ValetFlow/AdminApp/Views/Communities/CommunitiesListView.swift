import SwiftUI

struct CommunitiesListView: View {
    @StateObject private var viewModel = CommunitiesListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.communities.isEmpty {
                    loadingView
                } else if viewModel.hasNoCommunities {
                    emptyStateView
                } else {
                    communitiesListView
                }
            }
            .navigationTitle("Communities")
            .searchable(text: $viewModel.searchText, prompt: "Search communities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add community action - placeholder for future implementation
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .task {
                await viewModel.loadCommunities()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading communities...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.adminAccent)

            Text("No Communities")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first community to get started with managing valet trash services.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                // Add community action - placeholder for future implementation
            }) {
                Label("Add Community", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.Colors.adminPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Communities List View

    private var communitiesListView: some View {
        List {
            if viewModel.hasNoSearchResults {
                noSearchResultsView
            } else {
                ForEach(viewModel.filteredCommunities) { community in
                    NavigationLink(destination: CommunityDetailView(community: community)) {
                        CommunityRowView(community: community)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteCommunity(community)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - No Search Results View

    private var noSearchResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Constants.Colors.adminAccent)

            Text("No Results")
                .font(.headline)

            Text("No communities match \"\(viewModel.searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    CommunitiesListView()
}
