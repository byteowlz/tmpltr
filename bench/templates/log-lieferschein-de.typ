// Lieferschein
// @description: Lieferschein ohne Preise mit Positionen und Empfangsbestätigung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let positionen = data.at("positionen", default: ())

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.2cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #g("lieferant.firma") · #g("lieferant.strasse") · #g("lieferant.plz_ort") · Tel. #g("lieferant.telefon")
    #h(1fr) Seite 1 von 1
  ])
#set text(font: "Arimo", size: 10pt)

// DIN 5008 fold + punch marks
#place(top + left, dx: -20mm, dy: 67mm, line(length: 4mm, stroke: 0.4pt + gray.darken(20%)))
#place(top + left, dx: -20mm, dy: 128.5mm, line(length: 6mm, stroke: 0.4pt + gray.darken(20%)))
#place(top + left, dx: -20mm, dy: 172mm, line(length: 4mm, stroke: 0.4pt + gray.darken(20%)))

// Header: plain company letterhead
#align(right)[
  #text(weight: "bold", size: 14pt)[#g("lieferant.firma")] \
  #text(size: 9pt)[#g("lieferant.strasse") · #g("lieferant.plz_ort") \ Telefon #g("lieferant.telefon")]
]
#v(10pt)

// Absender line + address window
#text(size: 7pt, fill: gray.darken(40%))[#underline[#g("lieferant.firma") · #g("lieferant.strasse") · #g("lieferant.plz_ort")]]
#v(4pt)
#box(height: 30mm)[
  #text(weight: "bold")[#g("empfaenger.firma")] \
  #if g("empfaenger.ansprechpartner") != "" [#g("empfaenger.ansprechpartner") \ ]
  #g("empfaenger.strasse") \
  #g("empfaenger.plz_ort")
]
#v(6pt)

#text(weight: "bold", size: 16pt)[Lieferschein #g("lieferung.lieferscheinnr")]
#v(6pt)

// Meta table
#table(columns: (auto, auto, auto, auto), inset: (x: 10pt, y: 5pt),
  stroke: 0.5pt + gray.darken(20%), fill: (x, y) => if y == 0 { rgb("#f0f0ee") },
  [#text(size: 8pt, weight: "bold")[Datum]], [#text(size: 8pt, weight: "bold")[Ihre Bestellnummer]],
  [#text(size: 8pt, weight: "bold")[Versandart]], [#text(size: 8pt, weight: "bold")[Packstücke / Gewicht]],
  [#g("lieferung.datum")], [#g("lieferung.bestellnr")],
  [#g("lieferung.versandart")], [#g("lieferung.packstuecke") · #g("lieferung.gewicht_kg") kg])
#v(12pt)

// Positionen (ohne Preise)
#if positionen.len() > 0 {
  table(
    columns: (auto, auto, 1fr, auto, auto),
    align: (center, left, left, right, center),
    inset: (x: 7pt, y: 5.5pt),
    stroke: (x, y) => (bottom: 0.4pt + gray.lighten(20%)),
    table.header(
      table.cell(fill: gray.darken(60%))[#text(fill: white, size: 8.5pt, weight: "bold")[Pos.]],
      table.cell(fill: gray.darken(60%))[#text(fill: white, size: 8.5pt, weight: "bold")[Artikel-Nr.]],
      table.cell(fill: gray.darken(60%))[#text(fill: white, size: 8.5pt, weight: "bold")[Bezeichnung]],
      table.cell(fill: gray.darken(60%))[#text(fill: white, size: 8.5pt, weight: "bold")[Menge]],
      table.cell(fill: gray.darken(60%))[#text(fill: white, size: 8.5pt, weight: "bold")[Einheit]]),
    ..positionen.enumerate().map(((i, p)) => (
      [#(i + 1)],
      [#p.at("artikelnr", default: "")],
      [#p.at("bezeichnung", default: "")],
      [*#p.at("menge", default: "")*],
      [#p.at("einheit", default: "Stk")],
    )).flatten()
  )
} else {
  text(fill: gray)[Keine Positionen.]
}
#v(10pt)

#text(size: 9pt)[Die Ware bleibt bis zur vollständigen Bezahlung unser Eigentum. Bitte prüfen Sie die Sendung bei Anlieferung auf Vollständigkeit und Transportschäden; Beanstandungen sind innerhalb von 48 Stunden schriftlich anzuzeigen.]
#v(18pt)

// Empfangsbestätigung
#block(stroke: 0.7pt + black, inset: 10pt, width: 100%, radius: 1pt)[
  #text(weight: "bold", size: 9.5pt)[Empfangsbestätigung]
  #v(8pt)
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 20pt,
    [
      #v(16pt)
      #line(length: 100%, stroke: 0.5pt)
      #text(size: 7.5pt, fill: gray.darken(30%))[Name in Druckbuchstaben#if g("empfang.name") != "" [: #g("empfang.name")]]
    ],
    [
      #v(16pt)
      #line(length: 100%, stroke: 0.5pt)
      #text(size: 7.5pt, fill: gray.darken(30%))[Datum#if g("empfang.datum") != "" [: #g("empfang.datum")]]
    ],
    [
      #v(16pt)
      #line(length: 100%, stroke: 0.5pt)
      #text(size: 7.5pt, fill: gray.darken(30%))[Unterschrift / Firmenstempel]
    ])
]
