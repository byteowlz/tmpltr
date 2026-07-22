// Examination Schedule
// @description: Exam timetable with rooms, seats, rules
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let accent = rgb("#473a8f")
#let exams = data.at("exams", default: ())
#let rules = data.at("rules", default: ())

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [#g("institution.name") · Examinations Office],
      align(right)[Personal timetable — check the noticeboard for late room changes · Page 1 of 1])
  ])
#set text(font: "Arimo", size: 9.5pt)

// Header band
#block(fill: accent, width: 100%, inset: (x: 14pt, y: 11pt), radius: 2pt)[
  #grid(columns: (1fr, auto), column-gutter: 10pt,
    [
      #text(fill: white, weight: "bold", size: 15pt)[#g("institution.name")] \
      #text(fill: white.transparentize(15%), size: 9pt)[#g("institution.department")]
    ],
    align(right + horizon)[
      #text(fill: white, weight: "bold", size: 11pt)[EXAMINATION SCHEDULE] \
      #text(fill: white.transparentize(15%), size: 9pt)[#g("institution.term")]
    ])
]
#v(10pt)

// Candidate strip
#block(stroke: (left: 3pt + accent), fill: rgb("#f3f1fa"), width: 100%, inset: 8pt)[
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt,
    [*Candidate:* #g("student.name")],
    [*Student ID:* #g("student.id")],
    [*Programme:* #g("student.program")])
]
#v(12pt)

// Timetable
#if exams.len() > 0 {
  table(
    columns: (auto, auto, auto, 1fr, auto, auto, auto, 1fr),
    align: (left, center, left, left, left, center, center, left),
    stroke: (x, y) => (bottom: 0.4pt + gray.lighten(40%)),
    inset: (x: 5pt, y: 5pt),
    fill: (_, row) => if row == 0 { accent } else if calc.even(row) { rgb("#f7f6fc") } else { white },
    table.header(
      ..([Date], [Time], [Code], [Course], [Room], [Seat], [Min], [Permitted aids])
        .map(h => text(fill: white, weight: "bold", size: 8pt)[#h])),
    ..exams.map(e => (
      [#e.at("date", default: "")],
      [*#e.at("time", default: "")*],
      [#e.at("course_code", default: "")],
      [#e.at("course", default: "")],
      [#e.at("room", default: "")],
      [#e.at("seat", default: "")],
      [#e.at("duration_min", default: "")],
      [#text(size: 8.5pt)[#e.at("aids", default: "")]],
    )).flatten()
  )
} else {
  text(fill: gray, style: "italic")[No examinations scheduled.]
}
#v(14pt)

// Rules
#text(weight: "bold", size: 10.5pt, fill: accent)[Examination Rules]
#v(3pt)
#line(length: 100%, stroke: 0.8pt + accent.lighten(50%))
#v(4pt)
#if rules.len() > 0 {
  set text(size: 8.8pt)
  for (i, r) in rules.enumerate() [
    #grid(columns: (16pt, 1fr), column-gutter: 4pt, row-gutter: 0pt,
      text(weight: "bold", fill: accent)[#(i + 1).],
      [#r])
    #v(3pt)
  ]
} else {
  text(fill: gray, style: "italic", size: 8.8pt)[Refer to the general examination regulations.]
}
#v(1fr)
#text(size: 8pt, fill: gray.darken(20%))[
  Issued by the Examinations Office, #g("institution.name"). This timetable is
  personal to the candidate named above and is not transferable.
]
