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
        HStack {
            VStack(alignment: .leading) {
                Text(plate.plateTitle)
                    .font(.body)
                Text("State: \(plate.state)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let url = URL(string: plate.sourceImg), !plate.sourceImg.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    //Image(systemName: "photo")
                }
                .frame(width: 60, height: 30)
            }
        }
    }
}
