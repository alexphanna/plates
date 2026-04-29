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
    @State var plate: LicensePlate
    let locationManager = CLLocationManager()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let url = URL(string: plate.sourceImg), !plate.sourceImg.isEmpty {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            //Image(systemName: "photo")
                        }
                    }
                    Text(plate.plateTitle)
                        .bold()
                }
                if (!plate.spottings.isEmpty) {
                    Section(header: Text("Spottings")) {
                        ForEach(plate.spottings, id: \.self) { spotting in
                            Text(spotting.date.description)
                        }
                    }
                }
            }
            .toolbar {
                Button {
                    plate.spottings.append(Spotting(location: locationManager.location!))
                } label: {
                    Image(systemName: "eye")
                }
            }
        }.onAppear(perform: fetch)
    }
    
    private func fetch() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
    }
}
