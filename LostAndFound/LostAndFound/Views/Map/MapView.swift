//
//  MapView.swift
//  LostAndFound
//
//  Created by Shashank Nayak on 6/5/2026.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var itemRepository: ItemRepository
    @StateObject private var locationManager = LocationManager()
    @State private var selectedItem: Item? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.8834, longitude: 151.2006),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
    )

    var mappableItems: [Item] {
        itemRepository.items.filter { $0.latitude != nil && $0.longitude != nil && $0.status == "active" }
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(mappableItems) { item in
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: item.latitude!,
                        longitude: item.longitude!
                    )) {
                        ItemPin(type: item.type, isSelected: selectedItem?.id == item.id)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.25)) {
                                    selectedItem = selectedItem?.id == item.id ? nil : item
                                }
                            }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: .top)

           
            VStack {
                HStack {
                    Spacer()
                    NearbyBadge(count: mappableItems.count)
                        .padding(.trailing, 14)
                        .padding(.top, 12)
                }
                Spacer()
            }

            
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    if let item = selectedItem {
                        MapItemPreviewCard(item: item) {
                            withAnimation { selectedItem = nil }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    MapLegend()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.requestPermission() }
        .onReceive(locationManager.$userLocation) { location in
            guard let coordinate = location?.coordinate else { return }
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                ))
            }
        }
    }
}



private struct ItemPin: View {
    let type: String
    let isSelected: Bool

    var color: Color { type == "lost" ? .red : .green }

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: isSelected ? 32 : 24))
            .foregroundStyle(.white, color)
            .shadow(color: color.opacity(0.4), radius: 4)
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(duration: 0.25), value: isSelected)
    }
}



private struct MapItemPreviewCard: View {
    let item: Item
    let onDismiss: () -> Void

    var typeColor: Color { item.type == "lost" ? .red : .green }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    Label(item.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    Text(item.type.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(typeColor.opacity(0.12))
                        .foregroundColor(typeColor)
                        .cornerRadius(6)
                }
            }
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}



private struct NearbyBadge: View {
    let count: Int

    var body: some View {
        Text("\(count) item\(count == 1 ? "" : "s") nearby")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
}


private struct MapLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("Lost").font(.caption2).foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Found").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.92))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.08), radius: 4)
    }
}

#Preview {
    NavigationStack {
        MapView()
    }
    .environmentObject(ItemRepository())
}
