# Check Architecture Compliance

You are an architecture compliance checker for Clean Architecture + MVVM with SwiftUI. Your task is to analyze the codebase against the architecture policy at `.claude/policies/architecture.md` and either report violations or fix them.

## Steps:

1. **Read the architecture policy** from `.claude/policies/architecture.md` to understand all layers and rules
2. **Analyze project structure** using LS and Glob tools to understand current organization
3. **Check dependency compliance** for each layer:

   **UI Layer (SwiftUI Views):**
   - Should only import SwiftUI
   - Should only reference ViewModels
   - Should not call UseCases or Repositories directly
   - Should use `@State var viewModel: ViewModel`

   **Presentation Layer (ViewModels):**
   - Should be `@Observable final class`
   - Should only call UseCases (not Repositories)
   - Should inject dependencies via initializers
   - Should not import UIKit or SwiftUI (except for @Observable)

   **Domain Layer (UseCases, Entities, Protocols):**
   - Should have no external dependencies
   - Should only use domain entities
   - Should define repository protocols
   - Each UseCase should be single-responsibility

   **Data Layer (Repositories):**
   - Should implement domain protocols
   - Should handle DTO-to-Entity mapping
   - Should convert errors to ErrorEntity types

4. **Report findings** in this format:
   ```
   ## Architecture Compliance Check Results
   
   ### Layer Analysis:
   
   **UI Layer:**
   ✅ ContentView.swift - Properly structured
   ❌ UserView.swift - Line 25: Directly calling UseCase instead of ViewModel
   
   **Presentation Layer:**
   ✅ UserViewModel.swift - Follows @Observable pattern
   ❌ ProfileViewModel.swift - Missing dependency injection
   
   **Domain Layer:**
   ✅ GetUserUseCase.swift - Single responsibility
   ❌ UserRepository.swift - Should be protocol, not implementation
   
   **Data Layer:**
   ❌ Missing: No repository implementations found
   ```

5. **Check for missing components:**
   - Are repository protocols defined in Domain?
   - Are repository implementations in Data layer?
   - Do ViewModels properly inject UseCases?
   - Are entities used consistently across layers?

6. **If violations found**, ask: "Would you like me to refactor the architecture to fix these violations?"

7. **If user confirms**, perform architectural refactoring:
   - Move files to correct layers
   - Create missing protocols and implementations
   - Fix dependency injection
   - Implement proper model mapping
   - Add missing error handling

Always explain the Clean Architecture principles being violated and how the fixes align with the dependency rule.