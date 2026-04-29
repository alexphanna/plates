//
//  CollectionView.swift
//  plates
//
//  Modified to fix live filtering and expand countries by default.
//

import SwiftUI

// MARK: - SwiftUI Tree View

struct TreeContentView: View {
    @EnvironmentObject var store: PlateDataStore
    @State private var rootNode: PlateNode?
    @State private var errorMessage: String?

    @State private var searchText = ""
    @State private var filterBy = ""

    // Stable filtered copy – updated only outside the body evaluation.
    @State private var filteredRoot: PlateNode?

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if let filteredRoot {
                    if filteredRoot.children.isEmpty && filteredRoot.plates.isEmpty {
                        // The tree is loaded but nothing matches the current filter.
                        ContentUnavailableView(
                            "No plates match this filter",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search or clear the filter.")
                        )
                    } else {
                        List {
                            NodeView(node: filteredRoot, isTopLevel: true)
                        }
                        .listStyle(.sidebar)
                        .searchable(text: $searchText, placement: .sidebar)
                    }
                } else {
                    ProgressView("Loading tree…")
                }
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Picker(selection: $filterBy) {
                                Section {
                                    Label("All", systemImage: "licenseplate").tag("")
                                }
                                Section {
                                    Label("Seen", systemImage: "eye").tag("Seen")
                                    Label("Not Seen", systemImage: "eye.slash").tag("Not Seen")
                                }
                            } label: {
                                Label(
                                    "Filter",
                                    systemImage: filterBy.isEmpty
                                        ? "line.3.horizontal.decrease.circle"
                                        : "line.3.horizontal.decrease.circle.fill"
                                )
                                Text(filterBy)
                            }
                            .pickerStyle(.menu)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            do {
                rootNode = try TreeLoader.loadTree(from: "plates")
                // Show the full tree immediately.
                applyFilter()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .onChange(of: searchText) { _ in applyFilter() }
        .onChange(of: filterBy)  { _ in applyFilter() }
    }

    // MARK: - Filtering

    /// Re‑computes `filteredRoot` whenever the search text or filter status changes.
    private func applyFilter() {
        guard let rootNode else {
            filteredRoot = nil
            return
        }

        // No filter active – show the original tree.
        if searchText.isEmpty && filterBy.isEmpty {
            filteredRoot = rootNode
        } else {
            filteredRoot = filter(
                node: rootNode,
                query: searchText.lowercased()
            )
        }
    }

    /// Recursively prune the tree, keeping only nodes that contain the query
    /// in their name or in any descendant plate‘s license string, and that
    /// satisfy the current `filterBy` status.
    private func filter(node: PlateNode, query: String) -> PlateNode? {
        // Name match: also true when the query is empty (so the root survives).
        let nameMatch = query.isEmpty || node.name.lowercased().contains(query)
        // Filter direct plates.
        let matchingPlates = node.plates.filter { plate in
            let matchesSearch = query.isEmpty || plate.plateTitle.lowercased().contains(query)
            let realPlate = store.findPlate(by: plate.id)!
            let matchesStatus: Bool = {
                switch filterBy {
                case "Seen":     return realPlate.spottings.count > 0
                case "Not Seen": return realPlate.spottings.count == 0
                default:         return true          // "All"
                }
            }()
            return matchesSearch && matchesStatus
        }

        // Recursively filter children.
        let matchingChildren = node.children.compactMap { filter(node: $0, query: query) }

        // Keep this node if it (or any descendant) has surviving content.
        if nameMatch || !matchingPlates.isEmpty || !matchingChildren.isEmpty {
            return PlateNode(
                name: node.name,
                plates: matchingPlates,
                children: matchingChildren
            )
        }
        return nil
    }
}

// MARK: - Recursive Node View

struct NodeView: View {
    let node: PlateNode
    let isTopLevel: Bool

    @State private var isExpanded: Bool

    init(node: PlateNode, isTopLevel: Bool = false) {
        self.node = node
        self.isTopLevel = isTopLevel
        // Countries (non‑top‑level nodes) start expanded.
        _isExpanded = State(initialValue: isTopLevel)
    }

    var body: some View {
        if !isTopLevel {
            DisclosureGroup(isExpanded: $isExpanded) {
                if !node.plates.isEmpty {
                    ForEach(node.plates) { plate in
                        PlateRow(plate: plate)
                    }
                } else {
                    ForEach(node.children) { child in
                        NodeView(node: child)
                    }
                }
            } label: {
                Text(node.name)
            }
        } else {
            ForEach(node.children) { child in
                NodeView(node: child)
            }
        }
    }
}
