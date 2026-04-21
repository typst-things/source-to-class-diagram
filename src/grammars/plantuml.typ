// =============================================================================
// cetz-classuml — PlantUML Grammar
// =============================================================================
// Parses PlantUML class diagram syntax into the IR.

#import "../ir.typ"
#import "../parser/utils.typ" as putils

// =============================================================================
// Class Declaration Parser
// =============================================================================

/// Try to parse a line as a class/interface/enum declaration.
/// Returns a uml-class dictionary or none.
#let _try-parse-class-decl(line) = {
  // Match: [abstract] (class|interface|enum|annotation) Name [<generics>] [<<stereotype>>]
  let m = line.match(regex("^(?:(abstract)\\s+)?(class|interface|enum|annotation)\\s+"))
  if m == none { return none }

  let is-abstract = m.captures.at(0) != none
  let keyword = m.captures.at(1)

  // Get everything after the keyword
  let rest = line.slice(m.end)

  // Extract class name — handle quoted names: "My Class" as alias
  let name = ""
  let after-name = ""

  if rest.starts-with("\"") {
    let m2 = rest.match(regex("^\"([^\"]+)\""))
    if m2 != none {
      name = m2.captures.at(0)
      after-name = rest.slice(m2.end)
      // Check for 'as alias' pattern
      let alias-match = after-name.match(regex("^\\s+as\\s+(\\w+)"))
      if alias-match != none {
        name = alias-match.captures.at(0)
        after-name = after-name.slice(alias-match.end)
      }
    }
  } else {
    let m2 = rest.match(regex("^([\\w.]+)"))
    if m2 != none {
      name = m2.text
      after-name = rest.slice(m2.end)
    }
  }

  if name == "" { return none }

  // Determine type
  let cls-type = if is-abstract { "abstract" } else { keyword }

  // Extract generics <T>
  let generics = none
  let gen-match = after-name.match(regex("^\\s*<([^>]+)>"))
  if gen-match != none {
    generics = gen-match.captures.at(0)
    after-name = after-name.slice(gen-match.end)
  }

  // Extract stereotype <<Name>>
  let stereotype = putils.parse-stereotype(after-name)

  ir.uml-class(
    name: name,
    type: cls-type,
    stereotype: stereotype,
    generics: generics,
  )
}

// =============================================================================
// Member Parser
// =============================================================================

/// Parse a line inside a class body as a member (field or method).
/// Returns a uml-member dictionary or none (for separators).
#let _parse-member-line(line) = {
  let trimmed = line.trim()

  // Skip separators: --, .., ==, __
  if trimmed.len() >= 2 {
    let first-two = trimmed.slice(0, 2)
    if first-two == "--" or first-two == ".." or first-two == "==" or first-two == "__" {
      return none
    }
  }

  if trimmed == "" { return none }

  // 1. Extract visibility prefix (+, -, #, ~)
  let visibility = "package"
  let rest = trimmed

  if rest.len() > 0 {
    let vis = putils.parse-visibility-symbol(rest.at(0))
    if vis != none {
      visibility = vis
      rest = rest.slice(1).trim()
    }
  }

  // 2. Extract modifiers: {static}, {abstract}
  let modifiers = ()
  let keep-parsing = true
  while keep-parsing {
    if rest.starts-with("{static}") {
      modifiers.push("static")
      rest = rest.slice(8).trim()
    } else if rest.starts-with("{abstract}") {
      modifiers.push("abstract")
      rest = rest.slice(10).trim()
    } else {
      keep-parsing = false
    }
  }

  // 3. Determine method vs field
  let is-method = rest.contains("(")
  let kind = if is-method { "method" } else { "field" }

  let name = ""
  let return-type = none
  let params = none

  if is-method {
    // Extract params from parentheses
    let paren-match = rest.match(regex("\\(([^)]*)\\)"))
    if paren-match != none {
      let raw-params = paren-match.captures.at(0)
      if raw-params.trim() != "" { params = raw-params.trim() }
    }

    if rest.contains(":") {
      // Format: methodName(params) : ReturnType
      let parts = rest.split(":")
      let left = parts.at(0).trim()
      return-type = parts.slice(1).join(":").trim()
      // Extract name (everything before the opening paren)
      let name-match = left.match(regex("^([^(]+)"))
      if name-match != none { name = name-match.text.trim() }
    } else {
      // Format: ReturnType methodName(params) or just methodName(params)
      let before-paren = rest.match(regex("^([^(]+)"))
      if before-paren != none {
        let words = before-paren.text.trim().split(regex("\\s+"))
        if words.len() >= 2 {
          return-type = words.slice(0, words.len() - 1).join(" ")
          name = words.last()
        } else {
          name = before-paren.text.trim()
        }
      }
    }
  } else {
    // Field parsing
    if rest.contains(":") {
      // Format: fieldName : Type
      let parts = rest.split(":")
      name = parts.at(0).trim()
      return-type = parts.slice(1).join(":").trim()
    } else {
      // Format: Type fieldName
      let words = rest.split(regex("\\s+"))
      if words.len() >= 2 {
        return-type = words.slice(0, words.len() - 1).join(" ")
        name = words.last()
      } else {
        name = rest
      }
    }
  }

  ir.uml-member(
    name: name,
    return-type: return-type,
    visibility: visibility,
    modifiers: modifiers,
    kind: kind,
    params: params,
  )
}

