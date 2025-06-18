//
//  BiteWiseApp.swift
//  BiteWise
//
//  Created by Regan on 2025-06-16.
//

import SwiftUI

@main
struct BiteWiseApp: App {
    init() {
        // Make navigation bar transparent
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            AppNavigation()
        }
    }
}
