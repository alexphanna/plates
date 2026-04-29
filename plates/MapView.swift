//
// MapView.swift
// plates
//
// Created by MapView
//

import SwiftUI
import MapKit
internal import Combine

// MARK: - Map View

/// A SwiftUI view that displays all license plate spottings on an interactive map.
struct MapView: View {
    
    // MARK: - Properties
    
    /// Access to the shared plate data store.
    @EnvironmentObject var store: PlateDataStore
    
    /// The region of the map that is currently visible.
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    /// Tracks whether the map is currently loading.
    @State private var isLoading = true
    
    /// A collection of all annotations to be displayed on the map.
    @State private var annotations: [PlateAnnotation] = []
    
    /// The currently selected annotation for the detail sheet.
    @State private var selectedAnnotation: PlateAnnotation?
    
    /// The error message to display if something goes wrong.
    @State private var errorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(annotations) { annotation in
                    // Use the string-based initializer: the first argument is a title (String)
                    // We pass the plate number as the title, but we'll hide it by not displaying it.
                    Annotation(annotation.title, coordinate: annotation.coordinate, anchor: .bottom) {
                        if let url = annotation.imageURL {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 30)
                            } placeholder: {
                                // placeholder
                            }
                            .offset(y: -15) // push image upward so the default pin title stays visible
                            .onTapGesture {
                                selectedAnnotation = annotation
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        zoomToFitAnnotations()
                    } label: {
                        Image(systemName: "location.viewfinder")
                    }
                    .disabled(annotations.isEmpty)
                }
            }
            .sheet(item: $selectedAnnotation) { annotation in
                // Detail view when a pin is tapped
                AnnotationDetailView(annotation: annotation)
                    .presentationDetents([.medium, .large])
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            buildAnnotationsFromSpottings()
        }
        .onReceive(store.objectWillChange) { _ in
            buildAnnotationsFromSpottings()
        }
    }
    
    // MARK: - Private Methods
    
    private func buildAnnotationsFromSpottings() {
        isLoading = true
        defer { isLoading = false }
        
        var newAnnotations: [PlateAnnotation] = []
        let allPlates = getAllPlates(from: store.root)
        
        for plate in allPlates where !plate.spottings.isEmpty {
            for spotting in plate.spottings {
                let annotation = PlateAnnotation(plate: plate, spotting: spotting)
                newAnnotations.append(annotation)
            }
        }
        
        annotations = newAnnotations
        
        if !annotations.isEmpty {
            DispatchQueue.main.async {
                zoomToFitAnnotations()
            }
        }
    }
    
    private func getAllPlates(from node: PlateNode) -> [LicensePlate] {
        var plates = node.plates
        for child in node.children {
            plates.append(contentsOf: getAllPlates(from: child))
        }
        return plates
    }
    
    private func zoomToFitAnnotations() {
        guard !annotations.isEmpty else { return }
        let coordinates = annotations.map { $0.coordinate }
        let region = fitRegion(for: coordinates, padding: 50)
        cameraPosition = .region(region)
    }
    
    private func fitRegion(for coordinates: [CLLocationCoordinate2D], padding: CGFloat) -> MKCoordinateRegion {
        var minLat = coordinates.first?.latitude ?? 0
        var maxLat = coordinates.first?.latitude ?? 0
        var minLon = coordinates.first?.longitude ?? 0
        var maxLon = coordinates.first?.longitude ?? 0
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Annotation Model

struct PlateAnnotation: Identifiable, Hashable {
    let id = UUID()
    let plate: LicensePlate
    let spotting: Spotting
    
    var coordinate: CLLocationCoordinate2D {
        spotting.location.coordinate
    }
    
    var spottingDate: Date {
        spotting.date
    }
    
    var title: String {
        plate.plateTitle
    }
    
    var subtitle: String {
        plate.state
    }
    
    var imageURL: URL? {
        guard !plate.sourceImg.isEmpty else { return nil }
        return URL(string: plate.sourceImg)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PlateAnnotation, rhs: PlateAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Detail View (shown when pin is tapped)

struct AnnotationDetailView: View {
    @Environment(\.dismiss) var dismiss
    let annotation: PlateAnnotation
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let url = annotation.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                            default:
                                ProgressView()
                            }
                        }
                    }
                }
                
                Section("Information") {
                    LabeledContent("Title", value: annotation.title)
                    LabeledContent("State", value: annotation.subtitle)
                }
                
                Section("Spotting Details") {
                    LabeledContent("Date", value: annotation.spottingDate.formatted())
                    LabeledContent("Location", value: "\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
                }
            }
            .navigationTitle("Spotting Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
