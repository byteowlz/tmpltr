// Vaccination Record
// @description: Immunization history table with lot numbers and next due dates
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let gold = rgb("#a3720e")
#let cream = rgb("#fdf6e3")
#let vaccinations = data.at("vaccinations", default: ())

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, x: 1.8cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.5pt + gold)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [This record is maintained by #g("clinic.name", default: "the clinic"). Keep this document with your personal health records.],
      [Page 1 of 1])
  ])
#set text(font: "Tinos", size: 9.5pt)

// Header — certificate style, centered
#align(center)[
  #box(stroke: (paint: gold, thickness: 1.4pt), inset: (x: 22pt, y: 10pt), fill: cream, radius: 2pt)[
    #text(size: 17pt, weight: "bold", fill: gold.darken(20%), tracking: 1.5pt)[VACCINATION RECORD] \
    #v(2pt)
    #text(size: 9pt, tracking: 0.5pt)[CERTIFICATE OF IMMUNIZATION]
  ]
]
#v(8pt)
#align(center)[
  #text(weight: "bold", size: 11pt)[#g("clinic.name", default: "—")] \
  #text(size: 8.5pt, fill: gray.darken(45%))[#g("clinic.address") · Tel. #g("clinic.phone")]
]
#v(10pt)

// Patient band
#block(width: 100%, stroke: (y: 0.7pt + gold), inset: (y: 6pt))[
  #grid(columns: (1.6fr, 1fr, 1fr), column-gutter: 14pt,
    [#text(size: 7.5pt, fill: gold.darken(20%))[PATIENT NAME] \ #text(weight: "bold", size: 11pt)[#g("patient.name", default: "—")]],
    [#text(size: 7.5pt, fill: gold.darken(20%))[DATE OF BIRTH] \ #text(weight: "bold", size: 11pt)[#g("patient.dob", default: "—")]],
    [#text(size: 7.5pt, fill: gold.darken(20%))[PATIENT ID] \ #text(weight: "bold", size: 11pt)[#g("patient.id", default: "—")]])
]
#v(12pt)

// Vaccination table
#if vaccinations.len() > 0 {
  table(
    columns: (auto, 1.15fr, 1fr, auto, auto, auto, auto),
    align: (left, left, left, left, left, left, left),
    stroke: 0.4pt + gold.lighten(35%),
    inset: 5.5pt,
    fill: (_, row) => if row == 0 { gold.darken(10%) } else if calc.odd(row) { cream } else { white },
    table.header(
      ..([Date], [Vaccine], [Protects against], [Lot no.], [Site / route], [Administered by], [Next due])
        .map(h => text(fill: white, weight: "bold", size: 8.5pt)[#h])),
    ..vaccinations.map(v => (
      [#text(size: 8.5pt)[#v.at("date", default: "")]],
      [#text(size: 8.5pt, weight: "bold")[#v.at("vaccine", default: "")]],
      [#text(size: 8.5pt)[#v.at("disease", default: "")]],
      [#text(size: 8.5pt, font: "Cousine")[#v.at("lot", default: "")]],
      [#text(size: 8.5pt)[#v.at("site", default: "")]],
      [#text(size: 8.5pt)[#v.at("administered_by", default: "")]],
      [#text(size: 8.5pt)[#v.at("next_due", default: "—")]],
    )).flatten()
  )
} else {
  text(fill: gray, style: "italic")[No vaccinations on record.]
}
#v(10pt)

#text(size: 8.5pt, fill: gray.darken(40%))[
  Entries above were transcribed from the clinic's electronic immunization
  registry and verified against manufacturer lot documentation. Report any
  suspected adverse reaction to your provider. Bring this record to every
  medical appointment and when travelling internationally.
]
#v(18pt)
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 8pt)[Authorized signature, #g("clinic.name", default: "clinic")]
  ],
  [
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 8pt)[Date issued]
  ])
