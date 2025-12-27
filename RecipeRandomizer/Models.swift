//
//  Models.swift
//  RecipeRandomizer
//
//  Created by Benedikt Schosser on 01.11.25.
//
import Foundation
import SwiftData

enum Cuisine: String, CaseIterable, Identifiable, Codable, Sendable {
    case italian, german, french, american, mexican, indian, chinese, japanese, korean, thai, middleEastern, dessert, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .german: return "German"
        case .italian: return "Italian"
        case .french: return "French"
        case .american: return "American"
        case .mexican: return "Mexican"
        case .indian: return "Indian"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .thai: return "Thai"
        case .middleEastern: return "Middle Eastern"
        case .dessert: return "Dessert"
        case .other: return "Other"
        }
    }
}

enum PrepTime: String, CaseIterable, Identifiable, Codable, Sendable {
    case under15, under30, under60, long
    var id: String { rawValue }
    var label: String {
        switch self {
        case .under15: return "≤ 15 min"
        case .under30: return "≤ 30 min"
        case .under60: return "≤ 60 min"
        case .long:     return "> 60 min"
        }
    }
}

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageData: Data?
    var ingredientsText: String?
    var link: URL?
    var instructions: String?
    var cuisine: Cuisine?
    var prepTime: PrepTime?
    var createdAt: Date

    var cookedCount: Int
    var lastCooked: Date?

    init(name: String,
         imageData: Data? = nil,
         ingredientsText: String? = nil,
         link: URL? = nil,
         instructions: String? = nil,
         cuisine: Cuisine? = nil,
         prepTime: PrepTime? = nil,
         createdAt: Date = .now,
         cookedCount: Int = 0,
         lastCooked: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.imageData = imageData
        self.ingredientsText = ingredientsText
        self.link = link
        self.instructions = instructions
        self.cuisine = cuisine
        self.prepTime = prepTime
        self.createdAt = createdAt
        self.cookedCount = cookedCount
        self.lastCooked = lastCooked
    }
}
