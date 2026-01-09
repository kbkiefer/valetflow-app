import SwiftUI

struct RoutesListView: View {
    @StateObject private var viewModel = RoutesListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.routes.isEmpty {
                    loadingView
                } else if viewModel.hasNoRoutes {
                    emptyStateView
                } else {
                    routesListView
                }
            }
            .navigationTitle("Routes")
            .searchable(text: $viewModel.searchText, prompt: "Search routes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $viewModel.filterOption) {
                            ForEach(RouteFilterOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: filterIcon)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add route action - placeholder for future implementation
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
                await viewModel.loadRoutes()
            }
        }
    }

    // MARK: - Filter Icon

    private var filterIcon: String {
        viewModel.filterOption == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading routes...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.adminAccent)

            Text("No Routes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first route to start organizing community pickups.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                // Add route action - placeholder for future implementation
            }) {
                Label("Add Route", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.Colors.adminPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Routes List View

    private var routesListView: some View {
        List {
            if viewModel.hasNoSearchResults {
                noSearchResultsView
            } else {
                ForEach(viewModel.filteredRoutes) { route in
                    RouteRowView(
                        route: route,
                        formattedSchedule: viewModel.formattedSchedule(for: route),
                        formattedDuration: viewModel.formattedDuration(for: route)
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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

            if viewModel.filterOption != .all {
                Text("No \(viewModel.filterOption.rawValue.lowercased()) routes match \"\(viewModel.searchText)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No routes match \"\(viewModel.searchText)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    RoutesListView()
}
