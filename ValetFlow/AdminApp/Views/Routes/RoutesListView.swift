import SwiftUI

struct RoutesListView: View {
    @StateObject private var viewModel = RoutesListViewModel()
    @State private var contentState: ContentState = .loading
    @State private var showFilterSheet = false

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

                VStack(spacing: 0) {
                    // Filter chips section
                    if !viewModel.routes.isEmpty {
                        filterChipsView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    contentView
                }
            }
            .navigationTitle("Routes")
            .searchable(text: $viewModel.searchText, prompt: "Search routes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add route action - placeholder for future implementation
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
                await viewModel.loadRoutes()
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                updateContentState()
            }
            .onChange(of: viewModel.routes.count) { _, _ in
                updateContentState()
            }
            .onChange(of: viewModel.searchText) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    updateContentState()
                }
            }
            .onChange(of: viewModel.filterOption) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    updateContentState()
                }
            }
        }
    }

    // MARK: - Filter Chips View

    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RouteFilterOption.allCases, id: \.self) { option in
                    FilterChip(
                        title: option.rawValue,
                        isSelected: viewModel.filterOption == option
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.filterOption = option
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground).opacity(0.95))
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
            routesListView
                .transition(.opacity)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    RouteRowSkeleton(index: index)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        AnimatedEmptyState(
            icon: "map",
            title: "No Routes",
            message: "Create your first route to start organizing community pickups.",
            accentColor: Constants.Colors.fieldPrimary,
            buttonTitle: "Add Route",
            buttonAction: {
                // Add route action - placeholder for future implementation
            }
        )
    }

    // MARK: - Routes List View

    private var routesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredRoutes.enumerated()), id: \.element.id) { index, route in
                    RouteRowView(
                        route: route,
                        formattedSchedule: viewModel.formattedSchedule(for: route),
                        formattedDuration: viewModel.formattedDuration(for: route),
                        index: index
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteRoute(route)
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
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.filteredRoutes.count)
    }

    // MARK: - No Search Results View

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            AnimatedSearchEmptyState(
                searchText: viewModel.searchText,
                accentColor: Constants.Colors.fieldPrimary
            )

            if viewModel.filterOption != .all {
                Text("Showing \(viewModel.filterOption.rawValue.lowercased()) routes only")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }

    // MARK: - State Management

    private func updateContentState() {
        if viewModel.isLoading && viewModel.routes.isEmpty {
            contentState = .loading
        } else if viewModel.hasNoRoutes {
            contentState = .empty
        } else if viewModel.hasNoSearchResults {
            contentState = .searchEmpty
        } else {
            contentState = .content
        }
    }
}

// MARK: - Animated Filter Chip for Routes

private struct RouteFilterChip: View {
    let option: RouteFilterOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: filterIcon)
                        .font(.caption)
                        .transition(.scale.combined(with: .opacity))
                }

                Text(option.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Constants.Colors.adminPrimary : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var filterIcon: String {
        switch option {
        case .all: return "list.bullet"
        case .active: return "checkmark.circle.fill"
        case .inactive: return "pause.circle.fill"
        }
    }
}

#Preview {
    RoutesListView()
}
