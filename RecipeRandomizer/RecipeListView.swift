//
//  RecipeListView.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//
import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)]) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var showAdd = false
    @State private var displayed: [Recipe] = []   // what the List actually shows

    // Base filtering (order doesn't matter here)
    private var filtered: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.ingredientsText ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private func reshuffle() {
        displayed = filtered.shuffled()
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes",
                        systemImage: "fork.knife",
                        description: Text("Add your first one with the + button.")
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Try a different search." : "Nothing for “\(searchText)”")
                    )
                } else {
                    List {
                        ForEach(displayed) { recipe in
                            NavigationLink(value: recipe) {
                                HStack(spacing: 12) {
                                    RecipeThumbnail(data: recipe.imageData)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.name).font(.headline)
                                        HStack(spacing: 8) {
                                            if let cuisine = recipe.cuisine { Tag(cuisine.label) }
                                            if let prep = recipe.prepTime { Tag(prep.label) }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .refreshable { reshuffle() } // optional: pull to re-randomize
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes or ingredients")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(id: recipe.id)
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack { RecipeFormView() }
            }
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
        }
        // Seed once when the view first appears
        .task { reshuffle() }

        // React to search text changes
        .onChange(of: searchText, initial: false) { _, _ in
            reshuffle()
        }

        // React to data changes (observe IDs => Equatable)
        .onChange(of: recipes.map(\.id), initial: true) { _, _ in
            reshuffle()
        }

    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(displayed[index])
        }
        try? context.save()
        displayed.remove(atOffsets: offsets)
        displayed.shuffle()
    }
}

struct Tag: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

struct RecipeThumbnail: View {
    let data: Data?
    var body: some View {
        Group {
            if let data, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Image(systemName: "photo")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
    }
}
