// =============================================================================
// cetz-classuml — Main Entry Point
// =============================================================================
// Public API for the cetz-classuml package.
// Provides both show-rule based (code fences) and function-based APIs.

#import "deps.typ": cetz
#import "ir.typ"
#import "parser/mod.typ" as parser
#import "grammars/mod.typ" as grammars
#import "renderer/mod.typ" as renderer

// =============================================================================
// Internal render function
// =============================================================================

/// Parse source code and render the class diagram.
#let _render-diagram(source, grammar: "plantuml", theme: auto, spacing: (x: 4.0, y: 3.5), fit: true) = {
  let diagram-ir = parser.parse(source, grammar: grammar)
  let result = renderer.render(diagram-ir, theme: theme, spacing: spacing)
  if fit {
    layout(bounds => context {
      let size = measure(result)
      if size.width > bounds.width {
        let factor = bounds.width / size.width
        scale(x: factor * 100%, y: factor * 100%, origin: top + left, result)
      } else {
        result
      }
    })
  } else {
    result
  }
}

// =============================================================================
// Show-rule API (code fences)
// =============================================================================

/// Setup function that enables code-fence rendering.
///
/// Usage:
/// ```typst
/// #import "src/lib.typ": setup-classuml
/// #show: setup-classuml
/// ```
///
/// Then use code fences:
/// ````
/// ```class-diagram-plantuml
/// class Foo { ... }
/// ```
/// ````
#let setup-classuml(
  theme: auto,
  spacing: (x: 4.0, y: 3.5),
  fit: true,
  doc,
) = {
  show raw.where(lang: "class-diagram-plantuml"): it => {
    _render-diagram(it.text, grammar: "plantuml", theme: theme, spacing: spacing, fit: fit)
  }
  show raw.where(lang: "class-diagram-java"): it => {
    _render-diagram(it.text, grammar: "java", theme: theme, spacing: spacing, fit: fit)
  }
  show raw.where(lang: "class-diagram-csharp"): it => {
    _render-diagram(it.text, grammar: "csharp", theme: theme, spacing: spacing, fit: fit)
  }
  doc
}

// =============================================================================
// Function API (programmatic)
// =============================================================================

/// Render a class diagram from source code.
///
/// - source (str): Source text in the specified grammar
/// - grammar (str or function): Grammar name ("plantuml", "java", "csharp") or custom parse function
/// - theme (dict): Theme override (default: built-in theme)
/// - spacing (dict): (x, y) spacing between classes
#let class-diagram(
  source,
  grammar: "plantuml",
  theme: auto,
  spacing: (x: 4.0, y: 3.5),
  fit: true,
) = {
  _render-diagram(source, grammar: grammar, theme: theme, spacing: spacing, fit: fit)
}

// =============================================================================
// Re-exports for advanced usage
// =============================================================================

// Allow users to create custom grammars
#let register-grammar = grammars.resolve-grammar

// Allow users to manipulate IR directly
#let create-class = ir.uml-class
#let create-member = ir.uml-member
#let create-relation = ir.uml-relation
#let create-diagram = ir.uml-diagram

// Allow users to render IR directly
#let render-ir = renderer.render
