// =============================================================================
// Example Template (tmpltr edition)
//
// A simple template demonstrating tmpltr features.
// Usage: tmpltr compile example-content.toml -o output.pdf
// =============================================================================

#import "@local/tmpltr-lib:1.0.0": tmpltr-data, editable, get, brand-color, brand-logo-image, brand-font

// =============================================================================
// TEMPLATE FUNCTION
// =============================================================================

#let example-template(data, doc) = {
  // Brand configuration with safe defaults
  let colors = (
    primary: brand-color(data, "primary", default: "#0f172a"),
    accent: brand-color(data, "accent", default: "#38bdf8"),
    text: brand-color(data, "text", default: "#000000"),
  )
  
  let primary-font = brand-font(data, usage: "body", default: "Arial")
  
  // Page setup
  set page(
    paper: "a4",
    margin: 2.5cm,
  )
  
  // Typography
  set text(
    font: primary-font,
    size: 11pt,
    fill: rgb(colors.text),
  )
  
  set par(
    justify: true,
    leading: 0.65em,
  )
  
  // Header with logo
  grid(
    columns: (1fr, auto),
    align(left)[
      #text(size: 18pt, weight: "bold")[
        #editable("title", get(data, "title", default: "Document Title"))
      ]
    ],
    brand-logo-image(data, width: 3cm),
  )
  
  v(1cm)
  line(length: 100%, stroke: 0.5pt + rgb(colors.primary))
  v(1cm)
  
  // Document content
  doc
}

// =============================================================================
// APPLY TEMPLATE
// =============================================================================

#let data = tmpltr-data()
#show: doc => example-template(data, doc)
