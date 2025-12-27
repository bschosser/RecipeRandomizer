//
//  RecipeFormView.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var recipe: Recipe? = nil // if non-nil -> editing

    @State private var name: String = ""
    @State private var imageData: Data? = nil
    @State private var ingredientsText: String = ""
    @State private var linkString: String = ""
    @State private var instructions: String = ""
    @State private var cuisine: Cuisine? = nil
    @State private var prepTime: PrepTime? = nil
    @State private var photoItem: PhotosPickerItem? = nil

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name *", text: $name)
            }

            Section("Photo") {
                HStack(spacing: 16) {
                    RecipeThumbnail(data: imageData)
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                    Button(role: .destructive) { imageData = nil } label: {
                        Label("Remove", systemImage: "trash")
                    }.disabled(imageData == nil)
                }
            }

            Section("Details") {
                Picker("Cuisine", selection: Binding(
                    get: { cuisine ?? .other },
                    set: { cuisine = $0 }
                )) {
                    Text("—").tag(Cuisine.other)
                    ForEach(Cuisine.allCases) { c in
                        Text(c.label).tag(c)
                    }
                }
                .pickerStyle(.menu)

                Picker("Prep Time", selection: Binding(
                    get: { prepTime ?? .under30 },
                    set: { prepTime = $0 }
                )) {
                    ForEach(PrepTime.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Ingredients") {
                TextEditor(text: $ingredientsText)
                    .frame(minHeight: 120)
                    .font(.body.monospaced())
                    .overlay(alignment: .topLeading) {
                        if ingredientsText.isEmpty {
                            Text("One per line…")
                                .foregroundStyle(.tertiary).padding(8)
                        }
                    }
            }

            Section("Link & Instructions") {
                TextField("Website link (optional)", text: $linkString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                TextEditor(text: $instructions)
                    .frame(minHeight: 140)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save)
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onChange(of: photoItem) { _, newItem in
            Task { imageData = try? await newItem?.loadTransferable(type: Data.self) }
        }
        .onAppear {
            if let r = recipe {
                name = r.name
                imageData = r.imageData
                ingredientsText = r.ingredientsText ?? ""
                linkString = r.link?.absoluteString ?? ""
                instructions = r.instructions ?? ""
                cuisine = r.cuisine
                prepTime = r.prepTime
            }
        }
    }
    

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let url: URL? = URL(string: linkString.trimmingCharacters(in: .whitespacesAndNewlines))

        if let recipe {
            recipe.name = trimmed
            recipe.imageData = imageData
            recipe.ingredientsText = ingredientsText.isEmpty ? nil : ingredientsText
            recipe.link = url
            recipe.instructions = instructions.isEmpty ? nil : instructions
            recipe.cuisine = cuisine
            recipe.prepTime = prepTime
        } else {
            let new = Recipe(
                name: trimmed,
                imageData: imageData,
                ingredientsText: ingredientsText.isEmpty ? nil : ingredientsText,
                link: url,
                instructions: instructions.isEmpty ? nil : instructions,
                cuisine: cuisine,
                prepTime: prepTime
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}