// =============================================================================
// Relation Parser
// =============================================================================

/// Parse a line as a relation between two classes.
/// Returns a uml-relation dictionary or none.
#let _try-parse-relation(line) = {
  let op-info = putils.detect-relation-operator(line)
  if op-info == none { return none }

  // Split line at the operator
  let parts = line.split(op-info.op)
  if parts.len() < 2 { return none }

  let left-text = parts.at(0)
  let right-raw = parts.slice(1).join(op-info.op)

  // Extract label (after :)
  let label = none
  let right-text = right-raw
  if right-raw.contains(":") {
    let colon-parts = right-raw.split(":")
    right-text = colon-parts.at(0)
    label = colon-parts.slice(1).join(":").trim()
  }

  // Parse sides
  let left = putils.parse-relation-side(left-text)
  let right = putils.parse-relation-side(right-text)

  // Skip if either name is empty
  if left.name == "" or right.name == "" { return none }

  // Apply swap for operators like <|--, <--, etc.
  let (from, to, from-card, to-card) = if op-info.swap {
    (right.name, left.name, right.card, left.card)
  } else {
    (left.name, right.name, left.card, right.card)
  }

  ir.uml-relation(
    from: from,
    to: to,
    type: op-info.type,
    label: label,
    from-card: from-card,
    to-card: to-card,
  )
}

// =============================================================================
// Main Parse Function
// =============================================================================

/// Parse PlantUML class diagram source into IR.
///
/// Supports: class, abstract class, interface, enum, annotation,
/// members with visibility (+/-/#/~), {static}, {abstract},
/// relations (<|--. *--, o--, -->, etc.), labels, cardinalities,
/// stereotypes, generics.
#let parse(source) = {
  let lines = source.split("\n")

  let classes = ()
  let relations = ()
  let packages = ()

  let current-class = none
  let current-members = ()
  let brace-depth = 0

  for raw-line in lines {
    let line = raw-line.trim()

    // Skip empty lines, comments, and markers
    if line == "" or line.starts-with("'") or line.starts-with("//") {
      continue
    }
    if line.starts-with("@startuml") or line.starts-with("@enduml") {
      continue
    }

    // --- Inside a class body ---
    if brace-depth > 0 {
      // Count braces in this line
      for ch in line.clusters() {
        if ch == "{" { brace-depth += 1 }
        if ch == "}" { brace-depth -= 1 }
      }

      if brace-depth == 0 {
        // Closing brace — finalize class
        if current-class != none {
          current-class.insert("members", current-members)
          classes.push(current-class)
          current-class = none
          current-members = ()
        }
      } else {
        // Member line
        let member = _parse-member-line(line)
        if member != none {
          current-members.push(member)
        }
      }
      continue
    }

    // --- Outside class body ---

    // Try class declaration
    let cls = _try-parse-class-decl(line)
    if cls != none {
      current-class = cls
      current-members = ()
      // Check if this line opens a brace
      if line.contains("{") {
        brace-depth = 1
        // If the line also closes (e.g., `class Foo {}`), handle it
        for ch in line.clusters() {
          if ch == "{" { brace-depth += 1 }
          if ch == "}" { brace-depth -= 1 }
        }
        // Correct: we already counted one `{` when setting brace-depth = 1
        // But the loop also counts it. Reset:
        brace-depth = 0
        for ch in line.clusters() {
          if ch == "{" { brace-depth += 1 }
          if ch == "}" { brace-depth -= 1 }
        }
        if brace-depth == 0 {
          // Class opened and closed on same line (e.g., `class Foo {}`)
          current-class.insert("members", current-members)
          classes.push(current-class)
          current-class = none
          current-members = ()
        }
      } else {
        // No brace — class with no body (just declaration)
        classes.push(cls)
        current-class = none
        current-members = ()
      }
      continue
    }

    // Try relation
    let rel = _try-parse-relation(line)
    if rel != none {
      relations.push(rel)
      continue
    }
  }

  // Post-processing: auto-create classes referenced in relations but not declared
  let known-names = classes.map(c => c.name)
  let mentioned = ()
  for rel in relations {
    if not (rel.from in known-names) and not (rel.from in mentioned) {
      mentioned.push(rel.from)
      classes.push(ir.uml-class(name: rel.from))
    }
    if not (rel.to in known-names) and not (rel.to in mentioned) {
      mentioned.push(rel.to)
      classes.push(ir.uml-class(name: rel.to))
    }
  }

  ir.uml-diagram(
    classes: classes,
    relations: relations,
    packages: packages,
  )
}
