// Arbeitsunfähigkeitsbescheinigung (AU)
// @description: AU mit Erst-/Folgebescheinigung, Zeitraum, Diagnose-Codes
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm)
)

#set text(font: "Libertinus Serif", size: 10pt)

// Colors and Styling
#let accent = rgb("#2c3e50")
#let border-color = rgb("#bdc3c7")

// Header: Doctor Info
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(weight: "bold", size: 12pt, fill: accent)[#g("arzt.name", default: "")] \
    #text(size: 9pt)[
      #g("arzt.strasse", default: "") \
      #g("arzt.plz_ort", default: "") \
      BSNR: #g("arzt.bsnr", default: "") | LANR: #g("arzt.lanr", default: "")
    ]
  ],
  [
    #text(size: 10pt, weight: "bold")[Ärztliche Bescheinigung] \
    #text(size: 9pt)[Ausstellungsdatum: #g("ausstellung.datum", default: "")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent)
#v(10pt)

// Title
#align(center)[
  #text(size: 16pt, weight: "bold", fill: accent)[Arbeitsunfähigkeitsbescheinigung] \
  #text(size: 11pt, style: "italic")[#g("au.art", default: "Bescheinigung")]
]

#v(15pt)

// Patient Section
#rect(width: 100%, stroke: 0.5pt + border-color, inset: 10pt, radius: 2pt)[
  #text(weight: "bold", size: 10pt, fill: accent)[Patientendaten]
  #v(5pt)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 20pt,
    [
      #text(size: 8pt, fill: gray.darken(50%))[Name, Anschrift:] \
      #g("patient.name", default: "")
    ],
    [
      #text(size: 8pt, fill: gray.darken(50%))[Geburtsdatum:] \
      #g("patient.geburtsdatum", default: "") \
      #v(4pt)
      #text(size: 8pt, fill: gray.darken(50%))[Versicherten-Nr.:] \
      #g("patient.versichertennr", default: "")
    ]
  )
  #v(5pt)
  #text(size: 8pt, fill: gray.darken(50%))[Krankenkasse:] \
  #g("patient.krankenkasse", default: "")
]

#v(20pt)

// Medical Details Section
#text(weight: "bold", size: 11pt, fill: accent)[Feststellungen zur Arbeitsunfähigkeit]
#v(5pt)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 15pt,
  stroke: 0.5pt + border-color,
  inset: 8pt,
  [
    #text(size: 8pt, fill: gray.darken(50%))[Festgestellt am:] \
    #g("au.festgestellt_am", default: "")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Arbeitsunfähig seit:] \
    #g("au.arbeitsunfaehig_seit", default: "")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Voraussichtlich bis:] \
    #g("au.voraussichtlich_bis", default: "")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Status:] \
    #g("au.art", default: "")
  ]
)

#v(20pt)

// Diagnosis Section
#text(weight: "bold", size: 11pt, fill: accent)[Diagnosen (ICD-10)]
#v(5pt)

// Safely extract diagnoses array
#let au_data = data.at("au", default: ())
#let diagnoses = if type(au_data) == dictionary { 
  au_data.at("diagnosen_icd", default: ()) 
} else { 
  () 
}

#if type(diagnoses) == array and diagnoses.len() > 0 {
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 10pt,
    row-gutter: 8pt,
    ..diagnoses.map(d => {
      rect(width: 100%, stroke: 0.5pt + border-color, inset: 5pt)[
        #set text(size: 9pt)
        #d
      ]
    })
  )
} else {
  text(size: 9pt, style: "italic", fill: gray)[Keine Diagnosen angegeben.]
}

#v(40pt)

// Signature Area
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 9pt, fill: gray.darken(50%))[Hinweis:] \
    #text(size: 8pt)[Diese Bescheinigung dient der Vorlage beim Arbeitgeber und der Krankenkasse. Eine ärztliche Begutachtung kann angeordnet werden.]
  ],
  align(right)[
    #v(10pt)
    #line(length: 60%, stroke: 0.5pt + black) \
    #text(size: 9pt)[Stempel / Unterschrift des Arztes]
  ]
)

#v(1fr)

// Footer
#align(center)[
  #text(size: 7pt, fill: gray.darken(50%))[
    Dokument automatisch erstellt am #g("ausstellung.datum", default: "") · System-ID: AU-#g("patient.versichertennr", default: "000000")
  ]
]
