// Patientenbrief (Entlassung)
// @description: Patientenverständlicher Entlassbrief in einfacher Sprache
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Layout Settings
#let accent = rgb("#2e7d32") // Medical Green
#let text-color = rgb("#2c3e50")
#let light-bg = rgb("#f8fbf8")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: [
    #set text(size: 9pt, fill: gray.darken(50%))
    #grid(columns: (1fr, auto),
      [#g("klinik.abteilung", default: "") \ #g("klinik.name", default: "")],
      [#align(right)[#g("klinik.plz_ort", default: "") \ #g("klinik.strasse", default: "") \ #g("klinik.telefon", default: "")]]
    )
    #v(1pt)
    #line(length: 100%, stroke: 0.5pt + gray)
  ]
)

#set text(font: "Libertinus Serif", size: 11pt, fill: text-color)
#set par(justify: true, leading: 0.65em)

// --- Header Section ---

// Logo Box (Initials)
#let klinik-name = g("klinik.name", default: "K")
#let initials = upper(klinik-name.clusters().slice(0, calc.min(2, klinik-name.clusters().len())).join(""))
#grid(columns: (auto, 1fr),
  box(fill: accent, inset: 8pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 14pt)[#initials]
  ],
  align(right)[
    #text(size: 10pt, weight: "bold")[Entlassungsbericht] \
    #text(size: 9pt, fill: gray.darken(40%))[Datum: #g("brief.datum", default: "")]
  ]
)

#v(12pt)

// Patient Info Box
#block(fill: light-bg, inset: 12pt, radius: 4pt, width: 100%)[
  #set text(size: 10pt)
  #grid(columns: (1fr, 1fr),
    [
      *Patientendaten:* \
      #text(weight: "bold")[#g("patient.name", default: "")] \
      #g("patient.strasse", default: "") \
      #g("patient.plz_ort", default: "")
    ],
    [
      *Aufenthalt:* \
      Geburtstag: #g("patient.geburtsdatum", default: "") \
      Station: #g("aufenthalt.station", default: "") \
      Zeitraum: #g("aufenthalt.aufnahme", default: "") bis #g("aufenthalt.entlassung", default: "")
    ]
  )
]

#v(12pt)

// --- Content Section ---

#text(size: 12pt, weight: "bold", fill: accent)[Liebe/r Patient/in,] \
#v(4pt)
#g("brief.anrede", default: "") \
#v(4pt)

#text(weight: "bold", size: 13pt)[Was wurde bei Ihnen festgestellt?] \
#g("brief.diagnose_einfach", default: "")

#v(8pt)

#text(weight: "bold", size: 13pt)[Was haben wir gemacht?] \
#g("brief.was_wurde_gemacht", default: "")

#v(12pt)

// Medications Section
#text(weight: "bold", size: 13pt, fill: accent)[Ihre Medikamente] \
#v(4pt)
#let meds = data.at("brief.medikamente", default: ())
#if meds.len() > 0 {
  table(
    columns: (1fr, 1fr, 1fr),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { accent.lighten(80%) } else { white },
    table.header(
      [#text(weight: "bold")[Name]],
      [#text(weight: "bold")[Einnahme]],
      [#text(weight: "bold")[Wofür?]]
    ),
    ..meds.map(m => (
      [#m.at("name", default: "")],
      [#m.at("einnahme", default: "")],
      [#m.at("wofuer", default: "")]
    )).flatten()
  )
} else {
  [Es wurden keine speziellen Medikamente verordnet.]
}

#v(12pt)

// Advice & Warnings
#grid(columns: (1fr, 1fr), column-gutter: 15pt,
  [
    #text(weight: "bold", size: 12pt)[Verhalten im Alltag] \
    #v(2pt)
    #g("brief.verhaltenshinweise", default: "")
  ],
  [
    #text(weight: "bold", size: 12pt, fill: rgb("#c62828"))[Wichtige Warnzeichen] \
    #v(2pt)
    #text(fill: rgb("#c62828"))[#g("brief.warnzeichen", default: "")]
  ]
)

#v(12pt)

// Next Steps
#text(weight: "bold", size: 13pt)[Was passiert als Nächstes?] \
#v(4pt)
#let steps = data.at("brief.naechste_schritte", default: ())
#if steps.len() > 0 {
  list(..steps.map(s => [ #s ]))
} else {
  [Bitte halten Sie Rücksprache mit Ihrem Hausarzt.]
}

#v(20pt)

// --- Footer / Signature ---
#align(right)[
  #set text(size: 10pt)
  Mit freundlichen Grüßen \
  #v(4pt)
  #text(weight: "bold")[#g("arzt.name", default: "")] \
  #g("arzt.funktion", default: "") \
  #v(10pt)
  #text(size: 8pt, fill: gray)[Dieses Dokument wurde elektronisch erstellt und ist ohne Unterschrift gültig.]
]
