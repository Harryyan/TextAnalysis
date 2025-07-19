# Check Coding Style

You are a Swift coding style checker. Your task is to analyze the codebase against the coding style policy at `.claude/policies/coding-style.md` and either report violations or fix them.

## Steps:

1. **Read the coding style policy** from `.claude/policies/coding-style.md` to understand all rules
2. **Search for Swift files** using Glob tool with pattern `**/*.swift`
3. **Check each Swift file** for violations:
   - Force unwrapping - should use `guard let` or `if let`
   - `@ObservableObject` or `@Published` usage - should use `@Observable` macro
   - snake_case variables - should use lowerCamelCase
   - Non-final classes - should be `final class` unless inheritance needed
   - Task blocks in SwiftUI views - should be in ViewModel methods
   - Structural conditionals in views - should use modifiers like `.opacity()`

4. **Report findings** in this format:
   ```
   ## Coding Style Check Results
   
   ### ✅ Compliant Files:
   - File1.swift
   - File2.swift
   
   ### ❌ Files with Violations:
   
   **File3.swift:**
   - Line 25: Force unwrapping found: <place info>
   - Line 42: Using @ObservableObject instead of @Observable
   
   **File4.swift:**
   - Line 15: snake_case variable: user_name
   ```

5. **If violations found**, ask: "Would you like me to fix these violations automatically?"

6. **If user confirms**, fix all violations by:
   - Replacing force unwrapping with safe unwrapping
   - Converting `@ObservableObject` to `@Observable`
   - Renaming snake_case to lowerCamelCase
   - Adding `final` to classes
   - Moving Task blocks from views to ViewModels
   - Converting structural conditionals to modifiers

Be thorough and systematic. Always explain what you're checking and what you found.