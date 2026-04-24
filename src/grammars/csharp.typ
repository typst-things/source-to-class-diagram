// =============================================================================
// cetz-classuml — C# Grammar
// =============================================================================

#import "../ir.typ"
#import "../parser/utils.typ" as putils

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
    if line == "" or line.starts-with("//") { continue }

    // --- Inside a class body ---
    if brace-depth > 0 {
      let depth-before = brace-depth
      for ch in line.clusters() {
        if ch == "{" { brace-depth += 1 }
        if ch == "}" { brace-depth -= 1 }
      }

      // Detect Exception Throws
      let throw-matches = line.matches(regex("throw\\s+new\\s+([A-Z][\\w.]*)"))
      let throw-targets = ()
      for tm in throw-matches {
        let target = tm.captures.at(0)
        throw-targets.push(target)
        relations.push(ir.uml-relation(
          from: current-class.name,
          to: target,
          type: "dependency"
        ))
      }

      // Detect Composition
      if line.contains(" new ") {
        let new-matches = line.matches(regex("new\\s+([A-Z][\\w.]*)\\s*\\("))
        for nm in new-matches {
          let target = nm.captures.at(0)
          if (target not in throw-targets) and (not putils.is-primitive-type(target)) {
            relations.push(ir.uml-relation(
              from: current-class.name,
              to: target,
              type: "composition"
            ))
          }
        }
      }

      if brace-depth == 0 {
        if current-class != none {
          current-class.insert("members", current-members)
          classes.push(current-class)
          current-class = none
          current-members = ()
        }
      } else if depth-before == 1 {
        // Parse Member (Field or Method or Constructor or Property)
        let rest = line
        let visibility = "package"
        
        let vis-match = rest.match(regex("^(public|private|protected|internal)\\s+"))
        if vis-match != none {
          visibility = vis-match.captures.at(0)
          if visibility == "internal" { visibility = "package" }
          rest = rest.slice(vis-match.end).trim()
        }

        let modifiers = ()
        let keep-parsing = true
        while keep-parsing {
          if rest.starts-with("static ") {
            modifiers.push("static")
            rest = rest.slice(7).trim()
          } else if rest.starts-with("abstract ") or rest.starts-with("virtual ") or rest.starts-with("override ") {
            if not ("abstract" in modifiers) { modifiers.push("abstract") }
            rest = rest.split(" ").slice(1).join(" ").trim()
          } else if rest.starts-with("sealed ") or rest.starts-with("readonly ") {
            rest = rest.split(" ").slice(1).join(" ").trim()
          } else {
            keep-parsing = false
          }
        }

        let is-method = rest.contains("(")

        if is-method {
          let pre-paren-match = rest.match(regex("^([^(]+)"))
          if pre-paren-match != none {
            let pre-paren = pre-paren-match.text.trim()
            let parts = pre-paren.split(regex("\\s+"))
            
            // Check if constructor
            if parts.len() == 1 and parts.at(0) == current-class.name {
              // Constructor
              let paren-inside = putils.extract-between(rest, "(", ")")
              if paren-inside != none and paren-inside.trim() != "" {
                let params-str = paren-inside.trim()
                current-members.push(ir.uml-member(
                  name: current-class.name,
                  return-type: none,
                  visibility: visibility,
                  modifiers: modifiers,
                  kind: "method",
                  params: params-str
                ))
                // Extract aggregations from parameters
                let param-parts = params-str.split(",")
                for p in param-parts {
                  let p-trim = p.trim()
                  let p-words = p-trim.split(regex("\\s+"))
                  if p-words.len() >= 2 {
                    let type-name = p-words.at(0)
                    type-name = type-name.replace(regex("<.*>"), "").replace("[]", "")
                    if not putils.is-primitive-type(type-name) {
                      relations.push(ir.uml-relation(
                        from: current-class.name,
                        to: type-name,
                        type: "aggregation"
                      ))
                    }
                  }
                }
              } else {
                current-members.push(ir.uml-member(
                  name: current-class.name,
                  return-type: none,
                  visibility: visibility,
                  modifiers: modifiers,
                  kind: "method",
                  params: none
                ))
              }
            } else if parts.len() >= 2 {
              // Standard method
              let name = parts.last()
              let return-type = parts.slice(0, parts.len() - 1).join(" ")
              let params-str = putils.extract-between(rest, "(", ")")
              
              current-members.push(ir.uml-member(
                name: name,
                return-type: return-type,
                visibility: visibility,
                modifiers: modifiers,
                kind: "method",
                params: if params-str != "" { params-str } else { none }
              ))
            }
          }
        } else {
          // Field or Property
          if rest.contains("=") {
            rest = rest.split("=").at(0).trim()
          }
          if rest.contains("{") {
            rest = rest.split("{").at(0).trim()
          }
          if rest.ends-with(";") {
            rest = rest.slice(0, rest.len() - 1).trim()
          }
          let parts = rest.split(regex("\\s+"))
          if parts.len() >= 2 {
            let name = parts.last()
            let return-type = parts.slice(0, parts.len() - 1).join(" ")
            
            // Generate association relation for fields that are not primitive
            let clean-type = return-type.replace(regex("<.*>"), "").replace("[]", "")
            if not putils.is-primitive-type(clean-type) {
                relations.push(ir.uml-relation(
                  from: current-class.name,
                  to: clean-type,
                  type: "association"
                ))
            }

            current-members.push(ir.uml-member(
              name: name,
              return-type: return-type,
              visibility: visibility,
              modifiers: modifiers,
              kind: "field"
            ))
          }
        }
      }
      continue
    }

    // --- Outside class body ---
    let m = line.match(regex("^(?:(public|protected|private|internal)\\s+)?(?:(abstract|sealed)\\s+)?(class|interface|struct|enum)\\s+([A-Z][\\w.]*)"))
    if m != none {
      let is-abstract = m.captures.at(1) == "abstract"
      let keyword = m.captures.at(2)
      let name = m.captures.at(3)
      let cls-type = if is-abstract { "abstract" } else if keyword == "struct" { "class" } else { keyword }

      let is-opening = line.contains("{")

      let cls = ir.uml-class(name: name, type: cls-type)
      current-class = cls
      current-members = ()

      // Parse inheritance/implementation
      let after-name = line.slice(m.end)
      let colon-match = after-name.match(regex(":\\s*([^{]+)"))
      if colon-match != none {
        let inheritsStr = colon-match.captures.at(0)
        let inherits = inheritsStr.split(",").map(s => s.trim())
        for inherit in inherits {
          if inherit != "" {
            let rel-type = if inherit.starts-with("I") and inherit.len() > 1 and inherit.at(1).match(regex("[A-Z]")) != none { "implementation" } else { "inheritance" }
            relations.push(ir.uml-relation(from: name, to: inherit, type: rel-type))
          }
        }
      }

      if is-opening {
        brace-depth = 1
        for ch in line.clusters() {
          if ch == "{" { brace-depth += 1 }
          if ch == "}" { brace-depth -= 1 }
        }
        brace-depth -= 1 // adjust the initial +1 guess
        
        if brace-depth == 0 {
          current-class.insert("members", current-members)
          classes.push(current-class)
          current-class = none
        }
      } else {
        classes.push(cls)
        current-class = none
      }
    }
  }

  ir.uml-diagram(classes: classes, relations: relations, packages: packages)
}
