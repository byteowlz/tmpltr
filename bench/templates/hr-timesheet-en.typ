// Monthly Timesheet
// @description: Daily hours, project codes, overtime, approval line
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let green = rgb("#1d7a3e")
#let zebra = rgb("#f0f7f2")

#let hrs(x) = {
  let v = int(calc.round(float(x) * 10))
  str(calc.quo(v, 10)) + "." + str(calc.rem(calc.abs(v), 10))
}

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2cm, x: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%), font: "Adwaita Sans")
    #grid(columns: (1fr, auto),
      [Timesheet · #g("period.month") #g("period.year") · #g("employee.id")],
      [Page 1 of 1])
  ])
#set text(font: "Adwaita Sans", size: 9.5pt)

// Header band
#block(fill: green, inset: (x: 14pt, y: 10pt), radius: 4pt, width: 100%)[
  #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    text(fill: white, size: 17pt, weight: "bold")[MONTHLY TIMESHEET],
    text(fill: white.transparentize(15%), size: 11pt, weight: "medium")[#g("period.month", default: "—") #g("period.year")])
]
#v(10pt)

// Employee meta
#grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt,
  ..(
    ("EMPLOYEE", g("employee.name", default: "—")),
    ("EMPLOYEE ID", g("employee.id", default: "—")),
    ("DEPARTMENT", g("employee.department", default: "—")),
  ).map(((lbl, val)) => block(stroke: (bottom: 1pt + green), inset: (bottom: 4pt), width: 100%)[
    #text(size: 7pt, fill: gray.darken(40%), tracking: 0.8pt)[#lbl] \
    #text(size: 10.5pt, weight: "semibold")[#val]
  ])
)
#v(12pt)

// Entries
#let entries = data.at("entries", default: ())
#if entries.len() > 0 {
  table(
    columns: (auto, auto, 1fr, auto, auto),
    align: (left, left, left, right, right),
    stroke: (x, y) => (bottom: 0.4pt + gray.lighten(30%)),
    inset: (x: 8pt, y: 5.5pt),
    fill: (_, row) => if row == 0 { green.lighten(88%) } else if calc.even(row) { zebra } else { white },
    table.header(
      [#text(weight: "bold", fill: green.darken(20%))[Date]],
      [#text(weight: "bold", fill: green.darken(20%))[Project]],
      [#text(weight: "bold", fill: green.darken(20%))[Task / activity]],
      [#text(weight: "bold", fill: green.darken(20%))[Hours]],
      [#text(weight: "bold", fill: green.darken(20%))[OT]]),
    ..entries.map(e => (
      [#e.at("date", default: "")],
      [#text(font: "Cousine", size: 8.5pt)[#e.at("project", default: "")]],
      [#e.at("task", default: "")],
      [#hrs(e.at("hours", default: 0))],
      [#{ let ot = float(e.at("overtime", default: 0)); if ot > 0 { text(weight: "semibold", fill: green.darken(10%))[#hrs(ot)] } else { text(fill: gray)[—] } }],
    )).flatten()
  )
} else {
  text(fill: gray, style: "italic")[No time entries recorded for this period.]
}
#v(10pt)

// Totals
#align(right)[
  #grid(columns: 3, column-gutter: 10pt,
    ..(
      ("Regular hours", hrs(g("totals.regular", default: 0))),
      ("Overtime", hrs(g("totals.overtime", default: 0))),
      ("Billable", hrs(g("totals.billable", default: 0))),
    ).map(((lbl, val)) => block(fill: green.lighten(90%), stroke: 0.6pt + green.lighten(50%), radius: 3pt, inset: (x: 12pt, y: 7pt))[
      #align(center)[
        #text(size: 7pt, fill: green.darken(25%), tracking: 0.6pt)[#upper(lbl)] \
        #text(size: 13pt, weight: "bold", fill: green.darken(20%))[#val]
      ]
    ])
  )
]
#v(18pt)

// Approval
#block(stroke: 0.6pt + gray.lighten(30%), radius: 3pt, inset: 12pt, width: 100%)[
  #text(size: 7.5pt, fill: gray.darken(40%), tracking: 0.8pt)[APPROVAL]
  #v(6pt)
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 18pt, row-gutter: 4pt,
    [#line(length: 100%, stroke: 0.6pt + black) #text(size: 8pt, fill: gray.darken(30%))[Manager: #g("approval.manager", default: "—")]],
    [#line(length: 100%, stroke: 0.6pt + black) #text(size: 8pt, fill: gray.darken(30%))[Date: #g("approval.date", default: "—")]],
    [#line(length: 100%, stroke: 0.6pt + black) #text(size: 8pt, fill: gray.darken(30%))[Status: #text(weight: "bold", fill: green.darken(10%))[#g("approval.status", default: "Pending")]]],
  )
]
