// Court Summons
// @description: Witness/defendant summons with case, date, courtroom
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
// Renamed 'default' to 'def' to prevent variable shadowing/collision errors
#let g(path, def: "") = get(data, path, default: def)

// Layout Settings
#set page(
  paper: "us-letter", 
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Tinos", size: 11pt, lang: "en")

// Colors and Accents
#let court-accent = rgb("#2c3e50")

// Header: Court Identity
#align(center)[
  #text(size: 18pt, weight: "bold", fill: court-accent)[#upper(g("court.name", def: "SUPERIOR COURT"))] \
  #text(size: 10pt, style: "italic")[#g("court.address", def: ""), #g("court.postal", def: ""), #g("court.city", def: ""), #g("court.country", def: "")] \
  #text(size: 10pt)[Phone: #g("court.phone", def: "—")]
  #v(10pt)
  #line(length: 100%, stroke: 1.5pt + court-accent)
  #v(5pt)
  #text(size: 14pt, weight: "bold")[SUMMONS TO APPEAR]
  #v(5pt)
  #line(length: 100%, stroke: 0.5pt + court-accent)
]

#v(15pt)

// Case Metadata Block
#grid(
  columns: (1fr, 1fr),
  [
    #text(weight: "bold")[CASE NUMBER:] \
    #text(size: 12pt, weight: "bold")[#g("court.case_no", def: "PENDING")]
  ],
  align(right)[
    #text(weight: "bold")[DATE OF ISSUE:] \
    #g("hearing.date", def: "—")
  ]
)

#v(20pt)

// Parties Section
#text(weight: "bold", size: 12pt)[PARTIES INVOLVED:]
#v(5pt)

// Safely extract parties using get to ensure default is respected
#let parties = g("hearing.parties", def: ())
#if type(parties) == array and parties.len() > 0 {
  block(width: 100%, inset: (left: 10pt), stroke: (left: 2pt + gray))[
    #for (i, p) in parties.enumerate() {
      // Ensure p is a dictionary before calling .at
      let p_name = if type(p) == dictionary { p.at("name", default: "Unknown") } else { "Unknown" }
      let p_role = if type(p) == dictionary { p.at("role", default: "Party") } else { "Party" }
      [#p_name \ #text(size: 9pt, fill: gray)[Role: #p_role] \ ]
      if i < parties.len() - 1 { v(4pt) }
    }
  ]
} else {
  [No parties listed.]
}

#v(20pt)

// Recipient Information
#rect(width: 100%, stroke: 0.5pt + gray, inset: 12pt, radius: 2pt)[
  #text(weight: "bold", size: 10pt, fill: court-accent)[RECIPIENT / SUBJECT:] \
  #v(4pt)
  #text(size: 13pt, weight: "bold")[#g("person.name", def: "UNKNOWN RECIPIENT")] \
  #g("person.address", def: "") \
  #g("person.city", def: ""), #g("person.postal", def: ""), #g("person.country", def: "") \
  #v(4pt)
  #text(size: 10pt, style: "italic")[Designated Role: #g("person.role", def: "N/A")]
]

#v(25pt)

// Hearing Details
#text(weight: "bold", size: 12pt)[HEARING SCHEDULE:]
#v(5pt)

#table(
  columns: (auto, 1fr),
  stroke: none,
  column-gutter: 15pt,
  row-gutter: 8pt,
  [#text(weight: "bold")[Matter:]], [#g("hearing.matter", def: "N/A")],
  [#text(weight: "bold")[Date:]], [#g("hearing.date", def: "—")],
  [#text(weight: "bold")[Time:]], [#g("hearing.time", def: "—")],
  [#text(weight: "bold")[Location:]], [#g("hearing.room", def: "—")],
  [#text(weight: "bold")[Presiding:]], [#g("hearing.judge", def: "—")],
)

#v(20pt)

// Instructions and Legal Warnings
#text(weight: "bold", size: 11pt)[INSTRUCTIONS:]
#v(4pt)
#set par(justify: true)
#g("hearing.instructions", def: "No instructions provided.")

#v(20pt)

#block(
  fill: rgb("#fdf2f2"),
  inset: 12pt,
  radius: 2pt,
  width: 100%
)[
  #text(weight: "bold", fill: rgb("#9b2c2c"))[LEGAL NOTICE: FAILURE TO COMPLY] \
  #v(4pt)
  #text(size: 10pt, fill: rgb("#742a2a"))[#g("hearing.failure_consequences", def: "Failure to appear may result in legal action.")]
]

#v(40pt)

// Signature Area
#grid(
  columns: (1fr, 1fr),
  [
    #v(20pt)
    #line(length: 80%, stroke: 0.5pt) \
    #text(size: 9pt)[Clerk of the Court]
  ],
  align(right)[
    #v(20pt)
    #line(length: 80%, stroke: 0.5pt) \
    #text(size: 9pt)[Authorized Signature]
  ]
)

#v(1fr)

// Footer
#align(center)[
  #text(size: 8pt, fill: gray)[Official Document of the #g("court.name", def: "Superior Court") · Case ID: #g("court.case_no", def: "—")]
]
