//
//  ContentView.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedSampleRecipes") private var didSeedSampleRecipes = false

    var body: some View {
        TabView {
            RandomizerView()
                .tabItem { Label("Random", systemImage: "die.face.5") }
            RecipeListView()
                .tabItem { Label("Recipes", systemImage: "list.bullet") }
            StatisticsView()
                .tabItem { Label("Statistics", systemImage: "chart.bar") }
        }
    }
}


