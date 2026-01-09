import SwiftUI

struct EmployeesListView: View {
    @StateObject private var viewModel = EmployeesListViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.employees.isEmpty {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    employeeListView
                }
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
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading employees...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Employees")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add employees to start managing your team")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Empty View

    private var searchEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No employees match \"\(viewModel.searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Employee List View

    private var employeeListView: some View {
        Group {
            if viewModel.isSearchEmpty {
                searchEmptyView
            } else {
                List {
                    ForEach(viewModel.filteredEmployees) { employee in
                        EmployeeRowView(employee: employee)
                    }
                    .onDelete(perform: deleteEmployees)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }

    // MARK: - Actions

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
