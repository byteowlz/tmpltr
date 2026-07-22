// Privatärztliche Rechnung (GOÄ)
// @description: GOÄ-Rechnung mit Ziffern, Faktor, Betrag
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, sym: "$") = {
  let v = calc.round(float(x), digits: 2)
  let neg = v < 0
  let a = calc.abs(v)
  let i = int(a)
  let c = int(calc.round((a - i) * 100))
  if c == 100 { i = i + 1; c = 0 }
  let s = str(i)
  let out = ""
  let n = s.clusters().len()
  for (k, ch) in s.clusters().enumerate() {
    out = out + ch
    let rem = n - k - 1
    if rem > 0 and calc.rem(rem, 3) == 0 { out = out + "," }
  }
  sym + (if neg { "-" } else { "" }) + out + "." + (if c < 10 { "0" } else { "" }) + str(c)
}

#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

// Configuration
#let accent = rgb("#2c3e50")
#let secondary = rgb("#7f8c8d")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  footer: [
    #set text(size: 8pt, fill: secondary)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [#g("arzt.name") \ #g("arzt.fachrichtung")],
      align(right)[#g("arzt.strasse"), #g("arzt.plz_ort") \ IBAN: #g("arzt.iban")]
    )
  ]
)

#set text(font: "Libertinus Serif", size: 10.5pt)

// Header: Doctor Info
#grid(columns: (1fr, auto),
  [
    #text(size: 18pt, weight: "bold", fill: accent)[#g("arzt.name")] \
    #text(size: 11pt, style: "italic", fill: secondary)[#g("arzt.fachrichtung")]
  ],
  align(right)[
    #text(weight: "bold")[Rechnung Nr. #g("rechnung.nummer")] \
    #text(size: 10pt)[Datum: #g("rechnung.datum")]
  ]
)

#v(1.5em)

// Patient Info Block
#rect(width: 100%, stroke: 0.5pt + gray, inset: 10pt, radius: 2pt)[
  #grid(columns: (1fr, 1fr),
    [
      #text(size: 8pt, weight: "bold", fill: secondary, tracking: 1pt)[RECHNUNGSADRESSE] \
      #v(4pt)
      #text(size: 11pt, weight: "bold")[#g("patient.name")] \
      #g("patient.strasse") \
      #g("patient.plz_ort")
    ],
    [
      #text(size: 8pt, weight: "bold", fill: secondary, tracking: 1pt)[PATIENTENDATEN] \
      #v(4pt)
      #text(size: 11pt, weight: "bold")[#g("patient.name")] \
      Geburtsdatum: #g("patient.geburtsdatum")
    ]
  )
]

#v(1.5em)

// Medical Context
#text(weight: "bold", size: 10pt)[Behandlungszeitraum:] #g("rechnung.behandlungszeitraum") \
#text(weight: "bold", size: 10pt)[Diagnose:] #g("rechnung.diagnose")

#v(2em)

// Table of Services
#let items = data.at("positionen", default: ())
#let total_sum = items.fold(0.0, (acc, it) => acc + float(it.at("betrag", default: 0)))

#if items.len() > 0 {
  table(
    columns: (auto, auto, 1fr, auto, auto, auto),
    stroke: none,
    inset: 6pt,
    align: (center, center, left, center, center, right),
    table.header(
      line(length: 100%, stroke: 1pt + accent),
      [#text(weight: "bold")[Datum]],
      [#text(weight: "bold")[Leistung]],
      [#text(weight: "bold")[Ziffer]],
      [#text(weight: "bold")[Faktor]],
      [#text(weight: "bold")[Betrag]],
      line(length: 100%, stroke: 1pt + accent),
    ),
    ..items.map(((it)) => (
      [#it.at("datum", default: "")],
      [#it.at("ziffer", default: "")],
      [#it.at("leistung", default: "")],
      [#it.at("faktor", default: "")],
      [#geld(it.at("betrag", default: 0))],
      [], // placeholder for alignment
    )).flatten()
  )
  
  // Manual addition of total to avoid row mismatch in flatten
  // We use a separate table for totals for cleaner layout
  v(1em)
  align(right)[
    #table(
      columns: (auto, auto),
      stroke: none,
      inset: 4pt,
      align: (right, right),
      [#text(size: 11pt)[Gesamtbetrag:]],
      [#text(size: 13pt, weight: "bold", fill: accent)[#geld(total_sum)]]
    )
  ]
} else {
  text(style: "italic", fill: secondary)[Keine Rechnungspositionen vorhanden.]
}

#v(3em)

// Footer/Terms
#text(size: 9pt, style: "italic", fill: secondary)[
  #g("gesamtbetrag_hinweis")
]

#v(1em)

#grid(columns: (1fr, 1fr),
  [
    #text(size: 8pt, fill: secondary)[Zahlungsinformationen:] \
    #text(size: 9pt)[IBAN: #g("arzt.iban")] \
    #text(size: 9pt)[BIC: #g("arzt.bic")]
  ],
  align(right)[
    #text(size: 8pt, fill: secondary)[Unterschrift / Stempel:] \
    #v(2em)
    #line(length: 80%, stroke: 0.5pt + gray)
  ]
)
