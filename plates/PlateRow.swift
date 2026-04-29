//
//  PlateRow.swift
//  plates
//
//  Created by alex on 4/25/26.
//

import SwiftUI

// MARK: - Plate Row
struct PlateRow: View {
    let plate: LicensePlate

    var body: some View {
        NavigationLink(destination: PlateView(plateID: plate.id)) {
            HStack {
                Text(plate.plateTitle)
                Spacer()
                if let url = URL(string: plate.sourceImg), !plate.sourceImg.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                            .frame(width: 60, height: 30)
                    } placeholder: {
                        //Image(systemName: "photo")
                    }
                }
            }
        }
    }
}
