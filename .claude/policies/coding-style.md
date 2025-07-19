# Swift Coding Style Policy (for Claude Code context injection)

## 1. Language-Level Rules

- **Variable naming**: Use `lowerCamelCase` for all variables.  
  Claude must reject or rename variables using snake_case or uppercase.

- **Type naming**: All type names (class, struct, enum, protocol) must use `UpperCamelCase`.  
  Acronyms must be capitalized consistently (e.g. `URLSession`, not `UrlSession`).

- **Force unwrapping is not allowed** (using `!`).  
  Claude should default to `guard let` or `if let`, unless explicitly told otherwise.

- **Access control**: Default to `private(set)` for mutable properties.  
  Avoid unnecessary `public` declarations unless required for cross-module usage.

- **Prefer `struct` over `class`** by default.  
  Use `class` only when reference semantics are needed (e.g. shared mutable state, inheritance).

- **When using `class`, always mark it `final` unless subclassing is explicitly required**.  
  Claude must treat `final class` as the default.

- **Do not use `@ObservableObject` or `@Published`.**  
  Use Swift’s modern `@Observable` macro instead.  
  Claude must refactor any usage of `ObservableObject` to `@Observable`.

## 2. File-Level Rules

- Each Swift file must contain only one public type.  
  If multiple types are required, they must be moved into separate files.

- File names must match the name of the primary type they define.  
  For example, `UserModel.swift` must define `UserModel`.

- Public type declarations must appear at the top of the file.  
  Helper types or extensions must follow.

## 3. Architecture-Level Rules

- Do not import `UIKit`, `SwiftUI`, or `FoundationNetworking` in the Domain layer.  
  Claude must use protocol abstractions for external dependencies.

- All async code must use `async throws` signatures.  
  Claude must avoid completion handlers or callback-based APIs.

- Follow the Single Responsibility Principle.  
  Each type or file must encapsulate one clearly defined purpose.  
  Claude must not group unrelated logic into the same type.

## 4. SwiftUI-Specific UI Design Rules

- **Use `@Observable` macro for ViewModel state**.  
  Views must hold the ViewModel using `@State var viewModel: ViewModel`.  
  Claude must not use `@ObservedObject`, `@StateObject`, or `@EnvironmentObject`.

- **Do not launch Task blocks or embed async logic inside SwiftUI Views.**  
  Async workflows must be implemented as methods inside the ViewModel.  
  Views may invoke those methods directly, but may not construct or manage `Task` objects themselves.

  Recommended (ViewModel handles Task internally):

  ```swift
  // ViewModel
  func loadData() {
      Task {
          isLoading = true
          defer { isLoading = false }
          data = await repository.fetch()
      }
  }

  // View
  Button("Load") {
      viewModel.loadData()
  }

Not recommended:

    // View (bad practice)
    Button("Load") {
        Task {
            viewModel.data = await repository.fetch()
        }
    }

- **Avoid structural conditionals (`if`, `switch`) that change view hierarchy.**  
  Prefer `.opacity()`, `.hidden()`, `.overlay()` (or similar modifiers) to toggle visibility while keeping a stable structure.

- **Split views into small composable subviews.**  
  Extract reusable UI sections into isolated components to:
  - Minimize the rendering impact (smaller invalidation scope)
  - Improve readability & testability
  - Enable focused state binding

- **Follow the Minimum Scope of Impact Principle.**  
  When a state changes, only the views depending on that state should refresh.

  Claude must:
  - Organize view hierarchies so state changes do **not** trigger broad refreshes.
  - Avoid placing unrelated state under the same parent unless strictly necessary.
  - Use techniques like:
    - Fine-grained view splitting
    - `EquatableView` (only when profiling shows benefit)
    - Targeted bindings / localized state wrappers

  *Example:* When `isEditing` changes, only `EditableRow` (or its immediate subtree) should re-render—**not** the entire list.

---

### 5. Application Consistency

- All generated types (models, services, use cases, views, view models) must follow these rules, regardless of the initiating command or prompt.  
- When generating SwiftUI code, Claude must use the `@Observable` macro exclusively for ViewModels.  
- When defining new types within the same session, Claude must reuse prior naming conventions, property ordering, modifiers, and architectural structure for consistency.

---

### 6. Feedback Requirements

Claude must self-check compliance with this policy **before** proposing or committing changes.

If any rule is violated in generated or modified code, Claude must:

1. Clearly explain **which rule** was broken (reference the section).  
2. Provide or apply a concrete fix (diff or corrected snippet) **before** marking the work complete.  

