// Equipment Maintenance Log
// @description: Machine maintenance record with interval tasks and service entries
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration
#let accent = rgb("#2e4a3e") // Industrial dark green
#let secondary = rgb("#f4f7f5")
#let text-main = rgb("#333333")

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  header: [
    #set text(size: 8pt, fill: gray.darken(50%))
    #grid(columns: (1fr, auto),
      [#upper(g("site.company", default: "N/A")) · #g("site.plant", default: "N/A")],
      [Log ID: #g("equipment.serial", default: "—")]
    )
    #line(length: 100%, stroke: 0.5pt + gray)
  ]
)

#set text(font: "Tinos", size: 10pt, fill: text-main)

// --- Header Section ---
#grid(columns: (1fr, auto),
  [
    #text(size: 22pt, weight: "bold", fill: accent)[Maintenance Log] \
    #text(size: 11pt, fill: gray.darken(40%))[Equipment Service Record]
  ],
  align(right)[
    #box(fill: accent, inset: 6pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 10pt)[#upper(g("equipment.manufacturer", default: "N/A"))]
    ]
  ]
)

#v(10pt)

// --- Equipment Info Card ---
#block(fill: secondary, inset: 12pt, radius: 4pt, width: 100%)[
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 12pt,
    [
      #text(size: 8pt, weight: "bold", fill: accent)[EQUIPMENT] \
      #text(weight: "bold", size: 11pt)[#g("equipment.name")] \
      #text(size: 10pt)[Model: #g("equipment.model")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: accent)[IDENTIFICATION] \
      #text(size: 10pt)[S/N: #g("equipment.serial")] \
      #text(size: 10pt)[Installed: #g("equipment.install_date")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: accent)[STATUS] \
      #text(size: 10pt)[Op. Hours: #g("equipment.operating_hours", default: "0")] \
      #text(size: 10pt)[Loc: #g("site.location")]
    ]
  )
]

#v(15pt)

// --- Section: Maintenance Schedule ---
#text(size: 13pt, weight: "bold", fill: accent)[Scheduled Maintenance Intervals]
#v(5pt)

#let schedule = data.at("schedule", default: ())
#if schedule.len() > 0 {
  table(
    columns: (1fr, auto, auto, auto),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { accent } else if calc.even(y) { secondary } else { white },
    table.header(
      [#text(fill: white, weight: "bold")[Task Description]],
      [#text(fill: white, weight: "bold")[Interval]],
      [#text(fill: white, weight: "bold")[Last Done]],
      [#text(fill: white, weight: "bold")[Next Due]]
    ),
    ..schedule.map(it => (
      [#it.at("task", default: "-")],
      [#it.at("interval", default: "-")],
      [#it.at("last_done", default: "-")],
      [#it.at("next_due", default: "-")]
    )).flatten()
  )
} else {
  text(style: "italic", fill: gray)[No scheduled tasks defined.]
}

#v(20pt)

// --- Section: Service History ---
#text(size: 13pt, weight: "bold", fill: accent)[Service History Log]
#v(5pt)

#let entries = data.at("entries", default: ())
#if entries.len() > 0 {
  table(
    columns: (auto, auto, 1fr, 1fr, auto),
    stroke: none,
    inset: 8pt,
    fill: (x, y) => if y == 0 { accent } else if calc.even(y) { secondary } else { white },
    table.header(
      [#text(fill: white, weight: "bold")[Date]],
      [#text(fill: white, weight: "bold")[Type]],
      [#text(fill: white, weight: "bold")[Work Performed]],
      [#text(fill: white, weight: "bold")[Parts/Materials]],
      [#text(fill: white, weight: "bold")[DT]]
    ),
    ..entries.map(it => (
      [#it.at("date", default: "-")],
      [#text(size: 9pt)[#it.at("type", default: "-")]],
      [#it.at("work_done", default: "-")],
      [#text(size: 9pt, style: "italic")[#it.at("parts_used", default: "-")]],
      [#it.at("downtime_h", default: "0") "h"]
    )).flatten()
  )
} else {
  text(style: "italic", fill: gray)[No service entries recorded.]
}

#v(20pt)

// --- Footer / Sign-off ---
#line(length: 100%, stroke: 0.5pt + gray)
#grid(columns: (1fr, 1fr),
  [
    #set text(size: 8pt, fill: gray.darken(50%))
    #text(weight: "bold", fill: text-main)[Authorized Signature: ____________________] \
    #v(4pt)
    #text(weight: "bold", fill: text-main)[Date: ____________________]
  ],
  align(right)[
    #set text(size: 8pt, fill: gray.darken(50%))
    Generated via Maintenance Management System \
    #datetime.today().display("[day].[month].[year]")
  ]
)
