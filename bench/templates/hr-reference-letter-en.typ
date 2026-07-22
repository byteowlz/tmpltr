// Letter of Recommendation
// @description: Professional reference: relationship, achievements, endorsement
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 3cm, bottom: 3cm, left: 2.5cm, right: 2.5cm)
)

// Use Libertinus Serif for a formal, professional letter feel
#set text(font: "Libertinus Serif", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.65em)

// Header: Author Information (Right Aligned)
#align(right)[
  #text(weight: "bold", size: 12pt)[#g("author.name")] \
  #text(size: 10pt, fill: gray.darken(50%))[#g("author.title")] \
  #text(size: 10pt, fill: gray.darken(50%))[#g("author.company")] \
  #v(4pt)
  #text(size: 10pt)[#g("author.email")] \
  #text(size: 10pt)[#g("author.phone")]
]

#v(2em)

// Date
#text(size: 11pt)[#g("date")]

#v(2em)

// Subject Line
#block(width: 100%)[
  #text(weight: "bold", size: 12pt)[
    RE: Letter of Recommendation for #g("subject.name")
  ]
]

#v(1em)

// Salutation
#text(size: 11pt)[To Whom It May Concern, / Dear Hiring Committee,]

#v(1em)

// Body Content
// Context
#g("body.context")

#v(1em)

// Relationship/Period
#text(style: "italic")[
  I had the pleasure of working closely with #g("subject.name"), serving as her #g("subject.relationship") during the period of #g("subject.period").
]

#v(1em)

// Achievements
#g("body.achievements")

#v(1em)

// Skills
#g("body.skills")

#v(1em)

// Endorsement
#text(weight: "medium")[
  #g("body.endorsement")
]

#v(3em)

// Closing
#text(size: 11pt)[
  Sincerely,
]

#v(1.5em)

// Signature Area
// Logo/Initials Box for visual identity
#let author-name = g("author.name", default: "··")
#let initials = upper(author-name.clusters().slice(0, calc.min(2, author-name.clusters().len())).join(""))

#grid(
  columns: (auto, 1fr),
  column-gutter: 12pt,
  // Visual signature placeholder
  box(
    fill: rgb("#2c3e50"),
    inset: 6pt,
    radius: 2pt,
    text(fill: white, weight: "bold", size: 14pt, initials)
  ),
  // Name and Title
  stack(
    spacing: 2pt,
    text(weight: "bold", size: 12pt)[#g("author.name")],
    text(size: 10pt, fill: gray.darken(50%))[#g("author.title")],
    text(size: 10pt, fill: gray.darken(50%))[#g("author.company")]
  )
)
