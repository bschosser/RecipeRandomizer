//
//  Styles.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//
import SwiftUI

struct FilledGroupBoxStyle: GroupBoxStyle {
    var fill: Color = Color("Brand").opacity(0.08)
    var stroke: Color = Color("Brand").opacity(0.15)

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
                .font(.headline)
            configuration.content
        }
        .padding(12)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(stroke)
        )
    }
}
