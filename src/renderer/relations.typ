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
    end-mark: ">",
    end-fill: auto,
    start-fill: none,
  ),
  dependency: (
    dash: "dashed",
    start-mark: none,
    end-mark: ">",
    end-fill: auto,
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

/// Compute best anchors using 8-direction mapping.
/// Returns: (from-anchor-suffix, to-anchor-suffix)
#let _compute-anchors(from-pos, to-pos) = {
  let dx = to-pos.at(0) - from-pos.at(0)
  let dy = to-pos.at(1) - from-pos.at(1)
  let adx = calc.abs(dx)
  let ady = calc.abs(dy)

  // Determine direction ratio
  let ratio = if adx > 0.01 { ady / adx } else { 100.0 }

  if ratio > 2.0 {
    // Primarily vertical
    if dy > 0 {
      ("north", "south")
    } else {
      ("south", "north")
    }
  } else if ratio < 0.5 {
    // Primarily horizontal
    if dx > 0 {
      ("east", "west")
    } else {
      ("west", "east")
    }
  } else {
    // Diagonal — use corner anchors
    if dx > 0 and dy > 0 {
      ("north-east", "south-west")
    } else if dx > 0 and dy < 0 {
      ("south-east", "north-west")
    } else if dx < 0 and dy > 0 {
      ("north-west", "south-east")
    } else {
      ("south-west", "north-east")
    }
  }
}

/// Draw a single UML relation in the CeTZ canvas.
///
/// - rel (dict): A uml-relation dictionary
/// - from-pos (tuple): (x, y) position of the source class
/// - to-pos (tuple): (x, y) position of the target class
/// - theme (dict): The active theme
#let draw-relation(rel, from-pos, to-pos, theme) = {
  let style = _relation-styles.at(
    rel.type,
    default: _relation-styles.at("link"),
  )

  // Compute anchors
  let (from-anchor, to-anchor) = _compute-anchors(from-pos, to-pos)
  let from-point = rel.from + "." + from-anchor
  let to-point = rel.to + "." + to-anchor

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

  // Draw the line
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

  // --- Labels and cardinalities ---

  // Midpoint for label
  if rel.label != none {
    let mid-x = (from-pos.at(0) + to-pos.at(0)) / 2
    let mid-y = (from-pos.at(1) + to-pos.at(1)) / 2
    // Offset label slightly above the line
    let offset-y = 0.3
    cetz.draw.content(
      (mid-x, mid-y + offset-y),
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
