//
//  Supabase.swift
//  BiteWise
//
//  Created by Regan on 2026-01-26.
//

import Foundation
import Supabase

// MARK: - Supabase Client Configuration

/// Global Supabase client instance
/// Credentials are loaded from Info.plist for security
let supabase: SupabaseClient = {
    guard let supabaseURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
          let supabaseURL = URL(string: supabaseURLString) else {
        fatalError("SUPABASE_URL not found in Info.plist. Please add your Supabase project URL.")
    }
    
    guard let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
        fatalError("SUPABASE_ANON_KEY not found in Info.plist. Please add your Supabase anon key.")
    }
    
    return SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
}()
