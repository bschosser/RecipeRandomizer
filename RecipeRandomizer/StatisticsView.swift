//
//  StatisticsView.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//
import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)])
    private var recipes: [Recipe]

    // Top/bottom 10
    private var mostCooked: [Recipe] {
        Array(recipes.sorted { $0.cookedCount > $1.cookedCount }.prefix(10))
    }
    private var leastCooked: [Recipe] {
        Array(recipes.sorted {
            if $0.cookedCount != $1.cookedCount { return $0.cookedCount < $1.cookedCount }
            return $0.createdAt < $1.createdAt
        }.prefix(10))
    }

    // Histogram data: total times cooked per cuisine (sum of cookedCount)
    private var cuisineBuckets: [CuisineBucket] {
        // Group by cuisine label (nil cuisines fall into "Uncategorized")
        let grouped = Dictionary(grouping: recipes) { (r: Recipe) in
            r.cuisine?.label ?? "Uncategorized"
        }
        // Sum cooked counts per cuisine
        let sums = grouped.map { (label, items) -> CuisineBucket in
            let total = items.reduce(0) { $0 + max(0, $1.cookedCount) }
            let recipeCount = items.count
            return CuisineBucket(id: label, cuisine: label, totalCooked: total, recipesCount: recipeCount)
        }
        // Show buckets with at least some activity first; stable sort by totalCooked desc, then name
        return sums
            .sorted { lhs, rhs in
                if lhs.totalCooked != rhs.totalCooked { return lhs.totalCooked > rhs.totalCooked }
                return lhs.cuisine < rhs.cuisine
            }
    }

    var body: some View {
        NavigationStack {
            List {
                // --- Histogram section ---
                Section("Cuisine histogram (times cooked)") {
                    if cuisineBuckets.reduce(0, { $0 + $1.totalCooked }) == 0 {
                        Text("No cooking history yet. Tap **Cooked** on recipes to build your stats.")
                            .foregroundStyle(.secondary)
                    } else {
                        CuisineHistogram(buckets: cuisineBuckets)
                            .frame(height: 240)
                            .padding(.vertical, 4)
                    }
                }

                // --- Top lists ---
                Section("Most cooked") {
                    if mostCooked.isEmpty {
                        Text("No data yet. Cook something!").foregroundStyle(.secondary)
                    } else {
                        ForEach(mostCooked) { r in
                            NavigationLink(value: r) {
                                StatCard(recipe: r)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                }

                Section("Least cooked") {
                    if leastCooked.isEmpty {
                        Text("No data yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(leastCooked) { r in
                            NavigationLink(value: r) {
                                StatCard(recipe: r)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .listRowBackground(Color.clear)
            .navigationTitle("Statistics")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(id: recipe.id)   // pass UUID, not the object itself
            }

        }
    }
}

// MARK: - Models & Views

private struct CuisineBucket: Identifiable {
    let id: String
    let cuisine: String
    let totalCooked: Int     // sum of cookedCount across recipes in that cuisine
    let recipesCount: Int    // how many recipes contributed (for context if you want)
}

private struct CuisineHistogram: View {
    let buckets: [CuisineBucket]

    var body: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("Cuisine", bucket.cuisine),
                y: .value("Times cooked", bucket.totalCooked)
            )
            .foregroundStyle(Color("Brand")) // use your brand color for bars
            .annotation(position: .top) {
                if bucket.totalCooked > 0 {
                    Text("\(bucket.totalCooked)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) { value in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick()
                AxisValueLabel {
                    if let s = value.as(String.self) {
                        Text(s)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }        .chartPlotStyle { plot in
            plot.background(Color("Brand").opacity(0.06)) // subtle filled background
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct StatCard: View {
    let recipe: Recipe
    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(data: recipe.imageData)
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name).font(.headline)
                HStack(spacing: 8) {
                    Label("\(recipe.cookedCount)", systemImage: "flame")
                    if let last = recipe.lastCooked {
                        Text("Last: \(last.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
//        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
