// Physiotherapie-Behandlungsplan
// @description: Verordnung mit Behandlungen, Terminen, Zuzahlung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm)
)

// Styling
#let accent-color = rgb("#2d5a27") // Medical green
#let secondary-color = rgb("#f0f4f0")
#set text(font: "Libertinus Serif", size: 10.5pt)

// Header
#grid(columns: (1fr, auto),
  [
    #text(size: 18pt, weight: "bold", fill: accent-color)[Behandlungsplan] \
    #text(size: 11pt, style: "italic", fill: gray.darken(50%))[Physiotherapie-Verordnung]
  ],
  align(right)[
    #text(weight: "bold")[#g("praxis.name")] \
    #text(size: 9pt)[#g("praxis.strasse") \ #g("praxis.plz_ort") \ Tel: #g("praxis.telefon")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent-color)
#v(10pt)

// Patient Section
#block(fill: secondary-color, inset: 10pt, radius: 4pt)[
  #grid(columns: (1fr, 1fr), column-gutter: 20pt,
    [
      #text(weight: "bold", fill: accent-color)[Patientendaten] \
      #v(4pt)
      #text(size: 11pt, weight: "medium")[#g("patient.name")] \
      Geburtsdatum: #g("patient.geburtsdatum") \
      Krankenkasse: #g("patient.krankenkasse")
    ],
    [
      #text(weight: "bold", fill: accent-color)[Verordnungsdetails] \
      #v(4pt)
      Datum: #g("verordnung.verordnungsdatum") \
      Arzt: #g("verordnung.arzt")
    ]
  )
]

#v(15pt)

// Medical Details
#text(weight: "bold", size: 11pt, fill: accent-color)[Medizinische Angaben]
#v(5pt)
#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: 4pt,
  [*Diagnose:*], [#g("verordnung.diagnose")],
  [*Heilmittel:*], [#g("verordnung.heilmittel")],
  [*Umfang:*], [#g("verordnung.anzahl") #g("verordnung.frequenz")]
)

#v(15pt)

// Appointment Table
#text(weight: "bold", size: 11pt, fill: accent-color)[Terminübersicht]
#v(5pt)

#let termine = if data.at("termine", default: ()) != none { data.at("termine", default: ()) } else { () }

#if termine.len() > 0 {
  table(
    columns: (1fr, 1fr, 2fr),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + accent-color) } else { (bottom: 0.5pt + gray.lighten(50%)) },
    inset: 8pt,
    align: (left, left, left),
    fill: (x, y) => if y == 0 { secondary-color } else { white },
    [*Datum*], [*Uhrzeit*], [*Therapeut*],
    ..termine.map(((it)) => (
      [#if it.at("datum", default: "—") != none { it.at("datum", default: "—") } else { "—" }],
      [#if it.at("uhrzeit", default: "—") != none { it.at("uhrzeit", default: "—") } else { "—" }],
      [#if it.at("therapeut", default: "—") != none { it.at("therapeut", default: "—") } else { "—" }]
    )).flatten()
  )
} else {
  text(style: "italic", fill: gray)[Keine Termine erfasst.]
}

#v(20pt)

// Payment/Footer
#rect(width: 100%, stroke: 0.5pt + gray, inset: 10pt, radius: 2pt)[
  #set text(size: 9pt)
  #grid(columns: (1fr, auto),
    [
      #text(weight: "bold")[Zahlungsinformationen / Zuzahlung:] \
      #g("zuzahlung")
    ],
    align(right)[
      #text(size: 8pt, fill: gray.darken(50%))[Dokument erstellt am #datetime.today().display("[day].[month].[year]")]
    ]
  )
]

#v(1fr)

#align(center)[
  #text(size: 8pt, fill: gray.darken(50%))[
    Dies ist ein Behandlungsplan zur Information des Patienten. 
    Bitte erscheinen Sie pünktlich zu Ihren Terminen.
  ]
]
