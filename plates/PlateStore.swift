//
//  PlateStore.swift
//  plates
//
//  Created by alex on 4/28/26.
//

import SwiftUI
internal import Combine

class PlateDataStore: ObservableObject {
    // The whole plate tree (loaded from JSON)
    @Published var root: PlateNode

    // @AppStorage stores the encoded spottings dictionary
    @AppStorage("plateSpottings") private var spottingsData: Data = Data()

    // In-memory dictionary parsed from spottingsData
    private var spottings: [String: [Spotting]] = [:]

    init() {
        // 1. Load tree from JSON (unchanged)
        self.root = try! TreeLoader.loadTree(from: "plates")
        // 2. Parse existing spottings from UserDefaults
        loadSpottingsFromStorage()
        // 3. Apply saved spottings to the tree
        applySpottingsToTree()
    }

    // MARK: - Spottings management

    func addSpotting(for plateID: String, spotting: Spotting) {
        spottings[plateID, default: []].append(spotting)
        saveSpottingsToStorage()
        applySpottingsToTree()
    }

    // Rebuild spottings dictionary from @AppStorage data
    private func loadSpottingsFromStorage() {
        guard !spottingsData.isEmpty else { return }
        spottings = (try? JSONDecoder().decode([String: [Spotting]].self, from: spottingsData)) ?? [:]
    }

    // Encode dictionary back to @AppStorage
    private func saveSpottingsToStorage() {
        if let data = try? JSONEncoder().encode(spottings) {
            spottingsData = data
        }
    }

    // Merge loaded spottings into the tree
    private func applySpottingsToTree() {
        apply(to: &root)
    }

    private func apply(to node: inout PlateNode) {
        for i in node.plates.indices {
            let id = node.plates[i].id
            if let saved = spottings[id] {
                node.plates[i].spottings = saved
            }
        }
        // Use indices to get mutable access to each child
        for i in node.children.indices {
            apply(to: &node.children[i])
        }
    }
    
    func findPlate(by id: String, in node: PlateNode) -> LicensePlate? {
            if let plate = node.plates.first(where: { $0.id == id }) {
                return plate
            }
            for child in node.children {
                if let found = findPlate(by: id, in: child) {
                    return found
                }
            }
            return nil
        }
}
