// This file is used to check that the Color(hex:) initializer works without ambiguity
import SwiftUI

// Check if the Color(hex:) initializer works without ambiguity
let blueColor = Color(hex: "0000FF")
let greenColor = Color(hex: "00FF00")

print("✅ Color(hex:) initializer works without ambiguity") 