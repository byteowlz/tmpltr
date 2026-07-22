// System Access Request Form
// @description: Access request with systems, roles, approvals
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4", 
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm)
)

// Use Adwaita Sans for a modern, technical "IT Form" look
#set text(font: "Adwaita Sans", size: 10pt, weight: "regular")

// Theme Colors
#let primary = rgb("#2c3e50")
#let secondary = rgb("#7f8c8d")
#let accent = rgb("#2980b9")
#let border = rgb("#dcdde1")
#let bg-light = rgb("#f8f9fa")

// Header Section
#block(width: 100%, height: 12pt)
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(size: 18pt, weight: "bold", fill: primary)[SYSTEM ACCESS REQUEST] \
    #text(size: 10pt, fill: secondary)[Form ID: IT-REQ-#{g("request.id", default: "GENERIC")}]
  ],
  [
    #box(fill: primary, inset: 6pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 12pt)[
        #let req-name = g("requester.name", default: "··")
        #upper(req-name.clusters().slice(0, calc.min(2, req-name.clusters().len())).join(""))
      ]
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + primary)
#v(10pt)

// Requester Information Block
#text(weight: "bold", fill: primary, size: 11pt)[1. REQUESTER DETAILS]
#v(4pt)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 20pt,
  row-gutter: 8pt,
  [
    #text(size: 8pt, fill: secondary)[FULL NAME] \
    #text(weight: "medium")[#g("requester.name")]
  ],
  [
    #text(size: 8pt, fill: secondary)[EMPLOYEE ID] \
    #text(weight: "medium")[#g("requester.id")]
  ],
  [
    #text(size: 8pt, fill: secondary)[DEPARTMENT] \
    #text(weight: "medium")[#g("requester.department")]
  ],
  [
    #text(size: 8pt, fill: secondary)[LINE MANAGER] \
    #text(weight: "medium")[#g("requester.manager")]
  ]
)

#v(12pt)

// Request Metadata
#text(weight: "bold", fill: primary, size: 11pt)[2. ACCESS SPECIFICATIONS]
#v(4pt)
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  [
    #text(size: 8pt, fill: secondary)[REQUEST DATE] \
    #text(weight: "medium")[#g("request.date")]
  ],
  [
    #text(size: 8pt, fill: secondary)[DURATION] \
    #text(weight: "medium")[#g("request.duration")]
  ],
  [
    #text(size: 8pt, fill: secondary)[DATA CLASSIFICATION] \
    #text(weight: "medium")[#g("request.data_classification")]
  ]
)

#v(12pt)

// Systems Table
#text(weight: "bold", fill: primary, size: 11pt)[3. SYSTEM & ROLE REQUIREMENTS]
#v(4pt)

#let systems = data.at("systems", default: ())

#if systems.len() > 0 {
  table(
    columns: (1.5fr, 1.2fr, 2fr),
    stroke: none,
    inset: 8pt,
    fill: (x, y) => if y == 0 { bg-light } else { white },
    table.header(
      [#text(size: 8pt, fill: secondary)[SYSTEM NAME]],
      [#text(size: 8pt, fill: secondary)[ROLE/PERMISSIONS]],
      [#text(size: 8pt, fill: secondary)[JUSTIFICATION]]
    ),
    ..systems.map(it => (
      [#text(weight: "medium")[#it.at("system", default: "—")]],
      [#it.at("role", default: "—")],
      [#set text(size: 9pt); #it.at("justification", default: "—")]
    )).flatten()
  )
} else {
  block(fill: bg-light, width: 100%, inset: 10pt, radius: 2pt)[
    #align(center, text(fill: secondary, size: 9pt)[No systems specified in this request.])
  ]
}

#v(12pt)

// Approvals Section
#text(weight: "bold", fill: primary, size: 11pt)[4. AUTHORIZATION WORKFLOW]
#v(4pt)

#let approvals = data.at("approvals", default: ())

#if approvals.len() > 0 {
  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + primary) } else { (bottom: 0.5pt + border) },
    inset: 8pt,
    fill: (x, y) => if y == 0 { bg-light } else { white },
    table.header(
      [#text(size: 8pt, fill: secondary)[APPROVER]],
      [#text(size: 8pt, fill: secondary)[ROLE]],
      [#text(size: 8pt, fill: secondary)[STATUS]],
      [#text(size: 8pt, fill: secondary)[DATE]]
    ),
    ..approvals.map(it => {
      let status = it.at("status", default: "Unknown")
      let status-color = if status == "Approved" { green.darken(20%) } 
                        else if status == "Pending" { orange.darken(20%) } 
                        else { red.darken(20%) }
      
      (
        [#it.at("approver", default: "—")],
        [#it.at("role", default: "—")],
        [#text(fill: status-color, weight: "bold")[#status]],
        [#it.at("date", default: "—")]
      )
    }).flatten()
  )
} else {
  text(fill: secondary, size: 9pt)[No approval records found.]
}

#v(20pt)

// Footer / Disclaimer
#block(
  width: 100%,
  stroke: 0.5pt + border,
  inset: 10pt,
  radius: 2pt,
  fill: bg-light
)[
  #set text(size: 7.5pt, fill: secondary)
  *Security Notice:* This document is an official record of access authorization. Unauthorized modification or distribution of this form is strictly prohibited. Access is granted based on the principle of least privilege (PoLP) and is subject to periodic auditing by the IT Security Department.
]

#v(1fr)
#align(center)[
  #text(size: 7pt, fill: secondary)[Generated by Identity & Access Management (IAM) Portal · #{g("request.date", default: "")}]
]
