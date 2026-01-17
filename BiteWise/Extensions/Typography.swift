import SwiftUI

// MARK: - BiteWise Typography System
// Consistent SF Pro Rounded typography with semantic naming

public struct BWTypography {
    
    // MARK: - Hero & Display
    
    /// Extra large hero text for splash screens and major headers
    /// Size: 42pt, Weight: Bold, Design: Rounded
    public static let heroTitle = Font.system(size: 42, weight: .bold, design: .rounded)
    
    /// Large display text for welcome screens
    /// Size: 36pt, Weight: Bold, Design: Rounded
    public static let displayLarge = Font.system(size: 36, weight: .bold, design: .rounded)
    
    /// Medium display text
    /// Size: 32pt, Weight: Bold, Design: Rounded
    public static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    
    // MARK: - Section Headers
    
    /// Primary section header
    /// Size: 28pt, Weight: Bold, Design: Rounded
    public static let sectionHeader = Font.system(size: 28, weight: .bold, design: .rounded)
    
    /// Secondary section header
    /// Size: 22pt, Weight: Semibold, Design: Rounded
    public static let sectionSubheader = Font.system(size: 22, weight: .semibold, design: .rounded)
    
    /// Card title
    /// Size: 18pt, Weight: Semibold, Design: Rounded
    public static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    // MARK: - Body Text
    
    /// Primary body text
    /// Size: 16pt, Weight: Regular, Design: Rounded
    public static let bodyPrimary = Font.system(size: 16, weight: .regular, design: .rounded)
    
    /// Secondary body text (lighter)
    /// Size: 15pt, Weight: Regular, Design: Rounded
    public static let bodySecondary = Font.system(size: 15, weight: .regular, design: .rounded)
    
    /// Emphasized body text
    /// Size: 16pt, Weight: Medium, Design: Rounded
    public static let bodyEmphasis = Font.system(size: 16, weight: .medium, design: .rounded)
    
    // MARK: - Labels & Buttons
    
    /// Button label text
    /// Size: 17pt, Weight: Semibold, Design: Rounded
    public static let buttonLabel = Font.system(size: 17, weight: .semibold, design: .rounded)
    
    /// Small button/action text
    /// Size: 15pt, Weight: Semibold, Design: Rounded
    public static let buttonSmall = Font.system(size: 15, weight: .semibold, design: .rounded)
    
    /// Navigation/tab label
    /// Size: 10pt, Weight: Medium, Design: Rounded
    public static let tabLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    
    // MARK: - Captions & Supporting
    
    /// Primary caption text
    /// Size: 13pt, Weight: Regular, Design: Rounded
    public static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    
    /// Secondary caption (smaller)
    /// Size: 11pt, Weight: Regular, Design: Rounded
    public static let captionSmall = Font.system(size: 11, weight: .regular, design: .rounded)
    
    /// Badge/tag text
    /// Size: 12pt, Weight: Semibold, Design: Rounded
    public static let badge = Font.system(size: 12, weight: .semibold, design: .rounded)
    
    // MARK: - Numeric
    
    /// Large numeric display (for stats)
    /// Size: 32pt, Weight: Bold, Design: Rounded
    public static let numericLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    
    /// Medium numeric display
    /// Size: 24pt, Weight: Bold, Design: Rounded
    public static let numericMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    
    /// Small numeric display
    /// Size: 18pt, Weight: Semibold, Design: Rounded
    public static let numericSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
}

// MARK: - View Extension for Easy Access
public extension View {
    func bwFont(_ font: Font) -> some View {
        self.font(font)
    }
}

// MARK: - Text Style Modifiers
public extension Text {
    func heroStyle() -> Text {
        self.font(BWTypography.heroTitle)
    }
    
    func sectionHeaderStyle() -> Text {
        self.font(BWTypography.sectionHeader)
    }
    
    func cardTitleStyle() -> Text {
        self.font(BWTypography.cardTitle)
    }
    
    func bodyStyle() -> Text {
        self.font(BWTypography.bodyPrimary)
    }
    
    func captionStyle() -> Text {
        self.font(BWTypography.caption)
    }
    
    func badgeStyle() -> Text {
        self.font(BWTypography.badge)
    }
}

// MARK: - Updated Font Helpers (Using Rounded Design)
public extension Font {
    static func bwLargeTitle() -> Font {
        BWTypography.sectionHeader
    }
    
    static func bwTitle() -> Font {
        BWTypography.displayMedium
    }
    
    static func bwTitle2() -> Font {
        BWTypography.sectionSubheader
    }
    
    static func bwTitle3() -> Font {
        BWTypography.cardTitle
    }
    
    static func bwHeadline() -> Font {
        BWTypography.cardTitle
    }
    
    static func bwBody() -> Font {
        BWTypography.bodyPrimary
    }
    
    static func bwSubheadline() -> Font {
        BWTypography.bodySecondary
    }
    
    static func bwCaption() -> Font {
        BWTypography.caption
    }
    
    static func bwCaption2() -> Font {
        BWTypography.captionSmall
    }
    
    static func bwButton() -> Font {
        BWTypography.buttonLabel
    }
}

