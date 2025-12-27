import SwiftUI
import SwiftData

// Wrapper view: loads a live Recipe from SwiftData by UUID, then shows a bindable body.
struct RecipeDetailView: View {
    let id: UUID

    // Query the single recipe by its UUID (live instance from the store)
    @Query private var result: [Recipe]

    init(id: UUID) {
        self.id = id
        _result = Query(filter: #Predicate<Recipe> { $0.id == id })
    }

    var body: some View {
        if let recipe = result.first {
            RecipeDetailBody(recipe: recipe)   // pass the live model
        } else {
            ContentUnavailableView("Recipe not found",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text("It may have been deleted."))
        }
    }
}

// Actual UI with a bindable model you can mutate safely on device.
private struct RecipeDetailBody: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var recipe: Recipe
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Cooked button + quick stats
                // Cooked + Undo (inline)
                // Cooked + Undo (inline)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                            // Large primary button – move frame/background/shape to the Button
                            Button(action: markCooked) {
                                Label("Tap to Cook", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)                 // <- on Button
                            .padding()                                  // <- on Button
                            .background(Color("Brand").opacity(0.15))   // <- on Button
                            .foregroundStyle(Color("Brand"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(Rectangle())                  // ensure full rect is hit-testable
                            // .buttonStyle(.plain) // not needed anymore; remove to keep default tap behavior

                            // Tiny undo button
                            Button(action: undoCooked) {
                                Image(systemName: "arrow.uturn.left.circle.fill")
                                    .font(.title3)
                                    .padding(12)
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(Color("Brand"))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Undo last cook")
                            .disabled(recipe.cookedCount == 0)
                            .opacity(recipe.cookedCount == 0 ? 0.5 : 1)
                        }
                    .zIndex(1)

                    // Quick stats
                    HStack(spacing: 12) {
                        Label("\(recipe.cookedCount) times", systemImage: "flame")
                        if let last = recipe.lastCooked {
                            Label(last.formatted(date: .abbreviated, time: .omitted),
                                  systemImage: "clock")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }


                if let data = recipe.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(16)
                        .allowsHitTesting(false)   // <- key: don’t intercept touches
                }

                HStack(spacing: 8) {
                    if let cuisine = recipe.cuisine { Tag(cuisine.label) }
                    if let prep = recipe.prepTime { Tag(prep.label) }
                }

                if let ingredients = recipe.ingredientsText, !ingredients.isEmpty {
                    SectionHeader("Ingredients")
                    Text(ingredients).font(.body.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.thinMaterial)
                        .cornerRadius(12)
                }

                if let instructions = recipe.instructions, !instructions.isEmpty {
                    SectionHeader("Instructions")
                    Text(instructions)
                }

                if let url = recipe.link {
                    SectionHeader("Link")
                    Link(destination: url) {
                        Label(url.absoluteString, systemImage: "link")
                    }
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
                Button(role: .destructive) { deleteRecipe() } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack { RecipeFormView(recipe: recipe) }
        }
    }

    @State private var saveError: String?

    @MainActor
    private func markCooked() {
        recipe.cookedCount += 1
        recipe.lastCooked = .now
        do {
            try context.save()
            // Optional haptics/animation
            // try? await Task.sleep(nanoseconds: 0) // allows UI update before next work
        } catch {
            saveError = "Save failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func undoCooked() {
        guard recipe.cookedCount > 0 else { return }
        recipe.cookedCount -= 1
        if recipe.cookedCount == 0 { recipe.lastCooked = nil }
        do {
            try context.save()
        } catch {
            saveError = "Undo save failed: \(error.localizedDescription)"
        }
    }


    private func deleteRecipe() {
        context.delete(recipe)
        try? context.save()
        dismiss()
    }
}

// If you don't already have this helper in this file, include it:
struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title).font(.headline) }
}
