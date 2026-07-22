// Laboratory Report
// @description: Blood panel with analyte table, reference ranges, flags
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let accent = rgb("#00695c")
#let hi = rgb("#c62828")
#let lo = rgb("#1565c0")

#let results = data.at("results", default: ())

#let flag-cell(f) = {
  if f == "H" or f == "HH" { text(fill: hi, weight: "bold")[#f] } else if f == "L" or f == "LL" { text(fill: lo, weight: "bold")[#f] } else { [] }
}

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, x: 1.9cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.5pt + accent)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [#g("lab.name") · CLIA \#34D0655219 · Laboratory Director: #g("lab.director")],
      [Page 1 of 1])
  ])
#set text(font: "Arimo", size: 9.5pt)

// Header
#grid(columns: (auto, 1fr), column-gutter: 12pt,
  box(fill: accent, inset: (x: 9pt, y: 8pt), radius: 2pt)[
    #text(fill: white, weight: "bold", size: 15pt)[MCL]
  ],
  [
    #text(weight: "bold", size: 13pt, fill: accent)[#g("lab.name")] \
    #text(size: 8.5pt)[#g("lab.address") · Tel #g("lab.phone")]
  ])
#v(4pt)
#line(length: 100%, stroke: 2pt + accent)
#v(6pt)
#align(center)[#text(weight: "bold", size: 12pt, tracking: 1.5pt)[LABORATORY REPORT]]
#v(8pt)

// Patient / order block
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  box(stroke: 0.6pt + gray.darken(20%), inset: 8pt, radius: 2pt, width: 100%)[
    #text(size: 7.5pt, fill: accent, weight: "bold")[PATIENT] \
    #v(2pt)
    #grid(columns: (auto, 1fr), column-gutter: 8pt, row-gutter: 3.5pt,
      text(size: 8.5pt, fill: gray.darken(40%))[Name], text(weight: "bold")[#g("patient.name")],
      text(size: 8.5pt, fill: gray.darken(40%))[DOB], [#g("patient.dob")],
      text(size: 8.5pt, fill: gray.darken(40%))[Sex], [#g("patient.sex")],
      text(size: 8.5pt, fill: gray.darken(40%))[Patient ID], [#g("patient.id")])
  ],
  box(stroke: 0.6pt + gray.darken(20%), inset: 8pt, radius: 2pt, width: 100%)[
    #text(size: 7.5pt, fill: accent, weight: "bold")[ORDER] \
    #v(2pt)
    #grid(columns: (auto, 1fr), column-gutter: 8pt, row-gutter: 3.5pt,
      text(size: 8.5pt, fill: gray.darken(40%))[Physician], [#g("order.physician")],
      text(size: 8.5pt, fill: gray.darken(40%))[Practice], [#g("order.practice")],
      text(size: 8.5pt, fill: gray.darken(40%))[Collected], [#g("order.date_collected")],
      text(size: 8.5pt, fill: gray.darken(40%))[Reported], [#g("order.date_reported")])
  ])
#v(4pt)
#text(size: 8.5pt)[*Specimen:* #g("order.specimen", default: "—")]
#v(10pt)

// Results table
#if results.len() > 0 {
  table(
    columns: (2.4fr, auto, auto, auto, 1.4fr),
    align: (left, right, center, left, left),
    inset: (x: 7pt, y: 5pt),
    stroke: (x, y) => if y == 0 { (bottom: 1.2pt + accent) } else { (bottom: 0.4pt + gray.lighten(40%)) },
    fill: (_, row) => if row == 0 { rgb("#e0f2f1") } else { white },
    table.header(
      text(weight: "bold", size: 8.5pt)[ANALYTE],
      text(weight: "bold", size: 8.5pt)[RESULT],
      text(weight: "bold", size: 8.5pt)[FLAG],
      text(weight: "bold", size: 8.5pt)[UNITS],
      text(weight: "bold", size: 8.5pt)[REFERENCE RANGE]),
    ..results.map(r => {
      let f = r.at("flag", default: "")
      let abn = f != ""
      (
        [#r.at("analyte", default: "")],
        if abn { text(weight: "bold")[#r.at("value", default: "")] } else { [#r.at("value", default: "")] },
        flag-cell(f),
        text(size: 8.5pt)[#r.at("unit", default: "")],
        text(size: 8.5pt, fill: gray.darken(45%))[#r.at("reference", default: "")],
      )
    }).flatten()
  )
} else {
  text(fill: gray, style: "italic")[No results available for this order.]
}
#v(6pt)
#text(size: 7.5pt, fill: gray.darken(30%))[Flags: H = above reference range · L = below reference range. Reference intervals apply to adult population unless otherwise noted.]
#v(10pt)

// Comment
#if g("comment") != "" [
  #box(fill: rgb("#f1f8f6"), stroke: (left: 2.5pt + accent), inset: 9pt, width: 100%)[
    #text(size: 8pt, weight: "bold", fill: accent)[PATHOLOGIST COMMENT] \
    #v(2pt)
    #text(size: 9pt)[#g("comment")]
  ]
]
#v(14pt)
#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [],
  align(center)[
    #line(length: 85%, stroke: 0.6pt)
    #text(size: 8pt)[#g("lab.director") — Laboratory Director] \
    #text(size: 7.5pt, fill: gray.darken(30%))[Electronically verified #g("order.date_reported")]
  ])
