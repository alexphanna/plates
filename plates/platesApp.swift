//
//  platesApp.swift
//  plates
//
//  Created by alex on 4/14/26.
//

import SwiftUI

@main
struct platesApp: App {
    @StateObject private var store = PlateDataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
