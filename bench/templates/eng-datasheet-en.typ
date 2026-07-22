// Component Datasheet
// @description: Technical datasheet for electronic components with specifications and tables
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration
#let accent = rgb("#004a99")
#let text-main = "Libertinus Serif"
#let text-sans = "Adwaita Sans"
#let text-mono = "Cousine"

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
)
#set text(font: text-main, size: 10pt)

// Header Section
#let mfg-name = g("manufacturer.name", default: "Manufacturer")
#let mfg-initials = upper(mfg-name.clusters().slice(0, calc.min(2, mfg-name.clusters().len())).join(""))

#grid(
  columns: (auto, 1fr),
  column-gutter: 20pt,
  // Logo Box
  box(fill: accent, inset: 8pt, radius: 2pt, width: 45pt, height: 45pt)[
    #set align(center + horizon)
    #text(fill: white, weight: "bold", size: 18pt)[#mfg-initials]
  ],
  // Part Info
  align(left)[
    #text(font: text-sans, size: 22pt, weight: "bold", fill: accent)[#g("part.number", default: "PART-NUMBER")] \
    #text(font: text-sans, size: 12pt, fill: gray.darken(50%))[#g("part.title", default: "Component Title")]
  ]
)

#v(5pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(10pt)

// Meta Bar
#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  text(font: text-sans, size: 8pt, weight: "bold", fill: accent)[STATUS: #g("part.status", default: "—")],
  text(font: text-sans, size: 8pt, weight: "bold", fill: accent)[PACKAGE: #g("part.package", default: "—")],
  text(font: text-sans, size: 8pt, weight: "bold", fill: accent)[REV: #g("part.rev", default: "—")],
  align(right, text(font: text-sans, size: 8pt, fill: gray.darken(50%))[#g("part.date", default: "")]),
)

#v(15pt)

// Two Column Layout for Features/Applications
#grid(
  columns: (1fr, 1fr),
  column-gutter: 30pt,
  [
    #text(font: text-sans, weight: "bold", size: 11pt, fill: accent)[FEATURES]
    #v(4pt)
    #let features = data.at("features", default: ())
    #if features.len() > 0 {
      list(..features.map(it => text(size: 9pt)[#it]))
    } else {
      text(size: 9pt, style: "italic")[No features listed.]
    }
  ],
  [
    #text(font: text-sans, weight: "bold", size: 11pt, fill: accent)[APPLICATIONS]
    #v(4pt)
    #let apps = data.at("applications", default: ())
    #if apps.len() > 0 {
      list(..apps.map(it => text(size: 9pt)[#it]))
    } else {
      text(size: 9pt, style: "italic")[No applications listed.]
    }
  ]
)

#v(20pt)

// Absolute Maximum Ratings
#text(font: text-sans, weight: "bold", size: 12pt, fill: accent)[ABSOLUTE MAXIMUM RATINGS]
#v(5pt)
#let abs_max = data.at("abs_max", default: ())
#if abs_max.len() > 0 {
  table(
    columns: (1fr, auto, auto, auto),
    stroke: none,
    inset: 5pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      align(left)[#text(font: text-sans, weight: "bold")[Parameter]],
      align(center)[#text(font: text-sans, weight: "bold")[Symbol]],
      align(center)[#text(font: text-sans, weight: "bold")[Min]],
      align(right)[#text(font: text-sans, weight: "bold")[Max / Unit]],
    ),
    ..abs_max.map(it => (
      [#it.at("parameter", default: "")],
      [#it.at("symbol", default: "")],
      [#it.at("min", default: "—")],
      [#it.at("max", default: "—") #it.at("unit", default: "")]
    )).flatten()
  )
}

#v(20pt)

// Electrical Characteristics
#text(font: text-sans, weight: "bold", size: 12pt, fill: accent)[ELECTRICAL CHARACTERISTICS]
#v(5pt)
#let characteristics = data.at("characteristics", default: ())
#if characteristics.len() > 0 {
  table(
    columns: (1.5fr, auto, auto, auto, auto, auto),
    stroke: none,
    inset: 5pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      align(left)[#text(font: text-sans, weight: "bold")[Parameter]],
      align(center)[#text(font: text-sans, weight: "bold")[Sym]],
      align(center)[#text(font: text-sans, weight: "bold")[Min]],
      align(center)[#text(font: text-sans, weight: "bold")[Typ]],
      align(center)[#text(font: text-sans, weight: "bold")[Max]],
      align(right)[#text(font: text-sans, weight: "bold")[Unit]],
    ),
    ..characteristics.map(it => (
      [#it.at("parameter", default: "") \ #text(size: 7pt, fill: gray)[#it.at("condition", default: "")]],
      [#it.at("symbol", default: "")],
      [#it.at("min", default: "—")],
      [#it.at("typ", default: "—")],
      [#it.at("max", default: "—")],
      [#it.at("unit", default: "")]
    )).flatten()
  )
}

#v(20pt)

// Ordering Information
#text(font: text-sans, weight: "bold", size: 12pt, fill: accent)[ORDERING INFORMATION]
#v(5pt)
#let ordering = data.at("ordering", default: ())
#if ordering.len() > 0 {
  table(
    columns: (1fr, 1fr, 2fr),
    stroke: none,
    inset: 5pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      align(left)[#text(font: text-sans, weight: "bold")[Order Code]],
      align(left)[#text(font: text-sans, weight: "bold")[Temp Range]],
      align(left)[#text(font: text-sans, weight: "bold")[Packing]],
    ),
    ..ordering.map(it => (
      [#text(font: text-mono, weight: "bold")[#it.at("code", default: "")]],
      [#it.at("temp_range", default: "—")],
      [#it.at("packing", default: "—")],
    )).flatten()
  )
}

#v(30pt)

// Footer
#set align(center)
#line(length: 100%, stroke: 0.5pt + gray)
#v(5pt)
#text(size: 8pt, fill: gray.darken(50%))[
  #g("manufacturer.name", default: "Manufacturer") | #g("part.number", default: "Part Number") \
  #g("manufacturer.website", default: "")
]
