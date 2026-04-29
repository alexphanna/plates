//
//  PlateStore.swift
//  plates
//
//  Created by alex on 4/28/26.
//

import SwiftUI
internal import Combine

class PlateDataStore: ObservableObject {
    @Published var root: PlateNode
    @AppStorage("plateSpottings") private var spottingsData: Data = Data()
    private var spottings: [String: [Spotting]] = [:]

    // FAST LOOKUP DICTIONARY
    private(set) var plateDictionary: [String: LicensePlate] = [:]

    init() {
        self.root = try! TreeLoader.loadTree(from: "plates")
        loadSpottingsFromStorage()
        applySpottingsToTree()
        rebuildDictionary()
    }

    // MARK: - Spottings management
    func addSpotting(for plateID: String, spotting: Spotting) {
        spottings[plateID, default: []].append(spotting)
        saveSpottingsToStorage()
        applySpottingsToTree()
        rebuildDictionary()
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

    // Rebuild the flat dictionary by walking the tree
    private func rebuildDictionary() {
        var dict: [String: LicensePlate] = [:]
        addToDictionary(&dict, node: root)
        plateDictionary = dict
    }

    private func addToDictionary(_ dict: inout [String: LicensePlate], node: PlateNode) {
        for plate in node.plates {
            dict[plate.id] = plate
        }
        for child in node.children {
            addToDictionary(&dict, node: child)
        }
    }

    // ... existing code for loadSpottings, saveSpottings, applySpottingsToTree ...
    // findPlate(by:in:) can now simply use the dictionary, or you can remove it entirely
    func findPlate(by id: String) -> LicensePlate? {
        plateDictionary[id]
    }
}
