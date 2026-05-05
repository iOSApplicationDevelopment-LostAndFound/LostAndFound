//
//  ItemDetailView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI

struct ItemDetailView: View {
    let item: Item

    var body: some View {
        Text(item.title)
            .navigationTitle("Item Detail")
    }
}
