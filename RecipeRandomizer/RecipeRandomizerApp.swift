//
//  RecipeRandomizerApp.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//

import SwiftUI
import SwiftData

@main
struct RecipeRandomizerApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color("Background").ignoresSafeArea()   // global background
                ContentView()
            }
            .tint(Color("Brand"))  // if you set a brand color earlier
        }
        .modelContainer(for: Recipe.self)
    }
}


