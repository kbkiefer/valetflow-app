import SwiftUI

struct EmployeesListView: View {
    @StateObject private var viewModel = EmployeesListViewModel()
    @State private var contentState: ContentState = .loading

    private enum ContentState: Equatable {
        case loading
        case empty
        case searchEmpty
        case content
    }

    var body: some View {
        NavigationView {
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
            .navigationTitle("Employees")
            .searchable(text: $viewModel.searchText, prompt: "Search by name or position")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .task {
                await viewModel.loadEmployees()
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                updateContentState()
            }
            .onChange(of: viewModel.employees.count) { _, _ in
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
            searchEmptyView
                .transition(.opacity.combined(with: .move(edge: .top)))

        case .content:
            employeeListView
                .transition(.opacity)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    EmployeeRowSkeleton(index: index)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        AnimatedEmptyState(
            icon: "person.3.fill",
            title: "No Employees",
            message: "Add employees to start managing your team",
            accentColor: Constants.Colors.adminPrimary,
            buttonTitle: "Add Employee",
            buttonAction: {
                // Add employee action - placeholder for future implementation
            }
        )
    }

    // MARK: - Search Empty View

    private var searchEmptyView: some View {
        AnimatedSearchEmptyState(
            searchText: viewModel.searchText,
            accentColor: Constants.Colors.adminPrimary
        )
    }

    // MARK: - Employee List View

    private var employeeListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredEmployees.enumerated()), id: \.element.id) { index, employee in
                    NavigationLink {
                        EmployeeDetailView(displayItem: employee)
                    } label: {
                        EmployeeRowView(employee: employee, index: index)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteEmployee(employee)
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
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.filteredEmployees.count)
    }

    // MARK: - Actions

    private func updateContentState() {
        if viewModel.isLoading && viewModel.employees.isEmpty {
            contentState = .loading
        } else if viewModel.isEmpty {
            contentState = .empty
        } else if viewModel.isSearchEmpty {
            contentState = .searchEmpty
        } else {
            contentState = .content
        }
    }

    private func deleteEmployees(at offsets: IndexSet) {
        let employeesToDelete = offsets.map { viewModel.filteredEmployees[$0] }
        Task {
            for employee in employeesToDelete {
                await viewModel.deleteEmployee(employee)
            }
        }
    }
}

#Preview {
    EmployeesListView()
}
