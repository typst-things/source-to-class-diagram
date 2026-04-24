// =============================================================================
// cetz-classuml — Relation Renderer
// =============================================================================
// Draws UML relations (arrows, lines) between class boxes using CeTZ.

#import "../deps.typ": cetz

/// Style lookup for each relation type.
#let _relation-styles = (
  inheritance: (
    dash: none,
    start-mark: none,
    end-mark: "triangle",
    end-fill: white,
    start-fill: none,
  ),
  implementation: (
    dash: "dashed",
    start-mark: none,
    end-mark: "triangle",
    end-fill: white,
    start-fill: none,
  ),
  composition: (
    dash: none,
    start-mark: "diamond",
    end-mark: none,
    start-fill: black,
    end-fill: none,
  ),
  aggregation: (
    dash: none,
    start-mark: "diamond",
    end-mark: none,
    start-fill: white,
    end-fill: none,
  ),
  association: (
    dash: none,
    start-mark: none,
    end-mark: "straight",
    end-fill: none,
    start-fill: none,
  ),
  dependency: (
    dash: "dashed",
    start-mark: none,
    end-mark: "straight",
    end-fill: none,
    start-fill: none,
  ),
  link: (
    dash: none,
    start-mark: none,
    end-mark: none,
    start-fill: none,
    end-fill: none,
  ),
  dashed-link: (
    dash: "dashed",
    start-mark: none,
    end-mark: none,
    start-fill: none,
    end-fill: none,
  ),
)

/// Draw a single UML relation in the CeTZ canvas.
///
/// - rel (dict): A uml-relation dictionary
/// - from-pos (tuple): (x, y) position of the source class
/// - to-pos (tuple): (x, y) position of the target class
/// - theme (dict): The active theme
#let draw-relation(rel, from-pos, to-pos, theme, positions) = {
  let style = _relation-styles.at(
    rel.type,
    default: _relation-styles.at("link"),
  )

  // Detect if there are physical obstacle classes between the endpoints
  let is-horizontal = calc.abs(from-pos.at(1) - to-pos.at(1)) < 0.1
  let bridge = false
  
  if is-horizontal {
    let min-x = calc.min(from-pos.at(0), to-pos.at(0))
    let max-x = calc.max(from-pos.at(0), to-pos.at(0))
    for (name, pos) in positions {
      if name != rel.from and name != rel.to {
        if calc.abs(pos.at(1) - from-pos.at(1)) < 0.1 {
          if pos.at(0) > min-x + 0.1 and pos.at(0) < max-x - 0.1 {
            bridge = true
          }
        }
      }
    }
  }

  // Use base node names for native clipping, or top border for bridges
  let from-point = if bridge { rel.from + ".north" } else { rel.from }
  let to-point = if bridge { rel.to + ".north" } else { rel.to }

  // Build stroke
  let rel-stroke = if style.dash != none {
    (paint: theme.relation.color, thickness: theme.relation.stroke-thickness, dash: style.dash)
  } else {
    (paint: theme.relation.color, thickness: theme.relation.stroke-thickness)
  }

  // Build mark config
  let mark-cfg = (:)
  if style.start-mark != none {
    mark-cfg.insert("start", style.start-mark)
  }
  if style.end-mark != none {
    mark-cfg.insert("end", style.end-mark)
  }

  // Determine fill for marks
  if style.start-fill != none and style.start-fill != auto {
    mark-cfg.insert("fill", style.start-fill)
  } else if style.end-fill != none and style.end-fill != auto {
    mark-cfg.insert("fill", style.end-fill)
  }

  if mark-cfg.len() > 0 {
    mark-cfg.insert("size", 0.35)
    mark-cfg.insert("stroke", (paint: theme.relation.color, thickness: theme.relation.stroke-thickness))
  }

  let mid-x = (from-pos.at(0) + to-pos.at(0)) / 2
  let mid-y = (from-pos.at(1) + to-pos.at(1)) / 2
  let bridge-y = mid-y + 2.5 // push arc up by 2.5 units

  // Draw the line
  if bridge {
    if mark-cfg.len() > 0 {
      cetz.draw.bezier-through(from-point, (mid-x, bridge-y), to-point, stroke: rel-stroke, mark: mark-cfg)
    } else {
      cetz.draw.bezier-through(from-point, (mid-x, bridge-y), to-point, stroke: rel-stroke)
    }
  } else {
    if mark-cfg.len() > 0 {
      cetz.draw.line(
        from-point,
        to-point,
        stroke: rel-stroke,
        mark: mark-cfg,
      )
    } else {
      cetz.draw.line(
        from-point,
        to-point,
        stroke: rel-stroke,
      )
    }
  }

  // --- Labels and cardinalities ---

  // Midpoint for label
  if rel.label != none {
    let offset-y = 0.3
    let target-y = if bridge { bridge-y + offset-y } else { mid-y + offset-y }
    cetz.draw.content(
      (mid-x, target-y),
      anchor: "south",
      text(size: theme.relation.label-size, style: "italic")[#rel.label],
    )
  }

  // From cardinality (near the source endpoint)
  if rel.from-card != none {
    // Position ~20% from the source along the line, offset perpendicular
    let card-x = from-pos.at(0) + (to-pos.at(0) - from-pos.at(0)) * 0.15
    let card-y = from-pos.at(1) + (to-pos.at(1) - from-pos.at(1)) * 0.15
    let perp-offset = 0.3
    cetz.draw.content(
      (card-x + perp-offset, card-y + perp-offset),
      anchor: "south-west",
      text(size: theme.relation.card-size, weight: "bold")[#rel.from-card],
    )
  }

  // To cardinality (near the target endpoint)
  if rel.to-card != none {
    let card-x = to-pos.at(0) + (from-pos.at(0) - to-pos.at(0)) * 0.15
    let card-y = to-pos.at(1) + (from-pos.at(1) - to-pos.at(1)) * 0.15
    let perp-offset = 0.3
    cetz.draw.content(
      (card-x + perp-offset, card-y + perp-offset),
      anchor: "south-west",
      text(size: theme.relation.card-size, weight: "bold")[#rel.to-card],
    )
  }
}
