# BiteWise

## Overview
BiteWise is an AI-powered fridge-to-recipe mobile app that detects ingredients, suggests recipes, refines recommendations through an AI assistant, and adapts to user preferences.

## Features Implemented

### Onboarding & Setup
- **Welcome Screen** with clean introduction and "Get Started" button
- **Pantry Setup** with selectable pill buttons and custom item entry
- **User Profile** management with preferences

### Core Functionality
- **Fridge Photo Upload** screen with dotted box UI and image placeholder
- **Smooth Animated Analyzing Spinner** using custom SwiftUI spinner
- **Ingredient Detection** with modern selectable ingredient cards, rounded checkboxes, and AI Detected pill labels
- **Recipe Suggestions** screen displaying recipe cards with macros (P/C/F tags) and estimated cooking time
- **Recipe Detail View** with ingredients list, preparation steps, and macro information

### AI Assistant
- **Floating Gradient AI Assistant Button** fixed to bottom of screen
- **AI Assistant Chat Interface** for recipe refinement and food questions
- **AI Assistant Intro Screen** describing features and capabilities

## Tech Stack

- **iOS SwiftUI** (fully native SwiftUI architecture)
- **Reusable SwiftUI Components**:
  - MacroBadge
  - RecipeCard
  - ChatBubble
  - FlowLayout
  - GradientButton
  - Spinner
  - PhotoUploadBoxView
  - AIRecipeAssistantCardView
- **Clean Code Organization** for easy expansion to API integrations
- **Navigation** using SwiftUI NavigationStack

## Project Structure

```
BiteWise/
  ├── Models/
  │   ├── Ingredient.swift
  │   ├── Recipe.swift
  │   ├── ChatMessage.swift
  │   └── UserProfile.swift
  ├── Views/
  │   ├── Components/
  │   │   ├── ChatBubble.swift
  │   │   ├── MacroBadge.swift
  │   │   └── RecipeCard.swift
  │   └── Screens/
  │       ├── WelcomeScreen.swift
  │       ├── PantrySetupScreen.swift
  │       ├── PhotoUploadScreen.swift
  │       ├── DetectedIngredientsScreen.swift
  │       ├── RecipeSuggestionScreen.swift
  │       ├── RecipeDetailScreen.swift
  │       ├── ChatbotScreen.swift
  │       ├── FeedbackScreen.swift
  │       └── UserProfileScreen.swift
  └── AppNavigation.swift
```

## Next Steps / Future Work

- Integrate ingredient detection API (Google Vision, Clarifai, etc.)
- Connect recipe APIs (Spoonacular or Edamam)
- Build AI chat refinement layer (OpenAI Assistants API)
- Add persistent backend (Firebase or Supabase)
- Implement user authentication and profile management
- Add recipe favorites and history functionality
- Implement nutritional tracking and personalized recommendations

## Build Instructions

- **Requirements**: 
  - Xcode 15 or later
  - iOS 16.0+ deployment target
- **Dependencies**: No external dependencies yet
- **Installation**: 
  1. Clone the repository
  2. Open `BiteWise.xcodeproj` in Xcode
  3. Select a simulator or device
  4. Build and run (⌘+R)

## Screenshots
*(Coming soon)*

## Author
Regan Li
