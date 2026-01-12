# Flutter & Dart Style Guide

## 1. Naming Conventions (Effective Dart)
- **Classes, Enums, Typedefs, and Extensions:** Use `UpperCamelCase`.
- **Libraries, Packages, Directories, and Source Files:** Use `lowercase_with_underscores`.
- **Variables, Parameters, and Named Parameters:** Use `lowerCamelCase`.
- **Constants:** Use `lowerCamelCase` (preferred in modern Dart) or `SCREAMING_SNAKE_CASE` only for legacy reasons.
- **Private Members:** Prefix with an underscore `_`.

## 2. Widget Best Practices
- **Small Widgets:** Break down large `build()` methods into smaller, reusable private `Widget` classes (prefer `StatelessWidget` over helper methods).
- **Const Constructors:** Use `const` constructors whenever possible to reduce rebuild time.
- **Immutability:** Keep widgets immutable. Use `final` for all fields in `StatelessWidget`.
- **Build Method Logic:** Keep `build()` methods pure. Avoid expensive computations or side effects (like API calls) inside `build()`.

## 3. State Management (Riverpod)
- **Providers:** Use functional providers (`@riverpod`) where possible.
- **AsyncValue:** Always handle loading and error states using `AsyncValue` patterns.
- **ConsumerWidget:** Use `ConsumerWidget` or `ConsumerStatefulWidget` to access providers.
- **Scoped Providers:** Use `.family` for parameterized providers.

## 4. Navigation (GoRouter & Coordinator)
- **Type-Safe Routes:** Use `TypedGoRoute` and generated route classes.
- **Coordinator Pattern:** UI widgets should not navigate directly via `context.go`. Use a `Coordinator` class to handle routing logic.
- **Parameter Passing:** Pass simple IDs or primitives in routes; fetch complex data in the target screen's provider.

## 5. Performance & Optimization
- **RepaintBoundary:** Use `RepaintBoundary` for complex animations or static parts of a frequently updated UI.
- **ListView.builder:** Always use `.builder` for long or infinite lists to enable lazy loading.
- **Isolates:** Use `compute()` for CPU-intensive tasks (like complex JSON parsing) to avoid jank.

## 6. Project Structure (Minglit Specific)
- **Feature-First:** Organize by domain (e.g., `lib/src/features/auth`) rather than type.
- **Layered Architecture:** 
  - `Data Layer`: Repositories and Models.
  - `Logic Layer`: Providers and Controllers.
  - `UI Layer`: Widgets and Screens.
- **Shared Kit:** Use `minglit_kit` for common components to maintain visual consistency.

## 7. Error Handling
- Use `handleMinglitError(context, e)` from `minglit_kit`.
- Prefer `AsyncValue.showMinglitError(context)` for Riverpod-driven UI updates.

