# 💡 BiteWise — UI Prototype Plan (Cursor Master Document)

---

## 🚩 Initialization Status

- ✅ Xcode project has already been initialized.
- ✅ SwiftUI structure is in place.
- ✅ Cursor can directly generate SwiftUI `View` files and supporting code.
- ✅ No backend or API integration yet — UI dummy data only.

---

## 1️⃣ App Overview

**App Name**: BiteWise  
**Platform**: iOS (SwiftUI)  
**Goal**: Build complete SwiftUI dummy-data UI to simulate app flow.

---

## 2️⃣ Styling Guidelines

- Modern minimal UI.
- Light theme.
- Use:
  - **Pastel green** (light green) for high protein indicators.
  - **Pastel yellow** for fat indicators.
- Display macros as text or buttons with corresponding color backgrounds.
- Bubble-style chat UI for chatbot screen.

---

## 3️⃣ App Screen Flow (Generate in This Order)

### 1. Welcome Screen
- App name: **BiteWise**
- Logo placeholder.
- “Get Started” button.

### 2. Photo Upload Screen
- Button: "Upload Fridge Photo".
- Display placeholder image after "upload".

### 3. Detected Ingredients Screen
- Dummy ingredient list:
  - Chicken
  - Eggs
  - Spinach
  - Cheese
  - Yogurt
  - Broccoli
- Checkbox for each ingredient.
- Allow manual add/remove.

### 4. Recipe Suggestion Screen
- 3 dummy recipes:
  - Grilled Chicken Salad
  - Spinach Omelet
  - Yogurt Parfait
- Each card shows:
  - Recipe title
  - Placeholder image
  - Short description
  - Macros (protein: pastel green, fats: pastel yellow, carbs: neutral)

### 5. Recipe Detail Screen
- Ingredients (dummy list)
- Cooking steps (dummy text)
- Prep & cook time
- Macros breakdown w/ color indicators

### 6. AI ChatBot Refinement Screen
- Bubble-style chat UI.
- User input field.
- Dummy system responses:
  - "Would you like something Italian?"
  - "Do you prefer high-protein options today?"
  - "I can also suggest a vegetarian option."

### 7. Feedback Screen
- 5-star rating (dummy).
- Toggle: "Enjoyed this recipe?" (Yes/No).

### 8. User Profile Screen
- Dummy editable fields:
  - Preferences
  - Allergies
  - Macro goals

---

## 4️⃣ Dummy Data

- Use fixed static data for ingredients, recipes, macros.
- No API calls, no backend.
- Fully local dummy data.

---

## 5️⃣ Output Instructions

- Use clean SwiftUI architecture.
- Organize each screen as separate SwiftUI `View` files.
- Prepare for easy future backend/API wiring.
- Navigation flow should loosely follow the screen order above.

---

✅ **Cursor: You may now proceed with code generation based on this structure.**

---