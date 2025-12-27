//
//  RandomizerView.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//
import SwiftUI
import SwiftData
import Charts

struct RandomizerView: View {
    @Query(sort: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)])
    private var recipes: [Recipe]

    // Filters (nil = Any)
    @State private var selectedCuisine: Cuisine? = nil
    @State private var selectedPrep: PrepTime? = nil

    // Temperature: 0 = argmax (favorite), 2 = strong anti-favorite
    @State private var temperature: Double = 0.8

    // Last pick
    @State private var randomPick: Recipe? = nil
    
    @State private var showFullDistribution = false
    
    @State private var showWeightsInfo = false
    
    private var stepPoints: [WeightStepPoint] {
        // For each bin [start,end), add (start, p) and (end, p)
        var pts: [WeightStepPoint] = []
        for b in weightBins {
            pts.append(WeightStepPoint(x: b.start, y: b.prob))
            pts.append(WeightStepPoint(x: b.end,   y: b.prob))
        }
        return pts.sorted { $0.x < $1.x }
    }
    
    private var weightBins: [WeightBin] {
        // Sort recipes by cookedCount descending
        let items = filtered.sorted { $0.cookedCount > $1.cookedCount }
        let probs = weights(for: items, T: temperature) // your existing function

        // Create [start,end] bins: 0–1, 1–2, 2–3, ... so bars touch
        return probs.enumerated().map { i, p in
            WeightBin(start: Double(i), end: Double(i + 1), prob: p)
        }
    }
    
    private var smoothPoints: [SmoothPoint] {
        weightBins.map { b in
            SmoothPoint(x: (b.start + b.end) * 0.5, y: b.prob)
        }
    }

    var filtered: [Recipe] {
        recipes.filter { r in
            let cuisineOK = selectedCuisine == nil || r.cuisine == selectedCuisine
            let prepOK = selectedPrep == nil || r.prepTime == selectedPrep
            return cuisineOK && prepOK
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {                               // <- make it scroll
                VStack(spacing: 20) {
                    
                    // Filters
                    GroupBox("Filters") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Cuisine").frame(width: 90, alignment: .leading)
                                Picker("Cuisine", selection: $selectedCuisine) {
                                    Text("Any").tag(nil as Cuisine?)
                                    ForEach(Cuisine.allCases) { c in
                                        Text(c.label).tag(Optional(c))
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            HStack {
                                Text("Prep Time").frame(width: 90, alignment: .leading)
                                Picker("Prep", selection: $selectedPrep) {
                                    Text("Any").tag(nil as PrepTime?)
                                    ForEach(PrepTime.allCases) { p in
                                        Text(p.label).tag(Optional(p))
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .groupBoxStyle(FilledGroupBoxStyle())
                    
                    // Temperature
                    GroupBox("Temperature") {
                        VStack(alignment: .leading, spacing: 10) {
                            Slider(value: $temperature, in: 0...2, step: 0.01)
                            HStack {
                                Text("0").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("∞").font(.caption).foregroundStyle(.secondary)
                            }

                            
                            Button { showWeightsInfo = true } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $showWeightsInfo, arrowEdge: .top) {
                                InfoSheet()                                  // see below
                                    .presentationCompactAdaptation(.sheet)   // iPhone => sheet
                                    .presentationDetents([.medium, .large])  // allow bigger height
                                    .presentationDragIndicator(.visible)
                            }

                            
                            Button {
                                withAnimation(.snappy) { showFullDistribution.toggle() }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: showFullDistribution ? "chevron.up" : "chevron.down")
                                    Text(showFullDistribution ? "Hide distribution" : "Show distribution")
                                }
                                .font(.caption.bold())
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showFullDistribution
                                                ? "Hide selection weight distribution"
                                                : "Show selection weight distribution")
                            
                        }
                        ContinuousWeightsChart(
                            points: smoothPoints,
                            binCount: weightBins.count,
                            expanded: showFullDistribution,
                            lineColor: Color("Surprise")
                        )

                        
                        
                    }
                    .groupBoxStyle(FilledGroupBoxStyle())
                    
                    
                    
                    
                    Button {
                        randomPick = proposeRecipe(from: filtered,
                                                   temperature: temperature)
                    } label: {
                        Label("Surprise Me", systemImage: "sparkles")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Surprise").opacity(0.08))
                            .foregroundStyle(Color("Surprise"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(filtered.isEmpty)
                    
                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "No matches",
                            systemImage: "die.face.1",
                            description: Text("Try adding recipes or relaxing filters.")
                        )
                        .padding(.top, 20)
                    }
                    
                    if let pick = randomPick {
                        NavigationLink(value: pick) {
                            HStack(spacing: 12) {
                                RecipeThumbnail(data: pick.imageData)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pick.name).font(.headline)
                                    HStack(spacing: 8) {
                                        if let cuisine = pick.cuisine { Tag(cuisine.label) }
                                        if let prep = pick.prepTime { Tag(prep.label) }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(Color("Background"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Random Recipe")
                .navigationDestination(for: Recipe.self) { recipe in
                    RecipeDetailView(id: recipe.id)   // pass UUID, not the object itself
                }
                
                .background(Color("Background"))
            }
        }
    }

    // MARK: - Sampling Logic

    /// Temperature-to-exponent mapping:

    fileprivate func exponent(for T: Double) -> Double {
        if T <= 0 { return .infinity }                 // handled separately
        if T <= 1 { return 1.0 / max(T, 1e-6) }        // preference (peaky as T→0)

        // High-temperature regime: log scale to infinity as T→2
        if T >= 2 { return -.infinity }                // explicit “uncooked only” limit

        let u = tan((T - 1.0) * .pi / 2.0)             // 0…∞ as T→(1,2)
        let k = 2.5// smaller k = slower fall; larger k = faster
        return 1.0 - k*log1p(u)                          // 1 → -∞
    }


    fileprivate func weights(for items: [Recipe], T: Double) -> [Double] {
        guard !items.isEmpty else { return [] }

        // Greedy top at T=0 (unchanged)
        if T == 0 {
            let maxC = items.map(\.cookedCount).max() ?? 0
            let mask = items.map { $0.cookedCount == maxC ? 1.0 : 0.0 }
            let k = max(1.0, mask.reduce(0, +))
            return mask.map { $0 / k }
        }

        let exp = exponent(for: T)

        // ∞ temperature: only never-cooked get mass (uniform)
        if exp == -.infinity {
            let zeros = items.map { $0.cookedCount == 0 ? 1.0 : 0.0 }
            let k = max(1.0, zeros.reduce(0, +))
            return zeros.map { $0 / k }
        }

        // Regular case
        let base = items.map { Double(max(0, $0.cookedCount) + 1) } // ≥ 1
        let transformed = base.map { pow($0, exp) }
        let s = max(1e-12, transformed.reduce(0, +))
        return transformed.map { $0 / s }
    }

    
    fileprivate struct WeightStepPoint: Identifiable {
        let id = UUID()
        let x: Double   // bin edge
        let y: Double   // bin height (probability 0..1)
    }

    fileprivate struct WeightBin: Identifiable {
        let id = UUID()
        let start: Double   // left edge of the bin
        let end: Double     // right edge of the bin
        let prob: Double    // bar height (0..1)
    }
    
    fileprivate struct SmoothPoint: Identifiable {
        let id = UUID()
        let x: Double   // bin center (i + 0.5)
        let y: Double   // probability
    }




    /// Propose a recipe using: preference weights^(exp), multiplied by recency cool-down.
    private func proposeRecipe(from items: [Recipe],
                               temperature T: Double) -> Recipe? {
        guard !items.isEmpty else { return nil }

        // T = 0 => greedy (most cooked); if tie, random among top.
        if T == 0 {
            let maxCount = items.map { $0.cookedCount }.max() ?? 0
            let top = items.filter { $0.cookedCount == maxCount }
            return top.randomElement()
        }

        let exp = exponent(for: T)

        // Base score with Laplace smoothing (so zero-cooked still get some mass)
        let baseScores: [Double] = items.map { r in
            Double(max(0, r.cookedCount) + 1)
        }

        // Apply exponent: >0 = preference; <0 = anti-preference
        let transformed: [Double] = baseScores.map { score in
            if exp.isInfinite { return score } // unreachable when T != 0, but safe
            // Avoid pow(0, negative) — score is ≥ 1 anyway due to smoothing.
            return pow(score, exp)
        }

        // Apply recency cool-down
        let cooled: [Double] = items.enumerated().map { idx, r in
            transformed[idx]
        }

        if let pick = sample(items: items, weights: cooled) {
            return pick
        } else {
            // Fallback: uniform if all weights ~0
            return items.randomElement()
        }
    }

    /// Samples 1 item proportional to given (non-negative) weights.
    private func sample<T>(items: [T], weights: [Double]) -> T? {
        precondition(items.count == weights.count)
        let positive = weights.map { max(0.0, $0) }
        let total = positive.reduce(0, +)
        guard total > 0 else { return nil }
        var r = Double.random(in: 0..<total)
        for (i, w) in positive.enumerated() {
            r -= w
            if r < 0 { return items[i] }
        }
        return items.last
    }
}

private struct ContinuousWeightsChart: View {
    let points: [RandomizerView.SmoothPoint]
    let binCount: Int
    let expanded: Bool
    var lineColor: Color = .accentColor

    private let collapsedHeight: CGFloat = 0
    private let expandedHeight: CGFloat  = 220

    /// Lower bound: <= 0 with a small negative margin that scales with data.
    /// Upper bound: maxY + padding (optionally clamped to 1.05).
    private func yDomain(
        for pts: [RandomizerView.SmoothPoint],
        paddingFactor: Double = 0.08,
        clampUpperToOnePointOhFive: Bool = true
    ) -> ClosedRange<Double> {
        guard let minY = pts.map(\.y).min(),
              let maxY = pts.map(\.y).max()
        else { return -0.05...1.05 }

        // Data span and padding
        let span = max(maxY - minY, 1e-6)
        let pad  = max(span * paddingFactor, 1e-6)

        // Upper is data-driven + pad
        var upper = maxY + pad
        if clampUpperToOnePointOhFive {
            upper = min(1.05, upper)
        }

        // Lower should always include 0 and be slightly negative.
        // - If all data is ≥ 0, go to at least -pad.
        // - If data dips below 0, extend below minY by pad.
        let candidateLower = minY - pad
        let lower = min(candidateLower, -pad)   // ensures <= 0 with a small negative margin

        // Guard against a collapsed domain
        let adjustedUpper = max(upper, lower + 1e-3)

        return lower...adjustedUpper
    }

    var body: some View {
        let pts = points.sorted { $0.x < $1.x }

        let yDom = yDomain(for: pts)
        let domainToken: [Double] = [yDom.lowerBound, yDom.upperBound] // Equatable token

        Chart(pts) { p in
            LineMark(
                x: .value("Dish rank", p.x),
                y: .value("Weight",    p.y)
            )
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundStyle(lineColor)
        }
        .frame(height: expanded ? expandedHeight : collapsedHeight)
        .chartXScale(
            domain: (pts.first?.x ?? 0)...(pts.last?.x ?? Double(max(1, binCount)))
        )
        .chartYScale(domain: yDom)

        .chartXAxis(.hidden)
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text("← Favourites ←")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }

        .chartYAxis(expanded ? .automatic : .hidden)
        .chartYAxis {
            if expanded {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.25))
                    AxisTick().foregroundStyle(.secondary)
                    if let v = value.as(Double.self) {
                        AxisValueLabel {
                            Text(v, format: .percent.precision(.fractionLength(0)))
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 4)
                                .fixedSize()
                        }
                    }
                }
            }
        }

        .padding(.horizontal, 8)
        .chartPlotStyle { $0.background(.clear) }
        .mask(
            LinearGradient(
                stops: expanded
                    ? [.init(color: .black, location: 0),
                       .init(color: .black, location: 1)]
                    : [.init(color: .black, location: 0.0),
                       .init(color: .black, location: 0.85),
                       .init(color: .clear, location: 1.0)],
                startPoint: .top, endPoint: .bottom
            )
        )

        // Animate on expand/collapse and when domain changes
        .animation(.snappy, value: expanded)
        .animation(.snappy, value: domainToken)
    }
}




//
//        .padding(.horizontal, 8)
//        .padding(.vertical, 6)
//        .chartPlotStyle { $0.background(.clear) }
//
//
//        // keep the rest, but add a little padding so the axis/plot avoid rounded corners
//        .padding(.horizontal, 8)
//        .padding(.vertical, 6)
//        .chartPlotStyle { plot in
//            plot.background(.clear)
//        }
//        .chartPlotStyle { plot in
//            plot.background(.clear)
//        }
//        // Subtle fade when collapsed
//        .mask(
//            LinearGradient(
//                stops: expanded
//                    ? [.init(color: .black, location: 0), .init(color: .black, location: 1)]
//                    : [.init(color: .black, location: 0.0),
//                       .init(color: .black, location: 0.85),
//                       .init(color: .clear, location: 1.0)],
//                startPoint: .top, endPoint: .bottom
//            )
//        )
//        .animation(.snappy, value: expanded)
//    }
//}

private struct InfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {                         // <-- makes long text scroll
                VStack(alignment: .leading, spacing: 12) {
                    Text(.init("""
                    **How it works**

                    Dishes are sorted by how often you've cooked them *(left → favorites)*.  
                    The line shows the **probability** of proposing each rank.

                    - **T = 0**: pick favorite 
                    - **T small**: prefer favorites
                    - **T normal**: near-uniform
                    - **T large**: prefer least-cooked
                    - **T = ∞**: only never-cooked
                    """))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true) // prevent truncation
                }
                .padding()
            }
            .navigationTitle("Selection Weights")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

