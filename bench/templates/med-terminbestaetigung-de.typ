// Terminbestätigung Praxis
// @description: Terminbestätigung mit Vorbereitungshinweisen und Mitbringliste
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)

#let accent = rgb("#2d5a27") // Medical Green
#let secondary = rgb("#f4f7f4")

#set text(font: "Libertinus Serif", size: 11pt, lang: "de")

// Header: Logo (Initials) and Praxis Info
#let praxis-name = g("praxis.name", default: "Praxis")
// Guarding against empty strings or none for initials calculation
#let initials = if praxis-name != "" and praxis-name != none {
  let clusters = praxis-name.clusters()
  upper(clusters.slice(0, calc.min(2, clusters.len())).join(""))
} else {
  "P"
}

#grid(
  columns: (auto, 1fr),
  column-gutter: 20pt,
  align: (left, right),
  [
    #box(fill: accent, inset: 8pt, radius: 50%, width: 45pt, height: 45pt)[
      #set align(center + horizon)
      #text(fill: white, weight: "bold", size: 18pt)[#initials]
    ]
  ],
  [
    #text(weight: "bold", size: 13pt, fill: accent)[#praxis-name] \
    #text(size: 10pt)[
      #g("praxis.strasse", default: "") \
      #g("praxis.plz_ort", default: "") \
      #g("praxis.telefon", default: "") \
      #g("praxis.email", default: "")
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 0.5pt + gray)
#v(10pt)

// Recipient
#text(size: 10pt)[
  #g("patient.name", default: "") \
  #g("patient.strasse", default: "") \
  #g("patient.plz_ort", default: "")
]

#v(20pt)

// Subject Line
#text(size: 16pt, weight: "bold")[Terminbestätigung
#if g("termin.art") != "" and g("termin.art") != none [ — #g("termin.art")]
]

#v(10pt)

// Appointment Details Box
#block(fill: secondary, inset: 15pt, radius: 4pt, width: 100%)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 10pt,
    row-gutter: 8pt,
    [
      #text(fill: gray.darken(50%), size: 9pt, weight: "bold")[DATUM & UHRZEIT] \
      #text(size: 12pt, weight: "medium")[#g("termin.datum", default: "—")] um #g("termin.uhrzeit", default: "—") Uhr
    ],
    [
      #text(fill: gray.darken(50%), size: 9pt, weight: "bold")[BEHANDLUNG / ARZT] \
      #text(size: 12pt, weight: "medium")[#g("termin.arzt", default: "—")]
    ],
    [
      #text(fill: gray.darken(50%), size: 9pt, weight: "bold")[ORT / RAUM] \
      #text(size: 12pt, weight: "medium")[#g("termin.raum", default: "—")]
    ],
    [
      #text(fill: gray.darken(50%), size: 9pt, weight: "bold")[DAUER] \
      #text(size: 12pt, weight: "medium")[ca. #g("termin.dauer_min", default: "—") Min.]
    ]
  )
]

#v(20pt)

// Preparation and Checklist
#grid(
  columns: (1fr, 1fr),
  column-gutter: 30pt,
  [
    #text(weight: "bold", size: 12pt, fill: accent)[Vorbereitung]
    #v(5pt)
    // Safe access to nested arrays
    #let hinweise = data.at("hinweise", default: none)
    #let vorbereitung = if type(hinweise) == dictionary { hinweise.at("vorbereitung", default: ()) } else { () }
    #let vorbereitung = if type(vorbereitung) != array { () } else { vorbereitung }
    
    #if vorbereitung.len() > 0 {
      list(..vorbereitung.map(item => text(size: 10pt, str(item))))
    } else {
      text(size: 10pt, style: "italic")[Keine besonderen Vorbereitungen erforderlich.]
    }
  ],
  [
    #text(weight: "bold", size: 12pt, fill: accent)[Bitte mitbringen]
    #v(5pt)
    // Safe access to nested arrays
    #let hinweise = data.at("hinweise", default: none)
    #let mitbringen = if type(hinweise) == dictionary { hinweise.at("mitbringen", default: ()) } else { () }
    #let mitbringen = if type(mitbringen) != array { () } else { mitbringen }

    #if mitbringen.len() > 0 {
      list(..mitbringen.map(item => text(size: 10pt, str(item))))
    } else {
      text(size: 10pt, style: "italic")[Bitte bringen Sie Ihre Versichertenkarte mit.]
    }
  ]
)

#v(20pt)

// Cancellation Policy
#block(width: 100%, stroke: (left: 2pt + accent), inset: (left: 10pt, y: 5pt))[
  #text(size: 10pt, style: "italic")[
    #let absage = g("hinweise.absage_frist", default: "")
    #if absage != "" and absage != none [#absage]
  ]
]

#v(30pt)

// Footer
#align(center)[
  #set text(size: 8pt, fill: gray.darken(50%))
  #g("praxis.name", default: "") | #g("praxis.sprechzeiten", default: "") \
  #v(2pt)
  Diese Bestätigung wurde automatisch erstellt.
]
