//
//  PlatesView.swift
//  plates
//
//  Created by alex on 4/28/26.
//

import SwiftUI
import CoreLocation

// MARK: - Plate Row
struct PlateView: View {
    @EnvironmentObject var store: PlateDataStore
    let plateID: String          // ← changed from plate to ID
    let locationManager = CLLocationManager()

    // Get the up‑to‑date plate from the store
    private var plate: LicensePlate? {
        store.findPlate(by: plateID)
    }

    var body: some View {
        NavigationStack {
            List {
                if let plate {
                    if let url = URL(string: plate.sourceImg), !plate.sourceImg.isEmpty {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                Section {
                                    image.resizable().scaledToFit()
                                }
                            }
                        }
                    }
                    Section("Information") {
                        LabeledContent("Title", value: plate.plateTitle)
                        LabeledContent("State", value: plate.state)
                    }
                    if !plate.spottings.isEmpty {
                        Section(header: Text("Spottings")) {
                            ForEach(plate.spottings, id: \.self) { spotting in
                                Text(spotting.date.formatted())
                            }
                        }
                    }
                }
            }
            .toolbar {
                Button {
                    let newSpot = Spotting(date: Date(), location: locationManager.location!)
                    store.addSpotting(for: plateID, spotting: newSpot)
                } label: {
                    Image(systemName: "eye")
                }
            }
        }
        .onAppear(perform: fetch)
    }
    
    private func fetch() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
    }
}
