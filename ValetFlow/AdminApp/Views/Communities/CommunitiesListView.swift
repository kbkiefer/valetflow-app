import SwiftUI

struct CommunitiesListView: View {
    @StateObject private var viewModel = CommunitiesListViewModel()
    @State private var contentState: ContentState = .loading

    private enum ContentState: Equatable {
        case loading
        case empty
        case searchEmpty
        case content
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                contentView
            }
            .navigationTitle("Communities")
            .searchable(text: $viewModel.searchText, prompt: "Search communities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add community action - placeholder for future implementation
                    }) {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
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
            .onChange(of: viewModel.isLoading) { _, isLoading in
                updateContentState()
            }
            .onChange(of: viewModel.communities.count) { _, _ in
                updateContentState()
            }
            .onChange(of: viewModel.searchText) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    updateContentState()
                }
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch contentState {
        case .loading:
            loadingView
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

        case .empty:
            emptyStateView
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity
                ))

        case .searchEmpty:
            noSearchResultsView
                .transition(.opacity.combined(with: .move(edge: .top)))

        case .content:
            communitiesListView
                .transition(.opacity)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    CommunityRowSkeleton(index: index)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        AnimatedEmptyState(
            icon: "building.2",
            title: "No Communities",
            message: "Add your first community to get started with managing valet trash services.",
            accentColor: Constants.Colors.communityPrimary,
            buttonTitle: "Add Community",
            buttonAction: {
                // Add community action - placeholder for future implementation
            }
        )
    }

    // MARK: - Communities List View

    private var communitiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredCommunities.enumerated()), id: \.element.id) { index, community in
                    NavigationLink(destination: CommunityDetailView(community: community)) {
                        CommunityRowView(community: community, index: index)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
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
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.filteredCommunities.count)
    }

    // MARK: - No Search Results View

    private var noSearchResultsView: some View {
        AnimatedSearchEmptyState(
            searchText: viewModel.searchText,
            accentColor: Constants.Colors.communityPrimary
        )
    }

    // MARK: - State Management

    private func updateContentState() {
        if viewModel.isLoading && viewModel.communities.isEmpty {
            contentState = .loading
        } else if viewModel.hasNoCommunities {
            contentState = .empty
        } else if viewModel.hasNoSearchResults {
            contentState = .searchEmpty
        } else {
            contentState = .content
        }
    }
}

#Preview {
    CommunitiesListView()
}
