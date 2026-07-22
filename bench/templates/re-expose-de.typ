// Immobilien-Exposé
// @description: Objektbeschreibung mit Eckdaten, Ausstattung, Energieausweis
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let bordeaux = rgb("#7a1f2b")
#let creme = rgb("#f7f2ec")
#let ausstattung = data.at("ausstattung", default: ())

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 2.2cm, x: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray.lighten(30%))
    #v(2pt)
    #g("makler.firma") · Ihr Ansprechpartner: #g("makler.ansprechpartner") ·
    #g("makler.telefon") · #g("makler.email")
    #h(1fr) Exposé · Seite 1 von 1
  ])
#set text(font: "Libertinus Serif", size: 10pt, lang: "de")

// Kopf
#grid(columns: (auto, 1fr), align: (left + horizon, right + horizon), column-gutter: 10pt,
  box(fill: bordeaux, inset: 9pt)[
    #text(fill: white, weight: "bold", size: 13pt, font: "Libertinus Serif")[TI]
  ],
  align(right)[
    #text(size: 14pt, weight: "bold", fill: bordeaux, tracking: 0.08em)[#upper(g("makler.firma", default: "Immobilien"))] \
    #text(size: 8.5pt, fill: gray.darken(40%))[#g("makler.ansprechpartner") · #g("makler.telefon") · #g("makler.email")]
  ])
#v(4pt)
#line(length: 100%, stroke: (paint: bordeaux, thickness: 0.5pt))
#v(2pt)
#line(length: 100%, stroke: (paint: bordeaux, thickness: 2pt))
#v(14pt)

// Titel
#text(size: 17pt, weight: "bold")[#g("objekt.titel", default: "Objekt-Exposé")]
#v(2pt)
#text(size: 10.5pt, fill: gray.darken(30%), style: "italic")[
  #g("objekt.typ") · #g("objekt.strasse") · #g("objekt.plz_ort")
]
#v(12pt)

// Eckdaten-Raster
#box(width: 100%, fill: creme, inset: 12pt)[
  #text(weight: "bold", size: 9pt, fill: bordeaux, tracking: 0.1em)[ECKDATEN]
  #v(6pt)
  #grid(columns: (1fr, 1fr, 1fr, 1fr), row-gutter: 10pt, column-gutter: 8pt,
    [#text(size: 8pt, fill: gray.darken(40%))[Wohnfläche] \ #text(size: 12pt, weight: "bold")[#g("objekt.wohnflaeche_qm", default: "—") m²]],
    [#text(size: 8pt, fill: gray.darken(40%))[Zimmer] \ #text(size: 12pt, weight: "bold")[#g("objekt.zimmer", default: "—")]],
    [#text(size: 8pt, fill: gray.darken(40%))[Baujahr] \ #text(size: 12pt, weight: "bold")[#g("objekt.baujahr", default: "—")]],
    [#text(size: 8pt, fill: gray.darken(40%))[Grundstück] \ #text(size: 12pt, weight: "bold")[#{
      let gs = g("objekt.grundstueck_qm", default: 0)
      if float(gs) > 0 [#gs m²] else [—]
    }]],
    [#text(size: 8pt, fill: gray.darken(40%))[Lage im Haus] \ #text(size: 10.5pt, weight: "bold")[#g("objekt.etagen", default: "—")]],
    [#text(size: 8pt, fill: gray.darken(40%))[Hausgeld] \ #text(size: 10.5pt, weight: "bold")[#g("preise.hausgeld", default: "—")]],
    grid.cell(colspan: 2)[#text(size: 8pt, fill: gray.darken(40%))[Verfügbar] \ #text(size: 10.5pt, weight: "bold")[#g("preise.verfuegbar_ab", default: "—")]])
]
#v(10pt)

// Preiszeile
#grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
  box(fill: bordeaux, width: 100%, inset: (x: 12pt, y: 9pt))[
    #text(fill: white, size: 10pt)[Kaufpreis / Miete]
    #h(1fr)
    #text(fill: white, size: 14pt, weight: "bold")[#g("preise.kaufpreis_oder_miete", default: "auf Anfrage")]
  ])
#v(2pt)
#text(size: 8.5pt, fill: gray.darken(30%))[Courtage: #g("preise.courtage", default: "—")]
#v(10pt)

#grid(columns: (1.2fr, 1fr), column-gutter: 18pt,
  [
    // Beschreibung
    #text(weight: "bold", size: 11pt, fill: bordeaux)[Objektbeschreibung]
    #v(4pt)
    #text(size: 9.5pt)[#g("beschreibung", default: "Beschreibung folgt.")]
  ],
  [
    // Ausstattung
    #text(weight: "bold", size: 11pt, fill: bordeaux)[Ausstattung]
    #v(4pt)
    #if ausstattung.len() > 0 {
      for a in ausstattung [
        #box(baseline: 1pt)[#text(fill: bordeaux, size: 9pt)[▪]] #text(size: 9.5pt)[#a] \
      ]
    } else {
      text(fill: gray, size: 9.5pt)[Keine Angaben.]
    }
  ])
#v(12pt)

// Energieausweis-Balken
#text(weight: "bold", size: 11pt, fill: bordeaux)[Energieausweis]
#v(5pt)
#{
  let klassen = ("A+", "A", "B", "C", "D", "E", "F", "G", "H")
  let farben = (rgb("#0f7a34"), rgb("#3d9a3a"), rgb("#8bbf2f"), rgb("#d5cb27"),
    rgb("#e8a821"), rgb("#e07818"), rgb("#d34e14"), rgb("#c0281a"), rgb("#9c1212"))
  let akt = upper(str(g("energie.klasse", default: "")))
  grid(columns: (1fr,) * 9, column-gutter: 2pt,
    ..klassen.enumerate().map(((i, k)) => {
      let ist = k == akt
      box(width: 100%, fill: farben.at(i), inset: (y: if ist { 8pt } else { 5pt }),
        stroke: if ist { 2pt + black } else { none })[
        #align(center)[#text(fill: white, weight: if ist { "bold" } else { "regular" },
          size: if ist { 11pt } else { 8.5pt })[#k]]
      ]
    }))
}
#v(5pt)
#table(columns: (auto, 1fr, auto, 1fr), stroke: none, inset: 3pt,
  [#text(size: 8.5pt, fill: gray.darken(40%))[Ausweisart:]], [#text(size: 8.5pt, weight: "bold")[#g("energie.ausweisart", default: "—")]],
  [#text(size: 8.5pt, fill: gray.darken(40%))[Endenergiekennwert:]], [#text(size: 8.5pt, weight: "bold")[#g("energie.kennwert", default: "—")]],
  [#text(size: 8.5pt, fill: gray.darken(40%))[Energieträger:]], [#text(size: 8.5pt, weight: "bold")[#g("energie.traeger", default: "—")]],
  [#text(size: 8.5pt, fill: gray.darken(40%))[Baujahr Anlagentechnik:]], [#text(size: 8.5pt, weight: "bold")[#g("energie.baujahr_anlage", default: "—")]])
#v(8pt)

#text(size: 7.5pt, fill: gray.darken(20%))[
  Alle Angaben beruhen auf Informationen des Eigentümers und wurden von uns nach
  bestem Wissen weitergegeben; eine Haftung für die Richtigkeit und Vollständigkeit
  wird nicht übernommen. Zwischenverkauf bzw. -vermietung bleibt vorbehalten.
]
