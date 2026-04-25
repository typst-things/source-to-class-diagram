// =============================================================================
// cetz-classuml — Layout Engine
// =============================================================================
// Hierarchical grid layout with size-aware spacing.
// Places parent classes at the top, children below, avoids overlap.

/// Estimate the width of a class box in CeTZ units (~1 unit ≈ 1cm).
/// Based on the longest text line in the class.
#let _estimate-width(cls) = {
  let max-len = cls.name.len() + 4 // name + some padding for bold

  // Check stereotype / type label
  if cls.stereotype != none { max-len = calc.max(max-len, cls.stereotype.len() + 4) }
  if cls.type == "interface" or cls.type == "enum" or cls.type == "annotation" {
    max-len = calc.max(max-len, cls.name.len() + 6)
  }

  for m in cls.members {
    let member-len = 2 // visibility symbol + space
    member-len += m.name.len()
    if m.kind == "method" {
      member-len += 2 // parentheses
      if m.params != none { member-len += m.params.len() }
    }
    if m.return-type != none { member-len += m.return-type.len() + 2 } // ": Type"
    if member-len > max-len { max-len = member-len }
  }

  // 9pt Consolas: ~5.4pt/char ≈ 0.20cm/char + inset padding (~1.2cm total)
  calc.max(max-len * 0.20 + 1.2, 3.0)
}

/// Estimate the height of a class box in CeTZ units.
/// Based on the number of members.
#let _estimate-height(cls) = {
  let lines = 1.0 // header (name)
  if cls.stereotype != none or cls.type != "class" { lines += 0.6 }
  if cls.generics != none { lines += 0.4 }

  let fields = cls.members.filter(m => m.kind == "field")
  let methods = cls.members.filter(m => m.kind == "method")

  if fields.len() > 0 { lines += fields.len() + 0.3 } // +0.3 for separator
  if methods.len() > 0 { lines += methods.len() + 0.3 }
  if fields.len() == 0 and methods.len() == 0 { lines += 0.3 }

  // ~0.55cm per line (9pt + padding) + box chrome
  calc.max(lines * 0.55 + 0.8, 2.0)
}

/// Compute positions for all classes based on their relations.
///
/// Strategy:
/// 1. Build hierarchy from inheritance/implementation.
/// 2. Assign levels via BFS (roots at level 0).
/// 3. Estimate box sizes to compute proper spacing.
/// 4. Distribute in a grid with enough room.
///
/// - ir (dict): The full IR diagram
/// - spacing (dict): (x: min-horizontal, y: min-vertical) spacing in CeTZ units
/// Returns: Dictionary of class-name → (x, y) position.
#let compute(ir, spacing: (x: 4.0, y: 3.5)) = {
  let classes = ir.classes
  let relations = ir.relations

  if classes.len() == 0 { return (:) }

  // --- 1. Build hierarchy ---
  let parent-map = (:) // child → array of parents
  let child-map = (:) // parent → array of children

  for rel in relations {
    if rel.type == "inheritance" or rel.type == "implementation" {
      // from = child, to = parent (normalized by parser)
      if rel.from not in parent-map { parent-map.insert(rel.from, ()) }
      parent-map.at(rel.from).push(rel.to)

      if rel.to not in child-map { child-map.insert(rel.to, ()) }
      child-map.at(rel.to).push(rel.from)
    }
  }

  // --- 2. Assign levels via BFS ---
  let levels = (:)
  let all-names = classes.map(c => c.name)

  // Roots: classes with no parents
  let roots = all-names.filter(n => n not in parent-map or parent-map.at(n).len() == 0)
  if roots.len() == 0 { roots = all-names }

  // BFS
  let queue = roots.map(r => (name: r, level: 0))
  let visited = ()

  while queue.len() > 0 {
    let entry = queue.remove(0)
    if entry.name not in visited {
      visited.push(entry.name)
      levels.insert(entry.name, entry.level)
      if entry.name in child-map {
        for child in child-map.at(entry.name) {
          if child not in visited {
            queue.push((name: child, level: entry.level + 1))
          }
        }
      }
    }
  }

  // Any unvisited → level 0
  for cls in classes {
    if cls.name not in levels { levels.insert(cls.name, 0) }
  }

  // --- 3. Estimate sizes and compute spacing ---
  let max-width = 2.5
  let max-height = 1.5
  for cls in classes {
    let w = _estimate-width(cls)
    let h = _estimate-height(cls)
    if w > max-width { max-width = w }
    if h > max-height { max-height = h }
  }

  // Actual spacing: at least (max-box-size + comfortable gap)
  let gap-x = 2.0 // minimum gap between boxes
  let gap-y = 2.0
  let actual-sx = calc.max(spacing.x, max-width + gap-x)
  let actual-sy = calc.max(spacing.y, max-height + gap-y)

  // --- 4. Group by level ---
  let max-level = 0
  for (_, level) in levels.pairs() {
    if level > max-level { max-level = level }
  }

  let level-groups = (:)
  for idx in range(max-level + 1) {
    level-groups.insert(str(idx), ())
  }
  for cls in classes {
    let level = levels.at(cls.name, default: 0)
    level-groups.at(str(level)).push(cls.name)
  }

  // --- 5. Compute positions using Tree layout ---
  let positions = (:)

  // Build strict tree
  let strict-children = (:)
  for cls in classes { strict-children.insert(cls.name, ()) }

  for cls in classes {
    let p = parent-map.at(cls.name, default: ())
    let cur-level = levels.at(cls.name, default: 0)
    let valid-p = p.filter(x => levels.at(x, default: -1) == cur-level - 1)
    if cur-level > 0 and valid-p.len() > 0 {
      strict-children.at(valid-p.first()).push(cls.name)
    }
  }

  // Bottom-up pass for subtree widths
  let subtree-width = (:)
  
  for level-idx in range(max-level, -1, step: -1) {
    let group = level-groups.at(str(level-idx), default: ())
    for name in group {
      let kids = strict-children.at(name, default: ())
      if kids.len() == 0 {
        subtree-width.insert(name, actual-sx)
      } else {
        let w = 0.0
        for k in kids { w += subtree-width.at(k, default: actual-sx) }
        subtree-width.insert(name, calc.max(actual-sx, w))
      }
    }
  }

  // Top-down pass for coordinate assignment
  let root-group = level-groups.at("0", default: ())
  let root-total-width = 0.0
  for r in root-group { root-total-width += subtree-width.at(r, default: actual-sx) }

  let current-x = -root-total-width / 2

  for r in root-group {
    let w = subtree-width.at(r, default: actual-sx)
    positions.insert(r, (current-x + w / 2, 0.0))
    current-x += w
  }

  for level-idx in range(1, max-level + 1) {
    let parent-group = level-groups.at(str(level-idx - 1), default: ())
    for name in parent-group {
      let kids = strict-children.at(name, default: ())
      if kids.len() > 0 {
        let parent-x = positions.at(name).at(0)
        let total-kid-w = 0.0
        for k in kids { total-kid-w += subtree-width.at(k, default: actual-sx) }
        
        let kid-start-x = parent-x - total-kid-w / 2
        for k in kids {
          let kw = subtree-width.at(k, default: actual-sx)
          let kx = kid-start-x + kw / 2
          let ky = -level-idx * actual-sy
          positions.insert(k, (kx, ky))
          kid-start-x += kw
        }
      }
    }
  }

  positions
}
