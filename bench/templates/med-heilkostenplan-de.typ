// Heil- und Kostenplan (Zahnarzt)
// @description: HKP mit Befund, geplanten Leistungen, Eigenanteil
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)
#let garr(path) = { let v = get(data, path, default: none); if type(v) == array { v } else { () } }

#let geld(x) = {
  let v = calc.round(float(x), digits: 2)
  let i = int(calc.abs(v))
  let c = int(calc.round((calc.abs(v) - i) * 100))
  let s = str(i)
  let out = ""
  let n = s.clusters().len()
  for (k, ch) in s.clusters().enumerate() {
    out = out + ch
    let rem = n - k - 1
    if rem > 0 and calc.rem(rem, 3) == 0 { out = out + "." }
  }
  (if v < 0 { "-" } else { "" }) + out + "," + (if c < 10 { "0" } else { "" }) + str(c) + " €"
}

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 1.8cm, x: 2cm))
#set text(font: "Arimo", size: 9.5pt)

#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 12pt)[#g("praxis.name")] \
    #g("praxis.zahnarzt") \
    #g("praxis.strasse"), #g("praxis.plz_ort") \
    Abrechnungsnummer: #g("praxis.abrechnungsnr")
  ],
  align(right)[
    #box(fill: rgb("#0b5e4a"), inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 11pt)[Heil- und Kostenplan]
    ] \
    #v(2pt)
    #text(size: 9pt)[Datum: #g("plan.datum")]
  ])
#v(6pt)
#line(length: 100%, stroke: 0.8pt + rgb("#0b5e4a"))
#v(6pt)

#grid(columns: (1fr, 1fr), row-gutter: 3pt,
  [*Patient:* #g("patient.name")], [*Geburtsdatum:* #g("patient.geburtsdatum")],
  [*Krankenkasse:* #g("patient.krankenkasse")], [*Versicherten-Nr.:* #g("patient.versichertennr")])
#v(10pt)

#text(weight: "bold")[1. Befund] \
#box(stroke: 0.5pt + gray, inset: 7pt, width: 100%)[#g("plan.befund", default: "—")]
#v(8pt)

#text(weight: "bold")[2. Regelversorgung] \
#box(stroke: 0.5pt + gray, inset: 7pt, width: 100%)[#g("plan.regelversorgung", default: "—")]
#v(8pt)

#text(weight: "bold")[3. Geplante Leistungen]
#v(3pt)
#let pos = garr("plan.positionen")
#if pos.len() > 0 {
  table(columns: (auto, 1fr, auto), stroke: 0.5pt + gray, inset: 5pt,
    fill: (_, row) => if row == 0 { rgb("#e7f2ee") } else { white },
    table.header([*Zahn/Region*], [*Leistung*], [*Betrag*]),
    ..pos.map(p => (
      [#p.at("zahn", default: "")],
      [#p.at("leistung", default: "")],
      align(right)[#geld(p.at("betrag", default: 0))],
    )).flatten())
} else [—]
#v(8pt)

#align(right)[
  #table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3pt,
    [Gesamtkosten (geschätzt)], [#geld(g("plan.gesamtkosten", default: 0))],
    [Festzuschuss der Krankenkasse], [#geld(g("plan.festzuschuss", default: 0))],
    table.hline(stroke: 1pt + rgb("#0b5e4a")),
    [#text(weight: "bold")[Voraussichtlicher Eigenanteil]],
    [#text(weight: "bold", fill: rgb("#0b5e4a"))[#geld(g("plan.eigenanteil", default: 0))]])
]
#v(10pt)

#text(size: 8pt, fill: gray.darken(30%))[
  Dieser Heil- und Kostenplan ist ein Kostenvoranschlag. Der Festzuschuss wird von
  der Krankenkasse nach Prüfung festgesetzt. Bitte reichen Sie den Plan vor
  Behandlungsbeginn bei Ihrer Krankenkasse ein. Gültigkeit: 6 Monate.
]
#v(14pt)
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8.5pt)[Ort, Datum]],
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8.5pt)[Unterschrift Zahnärztin/Zahnarzt]])
