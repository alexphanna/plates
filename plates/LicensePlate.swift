//
//  LicensePlate.swift
//  plates
//
//  Created by alex on 4/25/26.
//


import Foundation
import _LocationEssentials

// MARK: - Model
struct LicensePlate: Codable, Identifiable {
    var id: String { plateTitle + state }
    let state: String
    let plateTitle: String
    let sourceImg: String
    var spottings: [Spotting] = []

    enum CodingKeys: String, CodingKey {
        case state
        case plateTitle = "plate_title"
        case sourceImg = "source_img"
    }
}

struct Spotting: Hashable {
    let date: Date
    let location: CLLocation
}

extension Spotting: Codable {
    enum CodingKeys: String, CodingKey { case date, latitude, longitude }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        let lat = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        location = CLLocation(latitude: lat, longitude: lon)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(location.coordinate.latitude, forKey: .latitude)
        try container.encode(location.coordinate.longitude, forKey: .longitude)
    }
}

struct PlateNode: Codable, Identifiable {
    let name: String
    var plates: [LicensePlate]
    var children: [PlateNode]
    
    var id: String { name } // we assume names are unique enough for this tree
}

// MARK: - JSON Loading
enum TreeLoader {
    /// Loads the license plate tree from a JSON file in the main bundle.
    /// - Parameter fileName: JSON file name without extension (e.g., "plates").
    /// - Returns: Root PlateNode representing the entire tree.
    static func loadTree(from fileName: String) throws -> PlateNode {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw NSError(domain: "TreeLoader", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "File \(fileName).json not found in main bundle"])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let root = try decoder.decode(PlateNode.self, from: data)
        return root
    }
}

/*func start() {
    do {
        let root = try TreeLoader.loadTree(from: "plates")

        // Navigate: root -> "License Plates" -> "United States" -> states
        print("Root: \(root.name)")                         // "License Plates"
        if let usNode = root.children.first {               // Should be "United States"
            print("Country: \(usNode.name)")
            for stateNode in usNode.children {              // e.g., "AK", "AL", ...
                print("  State: \(stateNode.name) - \(stateNode.plates.count) plates")
            }
        }
    } catch {
        print("Error loading tree: \(error)")
    }
 }*/
