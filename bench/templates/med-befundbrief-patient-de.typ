// Befundmitteilung an Patienten
// @description: Untersuchungsergebnis in Laiensprache mit Einordnung und Empfehlung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Money helper (required by rules even if not used in this specific template)
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

// Theme configuration
#let accent = rgb("#2d5a27") // Medical green
#let text-main = rgb("#333333")
#let text-muted = rgb("#666666")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Libertinus Serif", size: 11pt, fill: text-main)
#set par(justify: true)

// Header: Medical Logo (Initials) and Practice Info
#let praxis-name = g("praxis.name", default: "Medizinische Praxis")
// Guard array indexing for initials
#let initials-chars = praxis-name.clusters()
#let initials = upper(initials-chars.slice(0, calc.min(2, initials-chars.len())).join(""))

#grid(
  columns: (auto, 1fr),
  column-gutter: 20pt,
  box(fill: accent, inset: 8pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 18pt)[#initials]
  ],
  align(right)[
    #text(weight: "bold", size: 12pt)[#g("praxis.name")] \
    #text(size: 10pt)[#g("praxis.fachrichtung")] \
    #text(size: 10pt)[#g("praxis.arzt")] \
    #text(size: 10pt)[#g("praxis.strasse"), #g("praxis.plz_ort")] \
    #text(size: 10pt)[Tel: #g("praxis.telefon")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 0.5pt + gray)
#v(15pt)

// Recipient and Date
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 9pt, weight: "bold", fill: text-muted)[AN: #g("patient.name")] \
    #g("patient.strasse") \
    #g("patient.plz_ort")
  ],
  align(right)[
    #text(size: 10pt)[#g("praxis.plz_ort"), #g("praxis.name").split(" ").last()] \
    #v(4pt)
    #text(size: 10pt)[Datum: #g("befund.datum")]
  ]
)

#v(20pt)

// Subject Line
#text(size: 14pt, weight: "bold", fill: accent)[
  Befundmitteilung: #g("befund.untersuchung")
]
#v(4pt)
#text(size: 10pt, style: "italic")[Untersuchungsdatum: #g("befund.untersuchungsdatum")]

#v(15pt)

// Salutation
Sehr geehrte(r) #g("patient.name"),

#v(8pt)

// Main Result (Layman's terms)
#text(weight: "bold")[Zusammenfassung des Ergebnisses:] \
#g("befund.ergebnis_einfach")

#v(12pt)

// Detailed Table
#text(weight: "bold")[Detaillierte Befundwerte:]
#v(5pt)
#let details = data.at("untersuchungs_details", default: ())
#if details.len() > 0 {
  table(
    columns: (1fr, 1fr, auto),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      [#text(weight: "bold")[Parameter]],
      [#text(weight: "bold")[Befund]],
      [#text(weight: "bold")[Status]]
    ),
    ..details.map(it => (
      [#it.at("parameter", default: "")],
      [#it.at("wert", default: "")],
      [#if it.at("status", default: "") == "auffällig" [
        #text(fill: red.darken(50%), weight: "bold")[#it.at("status")]
      ] else [
        #text(fill: accent, weight: "bold")[#it.at("status")]
      ]]
    )).flatten()
  )
}

#v(15pt)

// Interpretation and Recommendation
#block(fill: accent.lighten(90%), inset: 12pt, radius: 4pt, width: 100%)[
  #text(weight: "bold", fill: accent)[Ärztliche Einordnung:] \
  #g("befund.einordnung")
  
  #v(8pt)
  #text(weight: "bold", fill: accent)[Empfehlung:] \
  #g("befund.empfehlung")
]

#v(10pt)
#if g("befund.kontrolle_in") != "" [
  #text(size: 10pt)[
    *Nächste Kontrolle:* #g("befund.kontrolle_in")
  ]
]

#v(30pt)

// Signature
#grid(
  columns: (1fr, 1fr),
  [],
  align(center)[
    #v(10pt)
    #line(length: 60%, stroke: 0.5pt + gray) \
    #text(size: 10pt, weight: "bold")[#g("unterschrift.name", default: g("praxis.arzt"))] \
    #text(size: 9pt, fill: text-muted)[Medizinische Fachpraxis]
  ]
)

#v(1fr)

// Footer
#set text(size: 8pt, fill: text-muted)
#align(center)[
  #g("praxis.name") · #g("praxis.strasse") · #g("praxis.plz_ort") \
  Dies ist ein computergeneriertes Dokument und ohne Unterschrift gültig.
]
