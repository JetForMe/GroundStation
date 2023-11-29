//
//  ContentView.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: GroundStationDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(GroundStationDocument()))
}
