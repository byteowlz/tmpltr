// Academic Recommendation Letter
// @description: Professor recommendation for graduate application
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let accent = rgb("#2f3d54")
#let courses = get(data, "student.courses", default: ())

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.4cm, left: 2.6cm, right: 2.6cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #align(center)[#g("author.department") · #g("author.institution") · #g("author.email")]
  ])
#set text(font: "Libertinus Serif", size: 10.5pt)
#set par(justify: true, leading: 0.62em)

// Letterhead
#grid(columns: (1fr, auto), column-gutter: 12pt,
  [
    #text(size: 14pt, weight: "bold", fill: accent)[#g("author.institution")] \
    #text(size: 9pt, style: "italic", fill: accent.lighten(20%))[#g("author.department")]
  ],
  align(right + bottom)[
    #text(size: 9pt)[
      #g("author.name") \
      #g("author.title") \
      #g("author.email")
    ]
  ])
#v(3pt)
#line(length: 100%, stroke: 1.2pt + accent)
#v(16pt)

#align(right)[#g("date")]
#v(10pt)

Admissions Committee \
#g("target.program", default: "Graduate Program") \
#g("target.institution", default: "")
#v(14pt)

#text(weight: "bold")[Re: Letter of recommendation for #g("student.name") — #g("student.program")]
#v(8pt)

Dear Members of the Admissions Committee,

#v(6pt)
#g("body.context")

#v(6pt)
#g("body.strengths")

#v(6pt)
#g("body.comparison")

// Coursework sidebar box
#if courses.len() > 0 [
  #v(8pt)
  #block(fill: rgb("#f4f5f7"), stroke: (left: 2.5pt + accent), width: 100%, inset: 9pt)[
    #text(size: 8.5pt, weight: "bold", fill: accent, tracking: 1pt)[WORK WITH ME (since #g("student.known_since", default: "—"))]
    #v(3pt)
    #set text(size: 9pt)
    #for c in courses [
      • #c \
    ]
  ]
]

#v(6pt)
#g("body.endorsement")

#v(20pt)
Sincerely,
#v(26pt)
#line(length: 45%, stroke: 0.6pt)
#text(weight: "bold")[#g("author.name")] \
#text(size: 9.5pt)[#g("author.title"), #g("author.institution")]
