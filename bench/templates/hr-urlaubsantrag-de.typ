// Urlaubsantrag
// @description: Antragsformular: Zeitraum, Resturlaub, Vertretung, Genehmigung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let ink = rgb("#1f2430")
#let formgrey = rgb("#eceef1")

#let cb(on) = box(width: 10pt, height: 10pt, stroke: 0.9pt + ink, baseline: 1.5pt,
  align(center + horizon, if on { text(size: 8.5pt, weight: "bold")[X] }))

#let field(lbl, val, w: 100%) = box(width: w)[
  #text(size: 7pt, fill: gray.darken(45%), tracking: 0.5pt)[#upper(lbl)]
  #v(2pt)
  #block(fill: white, stroke: 0.7pt + gray.darken(20%), inset: (x: 7pt, y: 6pt), width: 100%, radius: 1pt)[
    #text(size: 10pt, weight: "medium")[#if val == "" [#h(1pt)] else [#val]]
  ]
]

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2cm, x: 2.2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(1pt)
    Formular P-04 · Urlaubsantrag · Fassung 01/2026 — Ausgefülltes Formular bitte an die Personalabteilung weiterleiten.
  ])
#set text(font: "Arimo", size: 10pt, fill: ink)

// Form header
#grid(columns: (auto, 1fr, auto), align: (left + horizon, center + horizon, right + horizon),
  box(stroke: 1.2pt + ink, inset: 7pt)[#text(weight: "bold", size: 10pt)[P-04]],
  align(center)[
    #text(size: 16pt, weight: "bold", tracking: 1pt)[URLAUBSANTRAG]
    #v(1pt)
    #text(size: 8.5pt, fill: gray.darken(40%))[Antrag auf Erholungs-, Sonder- oder unbezahlten Urlaub]
  ],
  text(size: 8pt, fill: gray.darken(40%))[Personalabteilung \ #align(right)[intern]])
#v(4pt)
#line(length: 100%, stroke: 1.2pt + ink)
#v(12pt)

// Section 1: Antragsteller
#block(fill: formgrey, inset: (x: 8pt, y: 5pt), width: 100%)[
  #text(weight: "bold", size: 9pt)[1 — Angaben zur Person]
]
#v(6pt)
#grid(columns: (2fr, 1fr, 2fr), column-gutter: 10pt,
  field("Name, Vorname", g("antragsteller.name")),
  field("Personal-Nr.", g("antragsteller.personalnr")),
  field("Abteilung", g("antragsteller.abteilung")))
#v(12pt)

// Section 2: Urlaub
#block(fill: formgrey, inset: (x: 8pt, y: 5pt), width: 100%)[
  #text(weight: "bold", size: 9pt)[2 — Beantragter Urlaub]
]
#v(6pt)
#grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt,
  field("vom (erster Urlaubstag)", g("urlaub.von")),
  field("bis (letzter Urlaubstag)", g("urlaub.bis")),
  field("Arbeitstage", str(g("urlaub.arbeitstage", default: ""))))
#v(8pt)
#let art = lower(str(g("urlaub.art", default: "")))
#text(size: 7pt, fill: gray.darken(45%), tracking: 0.5pt)[URLAUBSART]
#v(3pt)
#grid(columns: 4, column-gutter: 18pt,
  [#cb(art.contains("erholung")) Erholungsurlaub],
  [#cb(art.contains("sonder")) Sonderurlaub],
  [#cb(art.contains("unbezahlt")) unbezahlter Urlaub],
  [#cb(art != "" and not (art.contains("erholung") or art.contains("sonder") or art.contains("unbezahlt"))) Sonstiges])
#v(10pt)
#grid(columns: (1fr, 1fr, 2fr), column-gutter: 10pt,
  field("Resturlaub vorher (Tage)", str(g("urlaub.resturlaub_vorher", default: ""))),
  field("Resturlaub nachher (Tage)", str(g("urlaub.resturlaub_nachher", default: ""))),
  box())
#v(12pt)

// Section 3: Vertretung
#block(fill: formgrey, inset: (x: 8pt, y: 5pt), width: 100%)[
  #text(weight: "bold", size: 9pt)[3 — Vertretung während der Abwesenheit]
]
#v(6pt)
#grid(columns: (2fr, 2fr), column-gutter: 10pt,
  field("Vertretung durch", g("vertretung.name")),
  [
    #text(size: 7pt, fill: gray.darken(45%), tracking: 0.5pt)[VERTRETUNG EINVERSTANDEN]
    #v(6pt)
    #let best = lower(str(g("vertretung.bestaetigt", default: "")))
    #cb(best == "ja" or best == "yes" or best == "true") ja
    #h(16pt)
    #cb(best == "nein" or best == "no") nein
  ])
#v(12pt)

// Section 4: Genehmigung
#block(fill: formgrey, inset: (x: 8pt, y: 5pt), width: 100%)[
  #text(weight: "bold", size: 9pt)[4 — Entscheidung der/des Vorgesetzten]
]
#v(6pt)
#let status = lower(str(g("genehmigung.status", default: "")))
#grid(columns: (auto, auto, 1fr), column-gutter: 22pt, align: horizon,
  [#cb(status.contains("genehmigt") and not status.contains("nicht")) genehmigt],
  [#cb(status.contains("abgelehnt") or status.contains("nicht")) abgelehnt],
  box())
#v(10pt)
#grid(columns: (2fr, 1fr, 2fr), column-gutter: 10pt,
  field("Vorgesetzte/r", g("genehmigung.vorgesetzter")),
  field("Datum", g("genehmigung.datum")),
  [
    #text(size: 7pt, fill: gray.darken(45%), tracking: 0.5pt)[UNTERSCHRIFT VORGESETZTE/R]
    #v(18pt)
    #line(length: 100%, stroke: 0.7pt + ink)
  ])
#v(16pt)
#grid(columns: (2fr, 2fr), column-gutter: 24pt,
  [
    #v(14pt)
    #line(length: 100%, stroke: 0.7pt + ink)
    #v(-2pt)
    #text(size: 8pt, fill: gray.darken(35%))[Datum, Unterschrift Antragsteller/in]
  ],
  [
    #v(14pt)
    #line(length: 100%, stroke: 0.7pt + ink)
    #v(-2pt)
    #text(size: 8pt, fill: gray.darken(35%))[Datum, Unterschrift Vertretung]
  ])
