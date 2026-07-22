// Schulzeugnis
// @description: Jahreszeugnis mit Fächern, Noten, Versetzungsvermerk
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let noten = data.at("noten", default: ())

#set page(paper: "a4", margin: (top: 2.4cm, bottom: 2.4cm, left: 2.4cm, right: 2.4cm),
  background: [
    #place(dx: 10mm, dy: 10mm, rect(width: 190mm, height: 277mm, stroke: 1.6pt + rgb("#3a3a3a")))
    #place(dx: 11.4mm, dy: 11.4mm, rect(width: 187.2mm, height: 274.2mm, stroke: 0.5pt + rgb("#3a3a3a")))
  ])
#set text(font: "New Computer Modern", size: 10.5pt)

// School header, centered
#align(center)[
  #text(size: 14pt, weight: "bold")[#g("schule.name")] \
  #text(size: 9.5pt)[#g("schule.strasse") · #g("schule.plz_ort")] \
  #text(size: 9pt, style: "italic")[#g("schule.schulform")]
]
#v(4pt)
#align(center)[#line(length: 55%, stroke: 0.7pt)]
#v(14pt)

#align(center)[
  #text(size: 26pt, tracking: 5pt)[ZEUGNIS] \
  #v(4pt)
  #text(size: 11pt)[Schuljahr #g("schueler.schuljahr") — #g("schueler.halbjahr")]
]
#v(16pt)

#align(center)[
  #text(size: 12pt)[#text(weight: "bold")[#g("schueler.name")]] \
  #v(2pt)
  #text(size: 10pt)[geboren am #g("schueler.geburtsdatum") · Klasse #g("schueler.klasse")]
]
#v(18pt)

// Grades in two columns
#text(size: 11pt, weight: "bold", tracking: 1pt)[Leistungen]
#v(6pt)
#if noten.len() > 0 {
  let half = calc.ceil(noten.len() / 2)
  let links = noten.slice(0, half)
  let rechts = noten.slice(half)
  let spalte(xs) = table(
    columns: (1fr, auto),
    stroke: (x, y) => (bottom: 0.4pt + gray.lighten(30%)),
    inset: (x: 4pt, y: 5pt),
    ..xs.map(n => (
      [#n.at("fach", default: "")],
      [#text(weight: "bold")[#n.at("note", default: "")]],
    )).flatten()
  )
  grid(columns: (1fr, 1fr), column-gutter: 28pt, spalte(links), spalte(rechts))
} else {
  text(fill: gray, style: "italic")[Keine Noten eingetragen.]
}
#v(6pt)
#text(size: 8.5pt, style: "italic", fill: gray.darken(30%))[
  Notenstufen: sehr gut (1), gut (2), befriedigend (3), ausreichend (4), mangelhaft (5), ungenügend (6)
]
#v(14pt)

// Remarks
#if g("bemerkungen") != "" [
  #text(size: 11pt, weight: "bold", tracking: 1pt)[Bemerkungen]
  #v(4pt)
  #text(size: 10pt)[#g("bemerkungen")]
  #v(12pt)
]

// Promotion note
#if g("versetzung") != "" [
  #align(center)[
    #box(stroke: (top: 0.6pt, bottom: 0.6pt), inset: (x: 18pt, y: 7pt))[
      #text(size: 11pt, weight: "bold")[#g("versetzung")]
    ]
  ]
  #v(18pt)
]

#v(1fr)

// Place, date, signatures
#text(size: 10pt)[#g("ausstellung.ort"), den #g("ausstellung.datum")]
#v(26pt)
#grid(columns: (1fr, auto, 1fr), column-gutter: 14pt,
  [
    #line(length: 80%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[#g("ausstellung.klassenleitung") \ #text(style: "italic")[Klassenleitung]]
  ],
  align(center + horizon)[
    #circle(radius: 11mm, stroke: (paint: gray, thickness: 0.7pt, dash: "dashed"))[
      #align(center + horizon)[#text(size: 7pt, fill: gray)[Siegel \ der Schule]]
    ]
  ],
  align(right)[
    #line(length: 80%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[#g("ausstellung.schulleitung") \ #text(style: "italic")[Schulleitung]]
  ])
