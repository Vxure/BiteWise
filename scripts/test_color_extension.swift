import SwiftUI
@testable import BiteWise

// Test the Color(hex:) initializer
func testColorExtension() {
    let color1 = Color(hex: "FF0000") // Red
    let color2 = Color(hex: "00FF00") // Green
    let color3 = Color(hex: "0000FF") // Blue
    
    print("Successfully created colors using Color(hex:)")
}

testColorExtension() 