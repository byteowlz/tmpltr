// Laborbefund
// @description: Deutscher Laborbefund mit Referenzbereichen und Bewertung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let dunkel = rgb("#374151")
#let rot = rgb("#b91c1c")

#let werte = data.at("werte", default: ())

#let bew(b) = {
  if b == "" { [] } else if b.starts-with("−") or b.starts-with("-") {
    text(fill: rot, weight: "bold", font: "Cousine", size: 8.5pt)[#b]
  } else {
    text(fill: rot, weight: "bold", font: "Cousine", size: 8.5pt)[#b]
  }
}

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 2.0cm, x: 2.0cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [#g("labor.name") · #g("labor.strasse") · #g("labor.plz_ort") · Tel. #g("labor.telefon") \
       Ärztliche Leitung: #g("labor.leitung")],
      align(right + bottom)[Seite 1 von 1])
  ])
#set text(font: "Tinos", size: 9.5pt)

// Plain serif letterhead, centered
#align(center)[
  #text(weight: "bold", size: 14pt)[#g("labor.name")] \
  #text(size: 9pt)[Medizinisches Versorgungszentrum für Laboratoriumsmedizin und Mikrobiologie] \
  #text(size: 8.5pt, fill: gray.darken(40%))[#g("labor.strasse") · #g("labor.plz_ort") · Telefon #g("labor.telefon")]
]
#v(3pt)
#line(length: 100%, stroke: (thickness: 0.8pt, paint: dunkel))
#line(length: 100%, stroke: (thickness: 0.3pt, paint: dunkel))
#v(10pt)

#grid(columns: (1fr, 1fr), column-gutter: 24pt, row-gutter: 2pt,
  [
    #set text(size: 9pt)
    #table(columns: (auto, 1fr), stroke: none, inset: (x: 4pt, y: 2.5pt),
      text(fill: gray.darken(40%))[Patient:], text(weight: "bold")[#g("patient.name")],
      text(fill: gray.darken(40%))[geb.:], [#g("patient.geburtsdatum") (#g("patient.geschlecht", default: "—"))],
      text(fill: gray.darken(40%))[Versicherten-Nr.:], [#g("patient.versichertennr")])
  ],
  [
    #set text(size: 9pt)
    #table(columns: (auto, 1fr), stroke: none, inset: (x: 4pt, y: 2.5pt),
      text(fill: gray.darken(40%))[Einsender:], [#g("auftrag.einsender")],
      text(fill: gray.darken(40%))[Entnahme:], [#g("auftrag.entnahme_datum")],
      text(fill: gray.darken(40%))[Probeneingang:], [#g("auftrag.eingang_datum")],
      text(fill: gray.darken(40%))[Material:], [#g("auftrag.material")])
  ])
#v(8pt)

#block(fill: dunkel, inset: (x: 8pt, y: 5pt), width: 100%)[
  #text(fill: white, weight: "bold", size: 10pt, tracking: 1pt)[ENDBEFUND]
]
#v(2pt)

#if werte.len() > 0 {
  table(
    columns: (2.2fr, 0.9fr, 0.5fr, 0.9fr, 1.1fr),
    align: (left, right, center, left, left),
    inset: (x: 7pt, y: 4pt),
    stroke: (x, y) => if y == 0 { (bottom: 0.8pt + dunkel) } else { none },
    table.header(
      text(weight: "bold", size: 8.5pt)[Parameter],
      text(weight: "bold", size: 8.5pt)[Wert],
      text(weight: "bold", size: 8.5pt)[Bew.],
      text(weight: "bold", size: 8.5pt)[Einheit],
      text(weight: "bold", size: 8.5pt)[Referenzbereich]),
    ..werte.map(w => {
      let b = w.at("bewertung", default: "")
      (
        [#w.at("parameter", default: "")],
        text(font: "Cousine", size: 8.5pt, weight: if b != "" { "bold" } else { "regular" },
          fill: if b != "" { rot } else { black })[#w.at("wert", default: "")],
        bew(b),
        text(size: 8.5pt)[#w.at("einheit", default: "")],
        text(size: 8.5pt, fill: gray.darken(45%))[#w.at("referenz", default: "")],
      )
    }).flatten()
  )
} else {
  v(4pt)
  text(fill: gray, style: "italic")[Keine Messwerte übermittelt.]
}
#v(4pt)
#text(size: 7.5pt, fill: gray.darken(35%))[Bewertung: + erhöht, ++ stark erhöht, − erniedrigt. Referenzbereiche gelten für Erwachsene. Akkreditiert nach DIN EN ISO 15189.]
#v(10pt)

#if g("kommentar") != "" [
  #text(weight: "bold", size: 10pt)[Befundkommentar] \
  #v(2pt)
  #block(stroke: (left: 1.5pt + dunkel), inset: (left: 9pt, y: 3pt))[
    #text(size: 9.5pt)[#g("kommentar")]
  ]
]
#v(14pt)
#text(size: 9pt)[Mit freundlichen kollegialen Grüßen] \
#v(10pt)
#text(size: 9.5pt, style: "italic")[#g("labor.leitung")] \
#text(size: 7.5pt, fill: gray.darken(30%))[Dieser Befund wurde elektronisch freigegeben und ist ohne Unterschrift gültig.]
