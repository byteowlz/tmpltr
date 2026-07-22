// University Transcript
// @description: Course grades, credits, GPA by term
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let courses = data.at("courses", default: ())
#let accent = rgb("#5b1f2e")

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, left: 2cm, right: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr), column-gutter: 8pt,
      [#g("university.name") · #g("university.registrar")],
      align(right)[Not valid without the registrar's signature and embossed seal · Page 1 of 1])
  ])
#set text(font: "Tinos", size: 9.5pt)

// Header
#align(center)[
  #text(size: 17pt, weight: "bold", fill: accent)[#g("university.name")] \
  #text(size: 9pt)[#g("university.address")] \
  #v(2pt)
  #text(size: 10.5pt, tracking: 2.5pt)[OFFICIAL ACADEMIC TRANSCRIPT] \
  #text(size: 8pt, style: "italic")[#g("university.registrar")]
]
#v(4pt)
#line(length: 100%, stroke: 1.4pt + accent)
#line(length: 100%, stroke: 0.5pt + accent)
#v(8pt)

// Student block
#box(fill: rgb("#f7f2f3"), width: 100%, inset: 8pt)[
  #grid(columns: (1fr, 1fr), row-gutter: 4pt,
    [*Student:* #g("student.name")],
    [*Student ID:* #g("student.id")],
    [*Program:* #g("student.program")],
    [*Enrolled since:* #g("student.enrollment_date")])
]
#v(10pt)

// Course table grouped by term
#if courses.len() > 0 {
  let rows = ()
  let prev-term = none
  for c in courses {
    let term = c.at("term", default: "")
    if term != prev-term {
      rows.push(table.cell(colspan: 4, fill: accent.lighten(88%),
        text(weight: "bold", size: 9.5pt, fill: accent)[#term]))
      prev-term = term
    }
    rows.push([#c.at("code", default: "")])
    rows.push([#c.at("title", default: "")])
    rows.push([#c.at("credits", default: "")])
    rows.push([#c.at("grade", default: "")])
  }
  table(
    columns: (auto, 1fr, auto, auto),
    align: (left, left, center, center),
    stroke: (x, y) => (bottom: 0.4pt + gray.lighten(40%)),
    inset: (x: 6pt, y: 4.5pt),
    table.header(
      table.cell(fill: accent, text(fill: white, weight: "bold", size: 8.5pt)[COURSE]),
      table.cell(fill: accent, text(fill: white, weight: "bold", size: 8.5pt)[TITLE]),
      table.cell(fill: accent, text(fill: white, weight: "bold", size: 8.5pt)[CREDITS]),
      table.cell(fill: accent, text(fill: white, weight: "bold", size: 8.5pt)[GRADE])),
    ..rows
  )
} else {
  text(fill: gray, style: "italic")[No coursework recorded.]
}
#v(10pt)

// Summary
#grid(columns: (1fr, auto), column-gutter: 12pt,
  [
    #text(size: 8pt, fill: gray.darken(30%))[Grading: A = 4.0, A- = 3.7, B+ = 3.3, B = 3.0, B- = 2.7, C+ = 2.3, C = 2.0, D = 1.0, F = 0.0. \ Credits are semester hours. This transcript reflects the complete undergraduate record to date.]
  ],
  table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3pt,
    [Total credits earned], [*#g("summary.total_credits")*],
    [Cumulative GPA], [*#g("summary.gpa")*],
    [Class rank], [*#g("summary.class_rank")*],
    table.hline(stroke: 0.8pt + accent)))
#v(1fr)

// Issue block
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(size: 9pt)[Issued: #g("issued.date")]
  ],
  align(right)[
    #line(length: 70%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[#g("issued.signature")]
  ])
