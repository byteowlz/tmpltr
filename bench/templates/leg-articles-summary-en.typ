// Articles of Incorporation Summary
// @description: Company formation summary: shares, directors, registered agent
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)

// Use Tinos for a formal, legal serif look
#set text(font: "Tinos", size: 11pt, lang: "en")
#set par(justify: true)

// Accent color: Deep Navy/Slate for legal documents
#let accent = rgb("#2c3e50")

// Header: Formal Title
#align(center)[
  #text(size: 18pt, weight: "bold", fill: accent)[CERTIFICATE OF INCORPORATION SUMMARY] \
  #v(4pt)
  #line(length: 100%, stroke: 1pt + accent)
]

#v(12pt)

// Company Identity Block
#block(width: 100%, inset: 10pt, fill: rgb("#f8f9fa"), radius: 2pt)[
  #grid(columns: (1fr, auto),
    [
      #text(size: 14pt, weight: "bold")[#g("company.name", default: "Unnamed Corporation")] \
      #text(size: 11pt, fill: gray.darken(50%))[Jurisdiction: #g("company.state", default: "—")]
    ],
    align(right)[
      #text(size: 10pt, weight: "bold")[Formation Date] \
      #text(size: 10pt)[#g("company.formation_date", default: "—")]
    ]
  )
]

#v(12pt)

// Registered Agent Section
#text(size: 12pt, weight: "bold", fill: accent)[REGISTERED AGENT]
#v(4pt)
#grid(columns: (auto, 1fr), column-gutter: 10pt,
  [#text(weight: "bold")[Name:]], [#g("company.registered_agent", default: "—")],
  [#text(weight: "bold")[Address:]], [#g("agent_address", default: "—")]
)

#v(18pt)

// Capitalization / Shares Section
#text(size: 12pt, weight: "bold", fill: accent)[AUTHORIZED CAPITALIZATION]
#v(4pt)
#table(
  columns: (1fr, 1fr),
  stroke: none,
  inset: 6pt,
  fill: (x, y) => if y == 0 { rgb("#eceff1") } else { white },
  table.header(
    [#text(weight: "bold")[Metric]], [#text(weight: "bold")[Details]]
  ),
  [Total Authorized Shares], [#g("shares.authorized", default: "—")],
  [Par Value], [#g("shares.par_value", default: "—")],
)

#v(8pt)
#text(size: 10pt, weight: "bold", fill: gray.darken(50%))[CLASS BREAKDOWN]

// Fixed: Use 'dictionary' type instead of 'dict'
#let shares_data = data.at("shares", default: ())
#let classes = if type(shares_data) == dictionary { shares_data.at("classes", default: ()) } else { () }

#if type(classes) == array and classes.len() > 0 {
  list(..classes.map(c => [ #c ]))
} else {
  [No class breakdown provided.]
}

#v(18pt)

// Board of Directors
#text(size: 12pt, weight: "bold", fill: accent)[BOARD OF DIRECTORS]
#v(4pt)
#let directors = data.at("directors", default: ())
#if type(directors) == array and directors.len() > 0 {
  for (i, d) in directors.enumerate() {
    // Ensure d is a dictionary before calling .at
    let name = if type(d) == dictionary { d.at("name", default: "Unknown") } else { "Unknown" }
    let addr = if type(d) == dictionary { d.at("address", default: "") } else { "" }
    block(width: 100%)[
      #text(weight: "bold")[#name] \
      #text(size: 10pt, style: "italic")[#addr]
    ]
    if i < directors.len() - 1 { v(6pt) }
  }
} else {
  [No directors listed.]
}

#v(24pt)

// Execution / Incorporator
#line(length: 100%, stroke: 0.5pt + gray)
#v(8pt)
#grid(columns: (1fr, 1fr),
  [
    #text(size: 10pt, weight: "bold", fill: accent)[INCORPORATOR] \
    #v(2pt)
    #g("incorporator.name", default: "—")
  ],
  align(right)[
    #text(size: 10pt, weight: "bold", fill: accent)[DATE OF EXECUTION] \
    #v(2pt)
    #g("incorporator.signed_date", default: "—")
  ]
)

#v(40pt)

// Footer Disclaimer
#align(center)[
  #set text(size: 8pt, fill: gray.darken(50%))
  #text(style: "italic")[This document is a summary for informational purposes only and does not constitute legal advice or a complete copy of the filed Articles of Incorporation.]
]
