//
//  ContentView.swift
//  plates
//
//  Created by alex on 4/14/26.
//

import SwiftUI
import MapKit

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Collection", systemImage: "licenseplate") {
                Text("Update from laptop")
            }
            Tab("Map", systemImage: "map") {
                Map()
            }
        }
    }
}

#Preview {
    ContentView()
}
