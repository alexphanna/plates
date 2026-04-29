//
//  LicensePlate 2.swift
//  plates
//
//  Created by alex on 4/25/26.
//

import SwiftUI

// MARK: - SwiftUI Tree View
struct TreeContentView: View {
    @State private var rootNode: PlateNode?
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var filterBy = ""

    // Filtered version of the root node (nil while loading)
    var filteredRoot: PlateNode? {
        guard let rootNode else { return nil }
        if searchText.isEmpty { return rootNode }
        return filter(node: rootNode, query: searchText.lowercased())
    }

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    Text("Error: \(errorMessage)").foregroundColor(.red)
                } else if let filteredRoot {
                    List {
                        NodeView(node: filteredRoot, isTopLevel: true)
                    }
                    .listStyle(.sidebar)
                    .searchable(text: $searchText, placement: .sidebar)
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
                                Label("Filter", systemImage: filterBy == "" ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
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
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Recursively prune the tree, keeping only nodes that contain the query
    /// in their name or in any descendant plate's license string.
    private func filter(node: PlateNode, query: String) -> PlateNode? {
        // Check if this node's name matches
        let nameMatch = node.name.lowercased().contains(query)

        // Filter direct plates
        let matchingPlates = node.plates.filter {
            $0.plateTitle.lowercased().contains(query)       // adjust to your Plate property
            && (filterBy != "Seen" || $0.spottings.count > 0)
            && (filterBy != "Not Seen" || $0.spottings.count == 0)
        }

        // Recursively filter children
        let matchingChildren = node.children.compactMap {
            filter(node: $0, query: query)
        }

        // Keep this node if it matches, or if any plates/children match
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
