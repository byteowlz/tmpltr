// EU-Konformitätserklärung
// @description: CE-Konformitätserklärung mit Richtlinien, Normen, Unterzeichner
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)

#set text(font: "Libertinus Serif", size: 11pt, lang: "de")

// Accent color: Deep Navy/Steel for a formal certificate look
#let accent = rgb("#2c3e50")

// Header: CE Mark Placeholder (Text initials)
#let manufacturer-name = g("hersteller.name", default: "··")
#let name-clusters = manufacturer-name.clusters()
// Guard array indexing for initials
#let initials-count = calc.min(2, name-clusters.len())
#let initials = if initials-count > 0 {
  upper(name-clusters.slice(0, initials-count).join(""))
} else {
  ""
}

#align(center)[
  #box(
    fill: accent,
    inset: 12pt,
    radius: 2pt,
    width: 60pt,
    height: 60pt,
    align(center + horizon)[
      #text(fill: white, weight: "bold", size: 24pt)[#initials]
    ]
  )
  #v(12pt)
  #text(size: 22pt, weight: "bold", fill: accent)[EU-KONFORMITÄTSERKLÄRUNG]
  #v(4pt)
  #text(size: 12pt, style: "italic", fill: gray.darken(50%))[Declaration of Conformity]
]

#v(20pt)

// Section: Manufacturer
#block(width: 100%, stroke: (bottom: 0.5pt + gray), inset: (bottom: 4pt))[
  #text(weight: "bold", size: 10pt, fill: accent)[HERSTELLER / MANUFACTURER] \
  #v(4pt)
  #g("hersteller.name", default: "") \
  #g("hersteller.strasse", default: "") \
  #g("hersteller.plz_ort", default: "")
]

#v(12pt)

// Section: Product
#block(width: 100%, stroke: (bottom: 0.5pt + gray), inset: (bottom: 4pt))[
  #text(weight: "bold", size: 10pt, fill: accent)[PRODUKTINFORMATIONEN / PRODUCT DETAILS] \
  #v(4pt)
  #grid(columns: (1fr, 1fr), column-gutter: 20pt,
    [
      *Bezeichnung:* \
      #g("produkt.bezeichnung", default: "") \
      *Typ:* \
      #g("produkt.typ", default: "")
    ],
    [
      *Seriennummer:* \
      #g("produkt.seriennummer_bereich", default: "") \
      *Baujahr:* \
      #g("produkt.baujahr", default: "")
    ]
  )
]

#v(12pt)

// Section: Declaration & Directives
#text(weight: "bold", size: 10pt, fill: accent)[RECHTLICHE GRUNDLAGEN / DIRECTIVES]
#v(6pt)
#text(size: 10pt)[
  Die alleinige Verantwortung für die Konformität dieses Produkts trägt der oben genannte Hersteller. Das Produkt entspricht den folgenden EU-Richtlinien:
]

#let erklaerung-data = data.at("erklaerung", default: ())
// Fixed: Use 'dictionary' type instead of 'dict' variable
#let directives = if type(erklaerung-data) == dictionary { erklaerung-data.at("richtlinien", default: ()) } else { () }

#if type(directives) == array and directives.len() > 0 {
  list(..directives.map(d => [ #d ]))
}

#v(12pt)

// Section: Standards
#text(weight: "bold", size: 10pt, fill: accent)[ANGWENDETE HARMONISIERTE NORMEN / APPLIED STANDARDS]
#v(6pt)
#let norms = if type(erklaerung-data) == dictionary { erklaerung-data.at("normen", default: ()) } else { () }

#if type(norms) == array and norms.len() > 0 {
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    ..norms.map(n => [ #n ]).flatten()
  )
}

#v(12pt)

// Section: Notified Body
#if g("erklaerung.benannte_stelle", default: "") != "" {
  block(fill: gray.lighten(90%), inset: 10pt, radius: 2pt, width: 100%)[
    #text(weight: "bold", size: 9pt)[Benannte Stelle / Notified Body: #g("erklaerung.benannte_stelle", default: "")] \
    #text(size: 9pt)[Zertifikatsnummer: #g("erklaerung.zertifikat_nr", default: "")]
  ]
}

#v(30pt)

// Section: Signature
#grid(columns: (1fr, 1fr),
  [
    #text(size: 9pt, fill: gray.darken(50%))[Ausgestellt in:] \
    #g("unterzeichner.ort", default: "") \
    #v(4pt)
    #g("unterzeichner.datum", default: "")
  ],
  align(right)[
    #set text(size: 10pt)
    #text(weight: "bold")[Unterschrift / Signature] \
    #v(10pt)
    #line(length: 60%, stroke: 0.5pt + black) \
    #v(2pt)
    #g("unterzeichner.name", default: "") \
    #text(size: 9pt, fill: gray.darken(50%))[#g("unterzeichner.funktion", default: "")]
  ]
)

#v(1fr)

// Footer
#align(center)[
  #set text(size: 8pt, fill: gray)
  Dieses Dokument wurde elektronisch erstellt und ist ohne handschriftliche Unterschrift gültig, sofern die Identität des Unterzeichners verifiziert ist.
]
