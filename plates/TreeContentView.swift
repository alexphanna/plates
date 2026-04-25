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

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    Text("Error: \(errorMessage)").foregroundColor(.red)
                } else if let rootNode {
                    List {
                        NodeView(node: rootNode, isTopLevel: true)
                    }
                    .listStyle(.sidebar)
                } else {
                    ProgressView("Loading tree…")
                }
            }
            .navigationTitle("License Plates")
        }
        .task {
            do {
                rootNode = try TreeLoader.loadTree(from: "plates")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
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
        // Set initial expansion state: top-level starts open, others closed.
        _isExpanded = State(initialValue: isTopLevel)
    }

    var body: some View {
        if !self.isTopLevel {
            DisclosureGroup(isExpanded: $isExpanded) {
                if !node.plates.isEmpty {
                    ForEach(node.plates) { plate in
                        PlateRow(plate: plate)
                    }
                }
                else {
                    ForEach(node.children) { child in
                        NodeView(node: child)
                    }
                }
            } label: {
                Text(node.name)
                    //.font(isTopLevel ? .title2.bold() : .headline)
            }
        }
        else {
            ForEach(node.children) { child in
                NodeView(node: child)
            }
        }
    }
}
