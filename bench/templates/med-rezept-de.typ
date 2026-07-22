// Privatrezept
// @description: Privatrezept mit Arzt, Patient, Verordnungen
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let blau = rgb("#1e3a8a")
#let verordnungen = data.at("verordnungen", default: ())

#set page(width: 148mm, height: 105mm, margin: (x: 7mm, y: 6mm))
#set text(font: "Adwaita Sans", size: 8pt, fill: blau.darken(10%))

// Kopfzeile
#grid(columns: (1fr, auto), column-gutter: 6mm,
  box(stroke: 0.7pt + blau, inset: 5pt, radius: 1.5pt, width: 100%)[
    #text(size: 6pt, fill: blau)[Krankenkasse bzw. Kostenträger] \
    #v(1pt)
    #text(size: 8.5pt, weight: "bold")[#g("patient.krankenkasse", default: " ")]
  ],
  align(right)[
    #text(size: 16pt, weight: "bold", fill: blau, tracking: 0.5pt)[Privatrezept] \
    #text(size: 6.5pt, fill: blau)[Gültig bis: *#g("rezept.gueltig_bis", default: "—")*]
  ])
#v(2mm)

// Patient + Arzt
#grid(columns: (1.2fr, 1fr), column-gutter: 4mm,
  box(stroke: 0.7pt + blau, inset: 5pt, radius: 1.5pt, width: 100%, height: 21mm)[
    #text(size: 6pt, fill: blau)[Name, Vorname des Versicherten · geb. am] \
    #v(1.5pt)
    #text(size: 9pt, weight: "bold")[#g("patient.name")] #h(4pt) #text(size: 8pt)[#g("patient.geburtsdatum")] \
    #v(1pt)
    #text(size: 8pt)[#g("patient.strasse") \ #g("patient.plz_ort")]
  ],
  box(stroke: 0.7pt + blau, inset: 5pt, radius: 1.5pt, width: 100%, height: 21mm)[
    #text(size: 6pt, fill: blau)[Vertragsarztstempel] \
    #v(1.5pt)
    #text(size: 8pt, weight: "bold")[#g("arzt.name")] \
    #text(size: 7pt)[#g("arzt.fachrichtung") \ #g("arzt.strasse"), #g("arzt.plz_ort") \ Tel. #g("arzt.telefon")]
  ])
#v(1.5mm)
#grid(columns: (auto, auto, auto, 1fr), column-gutter: 4mm,
  [#text(size: 6.5pt, fill: blau)[BSNR:] #text(size: 7.5pt, font: "Cousine")[#g("arzt.bsnr", default: "———")]],
  [#text(size: 6.5pt, fill: blau)[LANR:] #text(size: 7.5pt, font: "Cousine")[#g("arzt.lanr", default: "———")]],
  [#text(size: 6.5pt, fill: blau)[Datum:] #text(size: 7.5pt, weight: "bold")[#g("rezept.datum", default: "—")]],
  [])
#v(2mm)

// Rp.
#box(stroke: 1pt + blau, inset: (x: 6pt, y: 5pt), radius: 1.5pt, width: 100%, height: 34mm)[
  #text(size: 13pt, weight: "bold", style: "italic", fill: blau)[Rp.]
  #v(1mm)
  #if verordnungen.len() > 0 {
    for (i, vo) in verordnungen.enumerate() {
      grid(columns: (auto, 1fr, auto), column-gutter: 6pt,
        text(size: 8.5pt, weight: "bold")[#(i + 1).],
        [
          #text(size: 8.5pt, weight: "bold")[#vo.at("medikament", default: "")] #text(size: 8.5pt)[#vo.at("staerke", default: "")] — #text(size: 8pt)[#vo.at("menge", default: "")] \
          #text(size: 7pt, fill: blau.lighten(15%))[Dos.: #vo.at("dosierung", default: "nach Anweisung")]
        ],
        [])
      v(1.2mm)
    }
  } else {
    text(size: 8pt, fill: blau.lighten(30%), style: "italic")[— keine Verordnung eingetragen —]
  }
]
#v(1.5mm)

#grid(columns: (1fr, auto), column-gutter: 8mm, align: bottom,
  text(size: 6pt, fill: blau)[Nur gültig mit Unterschrift und Stempel des Arztes. Abgabe in der Apotheke gegen Vorlage.],
  align(center)[
    #box(width: 42mm)[#line(length: 100%, stroke: 0.6pt + blau)]
    #v(-1pt)
    #text(size: 6pt, fill: blau)[Unterschrift des Arztes]
  ])
