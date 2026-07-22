// Engineering Change Order
// @description: ECO with affected items, reason, disposition, approval chain
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm),
)

// Engineering documents look best with technical, clean fonts. 
// Using Cousine for data/mono elements and Arimo for body.
#set text(font: "Arimo", size: 9pt, lang: "en")

// Colors for a technical form
#let primary-color = rgb("#2c3e50")
#let secondary-color = rgb("#ecf0f1")
#let accent-color = rgb("#2980b9")
#let border-color = rgb("#bdc3c7")

// Header Section
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(size: 18pt, weight: "bold", fill: primary-color)[ENGINEERING CHANGE ORDER] \
    #text(size: 11pt, fill: accent-color)[#g("company.name", default: "—")] \
    #text(size: 9pt, fill: gray.darken(50%))[#g("company.site", default: "—")]
  ],
  [
    #rect(fill: primary-color, inset: 6pt, radius: 0pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#g("eco.number", default: "N/A")]
    ]
  ]
)

#v(4pt)
#line(length: 100%, stroke: 1.5pt + primary-color)
#v(10pt)

// Metadata Grid
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 8pt,
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[ECO TITLE] \
    #text(weight: "medium")[#g("eco.title", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[ORIGINATOR] \
    #text(weight: "medium")[#g("eco.originator", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[DATE ISSUED] \
    #text(weight: "medium")[#g("eco.date", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[PRIORITY] \
    #text(weight: "bold", fill: if g("eco.priority", default: "") == "High" { red } else { black })[#g("eco.priority", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[EFFECTIVE DATE] \
    #text(weight: "medium")[#g("eco.effective_date", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[STATUS] \
    #text(weight: "medium")[#g("eco.status", default: "Draft")]
  ]
)

#v(12pt)

// Change Details
#block(fill: secondary-color, inset: 8pt, radius: 2pt, width: 100%)[
  #text(weight: "bold", size: 10pt, fill: primary-color)[1. CHANGE DESCRIPTION & REASON]
  #v(4pt)
  #text(weight: "bold", size: 8pt)[REASON FOR CHANGE:] \
  #text(style: "italic")[#g("eco.reason", default: "—")]
  
  #v(6pt)
  #text(weight: "bold", size: 8pt)[DETAILED DESCRIPTION:] \
  #g("eco.description", default: "—")
]

#v(12pt)

// Disposition
#grid(
  columns: (1fr, 1fr),
  column-gutter: 15pt,
  [
    #text(weight: "bold", size: 10pt, fill: primary-color)[2. STOCK DISPOSITION] \
    #v(2pt)
    #text(size: 8pt, weight: "bold")[Existing Inventory:] \
    #text(size: 8pt)[#g("eco.disposition_stock", default: "—")]
  ],
  [
    #text(weight: "bold", size: 10pt, fill: primary-color)[3. WIP DISPOSITION] \
    #v(2pt)
    #text(size: 8pt, weight: "bold")[Work In Progress:] \
    #text(size: 8pt)[#g("eco.disposition_wip", default: "—")]
  ]
)

#v(15pt)

// Affected Items Table
#text(weight: "bold", size: 10pt, fill: primary-color)[4. AFFECTED PARTS / COMPONENTS]
#v(4pt)

#let affected = data.at("affected", default: ())
#if affected.len() > 0 {
  table(
    columns: (1fr, 2fr, auto, auto),
    stroke: 0.5pt + border-color,
    inset: 6pt,
    fill: (x, y) => if y == 0 { secondary-color } else { white },
    align: (left, left, center, center),
    [*Part Number*], [*Description*], [*From Rev*], [*To Rev*],
    ..affected.map(it => (
      it.at("part_number", default: "—"),
      it.at("description", default: "—"),
      it.at("from_rev", default: "—"),
      it.at("to_rev", default: "—"),
    )).flatten()
  )
} else {
  rect(width: 100%, stroke: 0.5pt + border-color, inset: 10pt)[#text(fill: gray)[No affected parts listed.]]
}

#v(15pt)

// Approval Chain
#text(weight: "bold", size: 10pt, fill: primary-color)[5. APPROVAL SIGN-OFF]
#v(4pt)

#let approvals = data.at("approvals", default: ())
#if approvals.len() > 0 {
  table(
    columns: (2fr, 2fr, 1fr, 1fr),
    stroke: 0.5pt + border-color,
    inset: 6pt,
    align: (left, left, center, center),
    fill: (x, y) => if y == 0 { secondary-color } else { white },
    [*Role*], [*Name*], [*Status*], [*Date*],
    ..approvals.map(it => {
      let role = it.at("role", default: "—")
      let name = it.at("name", default: "—")
      let st = it.at("status", default: "—")
      let date = it.at("date", default: "—")
      
      // Status styling logic moved inside the map block to return a single array of elements
      let status-content = if st == "Approved" { 
        text(fill: green.darken(20%), weight: "bold")[#st] 
      } else if st == "Rejected" { 
        text(fill: red.darken(20%), weight: "bold")[#st] 
      } else { 
        text(fill: orange.darken(20%), weight: "bold")[#st] 
      }
      
      (role, name, status-content, date)
    }).flatten()
  )
} else {
  text(fill: gray)[No approvals recorded.]
}

#v(20pt)

// Footer
#align(center)[
  #set text(size: 7pt, fill: gray)
  #line(length: 100%, stroke: 0.25pt + gray)
  #v(2pt)
  Controlled Document - Engineering Change Management System - Page 1 of 1
]
