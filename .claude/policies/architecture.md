# architecture.md

This file defines the architectural contract for Claude Code. It informs how Claude should generate, refactor, and reason about files in this repository. All code must conform to the following multi-layer design based on Clean Architecture and SwiftUI with the Observation framework.

## Overall Principles

This project uses **Clean Architecture + MVVM with SwiftUI**, aiming to enforce clear separation of concerns, testability, and composability.

Claude Code must respect the dependency rule:

- Outer layers depend on inner layers, never the reverse.
- Dependencies are always injected via protocols (inversion of control).
- UI and data sources are volatile; domain logic is the most stable.

---

## Layer Responsibilities

### 1. UI Layer (SwiftUI Views)

- Responsible only for UI rendering and user interaction.
- Should hold references to a ViewModel only.
- Uses SwiftUI bindings (`@Bindable`, `@State`, etc.) to reflect state.
- Does not directly call any business logic or UseCases.
- UI files are not required to be tested.

**Claude MUST:**
- Keep views as "dumb" as possible — no business logic, no branching.
- Avoid any direct usage of UseCase or Repository in views.
- Rely on ViewModel for all state values, event dispatch, and actions.

---

### 2. Presentation Layer (ViewModels)

- Handles view state, transformations, and presentation logic.
- Talks to UseCases to perform business actions.
- Uses `@Observable` macro (from the Swift Observation framework) to model reactive state.
- Avoids `ObservableObject` and `@Published`, favoring macros for performance and type safety.
- Does not manage UI lifecycle or navigation logic directly.
- Must be testable via state mutation and method invocation.

**Claude MUST:**
- Declare ViewModels as `@Observable final class` if needed.
- Avoid direct usage of data layers.
- Inject all dependencies (e.g., UseCases) via initializers.
- Never include view lifecycle or UIKit logic.

---

### 3. Domain Layer (UseCases, Entities, Repository Protocols)

- UseCases define app-specific business operations and workflows.
- Entities are pure value types representing business concepts and rules.
- Repository protocols define data access contracts.
- This layer is the most stable, reusable, and testable.
- Must contain all business rules, and no external dependencies (frameworks, databases, UI).

**Claude MUST:**
- Generate UseCases with single, well-scoped responsibilities.
- Never combine unrelated workflows into one UseCase.
- Use only domain entities in UseCase inputs/outputs.
- Provide a unit test file with every new UseCase generated.

---

### 4. Data Layer (Repositories + Data Sources)

- Repositories implement the data access protocols from the domain layer.
- Perform model mapping between DTOs and Entities.
- Coordinate access to data sources like APIs, local storage, or databases.
- Responsible for converting lower-level errors to `ErrorEntity` domain errors.

**Claude MUST:**
- Contain all DTO-to-Entity mapping logic inside repositories.
- Not allow repositories to call other repositories.
- Ensure each repository manages only its own data sources.
- Generate testable repository logic and test files.

---

## Model Mapping Rules

- Each layer defines its own models — models must NOT cross layers directly.
- Mappings are always done by the dependent layer.
- Domain Layer models (Entities) are the only ones used in UseCases.
- UI should use primitive types like `String`, `Bool`, `Int`, etc.
- ViewModel-specific models may be introduced only when primitive types are insufficient.

Claude must follow this mapping pattern:
---

## Error Handling Strategy

- Errors are treated as first-class data — each layer must map and propagate explicitly.
- Data Source errors → mapped to Repository errors → mapped to `ErrorEntity` → converted to display state in ViewModel.
- ViewModel must expose user-friendly display values or states for UI to consume.
- ViewModel must NOT throw errors — instead, represent failure via observable state.

Claude MUST:
- Define proper `ErrorEntity` types per use case.
- Include test coverage for failure paths.
- Use localized, user-readable error messages in ViewModel.

---

## Summary

Claude Code must treat this file as a **protocol contract** when working within this repository. All generated or modified files — especially those in UseCase, Repository, and ViewModel layers — must follow these architectural rules.

Violations should be flagged explicitly with suggestions for alignment.