// =============================================================================
// tmpltr Helper Library for Typst Templates
// Version: 1.0.0
//
// This library provides helper functions for tmpltr templates to:
// - Parse data from CLI input
// - Access brand configuration (colors, logos, fonts)
// - Mark editable fields and blocks
// - Render markdown content
// =============================================================================

// -----------------------------------------------------------------------------
// DATA ACCESS
// -----------------------------------------------------------------------------

/// Get parsed data from tmpltr CLI input.
/// Returns empty dictionary if no data is provided.
#let tmpltr-data() = {
  let raw = sys.inputs.at("data", default: "{}")
  // Modern Typst: pass bytes directly to json() instead of using json.decode()
  json(bytes(raw))
}

/// Safely get a nested value from data using dot-path notation.
/// Example: get(data, "workshop.title", default: "Untitled")
#let get(data, path, default: none) = {
  let parts = if type(path) == str { path.split(".") } else { path }
  let current = data
  
  for part in parts {
    if type(current) == dictionary {
      current = current.at(part, default: none)
      if current == none {
        return default
      }
    } else {
      return default
    }
  }
  
  if current == none { default } else { current }
}

// -----------------------------------------------------------------------------
// BRAND HELPERS
// -----------------------------------------------------------------------------

/// Get a brand color by name with fallback.
/// Example: brand-color(data, "primary", default: "#000000")
#let brand-color(data, name, default: "#000000") = {
  let colors = get(data, "brand.colors", default: (:))
  colors.at(name, default: default)
}

/// Get logo path for a variant with fallback.
/// Example: brand-logo(data, variant: "primary", default: none)
#let brand-logo(data, variant: "primary", default: none) = {
  let logos = get(data, "brand.logos", default: (:))
  logos.at(variant, default: default)
}

/// Render a brand logo image with fallback placeholder.
/// Example: brand-logo-image(data, variant: "primary", width: 4cm)
#let brand-logo-image(data, variant: "primary", width: 4cm, fallback: none) = {
  let logo-path = brand-logo(data, variant: variant, default: none)
  
  if logo-path != none {
    image(logo-path, width: width)
  } else if fallback != none {
    fallback
  } else {
    // Default placeholder
    rect(
      width: width,
      height: width * 0.4,
      stroke: 0.5pt + luma(200),
      inset: 4pt,
      align(center + horizon)[
        #text(fill: luma(150), size: 9pt)[\[Logo\]]
      ]
    )
  }
}

/// Get font family for a usage category with fallback.
/// Example: brand-font(data, usage: "body", default: "Arial")
#let brand-font(data, usage: "body", default: "Arial") = {
  let typography = get(data, "brand.typography", default: (:))
  let font-config = typography.at(usage, default: (:))
  
  if type(font-config) == dictionary {
    font-config.at("family", default: default)
  } else if type(font-config) == str {
    font-config
  } else {
    default
  }
}

/// Get contact information field with fallback.
/// Example: brand-contact(data, "email", default: "")
#let brand-contact(data, field, default: "") = {
  let contact = get(data, "brand.contact", default: (:))
  contact.at(field, default: default)
}

// -----------------------------------------------------------------------------
// EDITABLE FIELDS
// -----------------------------------------------------------------------------

/// Mark an inline field as editable (for future editor integration).
/// Currently renders the value directly.
/// Example: editable("workshop.title", "Meeting Title", type: "text")
#let editable(id, value, type: "text", default: none) = {
  let display-value = if value == none or value == "" { default } else { value }
  display-value
}

/// Mark a content block as editable (for future editor integration).
/// Currently renders the body directly.
/// Example: editable-block("intro", "Introduction", format: "markdown")[Content here]
#let editable-block(id, title: none, format: "text", body) = {
  if title != none {
    [*#title*]
    linebreak()
  }
  body
}

// -----------------------------------------------------------------------------
// MARKDOWN RENDERING
// -----------------------------------------------------------------------------

/// Render markdown content (already converted to Typst by tmpltr).
/// This is a passthrough for pre-processed content.
#let md(content) = {
  if type(content) == str {
    eval(content, mode: "markup")
  } else {
    content
  }
}

// -----------------------------------------------------------------------------
// TABLE RENDERING
// -----------------------------------------------------------------------------

/// Render a table from block data.
/// Expects a dictionary with "columns" (array of headers) and "rows" (array of arrays).
/// Example: render-table(get(data, "blocks.timeline"))
#let render-table(block-data) = {
  if block-data == none {
    return []
  }
  
  let columns = block-data.at("columns", default: ())
  let rows = block-data.at("rows", default: ())
  
  if columns.len() == 0 {
    return []
  }
  
  table(
    columns: columns.len() * (1fr,),
    stroke: 0.5pt,
    // Header row
    ..columns.map(c => [*#c*]),
    // Data rows
    ..rows.flatten().map(cell => [#cell])
  )
}
