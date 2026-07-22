// Wohnungsübergabeprotokoll
// @description: Übergabe mit Zählerständen, Mängeln, Schlüsseln
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let zaehler = data.at("zaehler", default: ())
#let raeume = data.at("raeume", default: ())
#let schluessel = data.at("schluessel", default: ())
#let dunkelblau = rgb("#1f3a5f")

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 2cm, x: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    Wohnungsübergabeprotokoll · #g("wohnung.strasse"), #g("wohnung.plz_ort") ·
    #g("uebergabe.datum")
    #h(1fr) Seite 1 von 1
  ])
#set text(font: "Arimo", size: 9.5pt, lang: "de")

// Formularkopf
#box(width: 100%, stroke: 1.5pt + dunkelblau, inset: 0pt, clip: true)[
  #box(width: 100%, fill: dunkelblau, inset: (x: 12pt, y: 8pt))[
    #text(fill: white, weight: "bold", size: 14pt, tracking: 0.06em)[WOHNUNGSÜBERGABEPROTOKOLL]
    #h(1fr)
    #text(fill: white, size: 9pt)[#g("uebergabe.art", default: "Übergabe")]
  ]
  #grid(columns: (1fr, 1fr), inset: 8pt, stroke: (x, y) => (
      left: if x > 0 { 0.5pt + gray.lighten(30%) } else { none },
      bottom: 0.5pt + gray.lighten(30%)),
    [#text(size: 7.5pt, fill: gray.darken(40%))[VERMIETER / ÜBERGEBENDE PARTEI] \ #v(1pt) #text(weight: "bold")[#g("vermieter.name", default: "—")]],
    [#text(size: 7.5pt, fill: gray.darken(40%))[MIETER / ÜBERNEHMENDE PARTEI] \ #v(1pt) #text(weight: "bold")[#g("mieter.name", default: "—")]],
    [#text(size: 7.5pt, fill: gray.darken(40%))[MIETOBJEKT] \ #v(1pt) #g("wohnung.strasse"), #g("wohnung.plz_ort") · #g("wohnung.etage")],
    [#text(size: 7.5pt, fill: gray.darken(40%))[DATUM / UHRZEIT DER ÜBERGABE] \ #v(1pt) #g("uebergabe.datum", default: "—")])
]
#v(12pt)

// 1. Zählerstände
#text(weight: "bold", size: 11pt, fill: dunkelblau)[1. Zählerstände zum Zeitpunkt der Übergabe]
#v(4pt)
#if zaehler.len() > 0 {
  table(columns: (1fr, auto, auto),
    align: (left, left, right),
    inset: (x: 8pt, y: 5pt),
    stroke: 0.5pt + gray.lighten(20%),
    fill: (_, row) => if row == 0 { rgb("#e8edf4") } else { white },
    table.header(
      [#text(weight: "bold", size: 8.5pt)[Zähler]],
      [#text(weight: "bold", size: 8.5pt)[Zählernummer]],
      [#text(weight: "bold", size: 8.5pt)[Zählerstand]]),
    ..zaehler.map(z => (
      [#z.at("typ", default: "")],
      [#z.at("nummer", default: "—")],
      [*#z.at("stand", default: "—")*],
    )).flatten())
} else {
  text(fill: gray)[Keine Zähler erfasst.]
}
#v(10pt)

// 2. Zustand der Räume
#text(weight: "bold", size: 11pt, fill: dunkelblau)[2. Zustand der Räume]
#v(4pt)
#if raeume.len() > 0 {
  table(columns: (auto, auto, 1fr),
    align: (left, center, left),
    inset: (x: 8pt, y: 5pt),
    stroke: 0.5pt + gray.lighten(20%),
    fill: (_, row) => if row == 0 { rgb("#e8edf4") } else if calc.even(row) { rgb("#f7f9fb") } else { white },
    table.header(
      [#text(weight: "bold", size: 8.5pt)[Raum]],
      [#text(weight: "bold", size: 8.5pt)[Zustand]],
      [#text(weight: "bold", size: 8.5pt)[Festgestellte Mängel]]),
    ..raeume.map(r => {
      let m = r.at("maengel", default: "keine")
      (
        [#r.at("raum", default: "")],
        [#r.at("zustand", default: "—")],
        [#if m == "keine" [#text(fill: gray.darken(20%))[keine]] else [#text(weight: "bold")[#m]]],
      )
    }).flatten())
} else {
  text(fill: gray)[Keine Räume erfasst.]
}
#v(10pt)

// 3. Schlüssel
#text(weight: "bold", size: 11pt, fill: dunkelblau)[3. Übergebene Schlüssel]
#v(4pt)
#if schluessel.len() > 0 {
  grid(columns: (1fr,) * calc.min(4, calc.max(1, schluessel.len())), column-gutter: 6pt,
    ..schluessel.map(s => box(stroke: 0.5pt + gray.lighten(20%), inset: 8pt, width: 100%)[
      #align(center)[
        #text(size: 8pt, fill: gray.darken(40%))[#s.at("art", default: "Schlüssel")] \
        #text(size: 13pt, weight: "bold")[#s.at("anzahl", default: 0) Stück]
      ]
    ]))
} else {
  text(fill: gray)[Keine Schlüssel erfasst.]
}
#v(12pt)

// Bestätigung + Unterschriften
#box(width: 100%, fill: rgb("#f2f4f7"), inset: 10pt)[
  #text(size: 8.5pt)[
    Beide Parteien bestätigen durch ihre Unterschrift die Richtigkeit der oben
    festgehaltenen Zählerstände, Raumzustände und Schlüsselanzahl. Über die
    aufgeführten Mängel hinaus wurden keine weiteren Schäden festgestellt.
    Nachträglich festgestellte, verdeckte Mängel bleiben hiervon unberührt.
  ]
]
#v(18pt)

#grid(columns: (1fr, 1fr), column-gutter: 32pt,
  [
    #line(length: 100%, stroke: 0.7pt + black)
    #v(2pt)
    #text(size: 8pt)[Ort, Datum: #g("unterschrift.ort", default: "—"), #g("unterschrift.datum", default: "—")] \
    #text(size: 8pt, fill: gray.darken(40%))[Unterschrift Vermieter / Übergebende Partei]
  ],
  [
    #line(length: 100%, stroke: 0.7pt + black)
    #v(2pt)
    #text(size: 8pt)[Ort, Datum: #g("unterschrift.ort", default: "—"), #g("unterschrift.datum", default: "—")] \
    #text(size: 8pt, fill: gray.darken(40%))[Unterschrift Mieter / Übernehmende Partei]
  ])
