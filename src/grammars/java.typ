// =============================================================================
// cetz-classuml — Java Grammar
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
  
  let layout-level = none
  let layout-order = none

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

      // Detect Composition from `new ClassName()` inside any class code
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
        // Parse Member (Field or Method or Constructor)
        let rest = line
        let visibility = "package"
        
        let vis-match = rest.match(regex("^(public|private|protected)\\s+"))
        if vis-match != none {
          visibility = vis-match.captures.at(0)
          rest = rest.slice(vis-match.end).trim()
        }

        let modifiers = ()
        let keep-parsing = true
        while keep-parsing {
          if rest.starts-with("static ") {
            modifiers.push("static")
            rest = rest.slice(7).trim()
          } else if rest.starts-with("abstract ") {
            modifiers.push("abstract")
            rest = rest.slice(9).trim()
          } else if rest.starts-with("final ") {
            // ignore final for diagram
            rest = rest.slice(6).trim()
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
          // Field
          if rest.contains("=") {
            rest = rest.split("=").at(0).trim()
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
    let layout-match = line.match(regex("^@Layout\\s*\\((.*)\\)"))
    if layout-match != none {
      let params = layout-match.captures.at(0)
      let level-m = params.match(regex("level\\s*=\\s*(\\d+)"))
      let order-m = params.match(regex("order\\s*=\\s*(\\d+)"))
      if level-m != none { layout-level = int(level-m.captures.at(0)) }
      if order-m != none { layout-order = int(order-m.captures.at(0)) }
      continue
    }

    let m = line.match(regex("^(?:(public|protected|private|package)\\s+)?(?:(abstract)\\s+)?(class|interface|enum|@interface)\\s+([A-Z][\\w.]*)"))
    if m != none {
      let is-abstract = m.captures.at(1) != none
      let keyword = m.captures.at(2)
      let name = m.captures.at(3)
      let cls-type = if is-abstract { "abstract" } else if keyword == "@interface" { "annotation" } else { keyword }

      let is-opening = line.contains("{")

      let cls = ir.uml-class(name: name, type: cls-type, level: layout-level, order: layout-order)
      current-class = cls
      current-members = ()
      layout-level = none
      layout-order = none

      // Parse extends and implements
      let after-name = line.slice(m.end)
      let extends-match = after-name.match(regex("extends\\s+([A-Z][\\w.]*)"))
      if extends-match != none {
        let parentName = extends-match.captures.at(0)
        relations.push(ir.uml-relation(from: name, to: parentName, type: "inheritance"))
      }
      
      let implements-match = after-name.match(regex("implements\\s+([^{]+)"))
      if implements-match != none {
        let implsStr = implements-match.captures.at(0)
        let impls = implsStr.split(",").map(s => s.trim())
        for impl in impls {
          if impl != "" {
            relations.push(ir.uml-relation(from: name, to: impl, type: "implementation"))
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
