// Gefährdungsbeurteilung
// @description: Arbeitsschutz-Gefährdungsbeurteilung mit Risikobewertung und Maßnahmen
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration
#let accent = rgb("#2e7d32") // Safety Green
#let danger = rgb("#c62828")
#let warning = rgb("#f9a825")
#let safe = rgb("#2e7d32")
#let light-gray = rgb("#757575")

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2.5cm, left: 2cm, right: 2cm),
  header: [
    #set text(size: 8pt, fill: gray)
    #grid(columns: (1fr, 1fr),
      [Dokument: #g("beurteilung.nummer", default: "—")],
      align(right)[Erstellt am: #g("beurteilung.datum", default: "—")]
    )
    #line(length: 100%, stroke: 0.5pt + gray)
  ],
  footer: [
    #set text(size: 8pt, fill: gray)
    #line(length: 100%, stroke: 0.5pt + gray)
    #grid(columns: (1fr, 1fr),
      [#g("betrieb.firma", default: "—")],
      align(right)[#context counter(page).display()]
    )
  ]
)

#set text(font: "Libertinus Serif", size: 10pt)

// Helper for Risk Class Colors
#let risk-color(klass) = {
  let k = lower(klass)
  if k == "hoch" { danger }
  else if k == "mittel" { warning }
  else if k == "gering" { safe }
  else { black }
}

// --- Header Section ---
#grid(columns: (auto, 1fr), column-gutter: 15pt,
  box(fill: accent, inset: 12pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 18pt)[GB]
  ],
  [
    #text(size: 18pt, weight: "bold", fill: accent)[Gefährdungsbeurteilung] \
    #text(size: 11pt, style: "italic")[gemäß § 5 ArbSchG]
  ]
)

#v(10pt)

// --- Betrieb & Kontext ---
#rect(width: 100%, stroke: 0.5pt + gray, radius: 2pt, inset: 10pt)[
  #grid(columns: (1fr, 1fr), column-gutter: 20pt,
    [
      #text(weight: "bold", size: 9pt, fill: accent)[BETRIEB & BEREICH] \
      #v(4pt)
      *Firma:* #g("betrieb.firma", default: "—") \
      *Bereich:* #g("betrieb.bereich", default: "—") \
      *Arbeitsplatz:* #g("betrieb.arbeitsplatz", default: "—") \
      *Tätigkeit:* #g("betrieb.taetigkeit", default: "—")
    ],
    [
      #text(weight: "bold", size: 9pt, fill: accent)[BEURTEILUNGSDETAILS] \
      #v(4pt)
      *Nr.:* #g("beurteilung.nummer", default: "—") \
      *Datum:* #g("beurteilung.datum", default: "—") \
      *Ersteller:* #g("beurteilung.ersteller", default: "—") \
      *Nächste Prüfung:* #g("beurteilung.naechste_pruefung", default: "—")
    ]
  )
]

#v(15pt)

// --- Gefährdungsliste ---
#text(size: 13pt, weight: "bold")[Risikobewertung und Maßnahmenplan]
#v(5pt)

#let items = if data.at("gefaehrdungen", default: none) != none { data.at("gefaehrdungen", default: ()) } else { () }

#if items.len() > 0 {
  table(
    columns: (auto, 1fr, auto, 1fr, auto),
    align: (center, left, center, left, center),
    stroke: 0.5pt + gray,
    inset: 7pt,
    fill: (x, y) => if y == 0 { rgb("#f0f4f0") } else { white },
    table.header(
      [#text(weight: "bold")[Risiko]],
      [#text(weight: "bold")[Gefährdung]],
      [#text(weight: "bold")[Klasse]],
      [#text(weight: "bold")[Maßnahmen & Verantwortlichkeit]],
      [#text(weight: "bold")[Status]],
    ),
    ..items.map((it) => (
      // Risiko Icon/Indicator
      [#circle(radius: 4pt, fill: risk-color(it.at("risiko_klasse", default: "")) )],
      // Gefährdung
      [#text(weight: "bold")[#it.at("gefaehrdung", default: "—")]],
      // Klasse
      [#text(fill: risk-color(it.at("risiko_klasse", default: "")), weight: "bold")[#it.at("risiko_klasse", default: "—")]],
      // Maßnahmen
      [
        #it.at("schutzmassnahme", default: "—") \
        #v(2pt)
        #text(size: 8.5pt, fill: light-gray)[Verantw.: #it.at("verantwortlich", default: "—")] \
        #text(size: 8.5pt, fill: light-gray)[Frist: #it.at("frist", default: "—")]
      ],
      // Status
      [#it.at("wirksam", default: "—")]
    )).flatten()
  )
} else {
  block(width: 100%, inset: 10pt, stroke: 1pt + gray, align(center, [Keine Gefährdungen erfasst.]))
}

#v(30pt)

// --- Unterschrift ---
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #set text(size: 9pt)
    #text(weight: "bold")[Bestätigung der Maßnahmen] \
    #v(5pt)
    Die oben genannten Maßnahmen wurden geprüft und sind in der angegebenen Form umzusetzen.
  ],
  [
    #set text(size: 9pt)
    #v(10pt)
    #line(length: 100%, stroke: 0.5pt + black) \
    #grid(columns: (1fr, 1fr),
      [#g("unterschrift.ort", default: "—")],
      [#g("unterschrift.datum", default: "—")]
    )
    #v(2pt)
    #text(weight: "bold")[#g("unterschrift.name", default: "—")] \
    (Unterschrift Verantwortlicher)
  ]
)
