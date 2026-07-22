// Einkommensteuerbescheid
// @description: Steuerbescheid mit Besteuerungsgrundlagen, festgesetzter Steuer, Erstattung
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

#let jahr = g("bescheid.jahr", default: "····")
#let erstattung = float(g("bescheid.erstattung_nachzahlung", default: 0))

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(40%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(1pt)
    #g("finanzamt.name") · #g("finanzamt.strasse") · #g("finanzamt.plz_ort") · Telefon #g("finanzamt.telefon")
    #h(1fr) Seite 1 von 1
  ])
#set text(font: "Tinos", size: 10pt, lang: "de")

// Fold marks (DIN 5008)
#place(top + left, dx: -1.9cm, dy: 87mm - 1.8cm, line(length: 4mm, stroke: 0.4pt + gray))
#place(top + left, dx: -1.9cm, dy: 192mm - 1.8cm, line(length: 4mm, stroke: 0.4pt + gray))

// Header
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 12pt)[#g("finanzamt.name", default: "Finanzamt")] \
    #text(size: 9pt)[#g("finanzamt.strasse") · #g("finanzamt.plz_ort")]
  ],
  align(right)[
    #set text(size: 9pt)
    #table(columns: 2, stroke: none, align: (left, right), inset: 2pt,
      [Steuernummer], [*#g("steuerpflichtiger.steuernr", default: "—")*],
      [Identifikationsnummer], [#g("steuerpflichtiger.idnr", default: "—")],
      [Datum], [#g("bescheid.datum", default: "—")])
  ])
#line(length: 100%, stroke: 0.6pt)
#v(8pt)

// Address window
#text(size: 6.5pt, fill: gray.darken(30%))[#g("finanzamt.name") · #g("finanzamt.strasse") · #g("finanzamt.plz_ort")]
#v(3pt)
#g("steuerpflichtiger.name", default: "—") \
#g("steuerpflichtiger.strasse") \
#g("steuerpflichtiger.plz_ort")
#v(16pt)

#text(weight: "bold", size: 12pt)[Bescheid für #jahr über Einkommensteuer und Solidaritätszuschlag]
#v(10pt)

// Festsetzungstabelle
#text(weight: "bold", size: 10.5pt)[Festsetzung]
#v(3pt)
#let festsetzung = data.at("bescheid", default: (:)).at("festsetzung", default: ())
#if festsetzung.len() > 0 {
  table(
    columns: (1fr, auto),
    align: (left, right),
    stroke: (x, y) => (top: if y == 0 { 0.6pt } else { 0.3pt + gray }, bottom: 0.6pt),
    inset: 5pt,
    ..festsetzung.map(f => (
      [#f.at("position", default: "")],
      [#geld(f.at("betrag", default: 0))],
    )).flatten()
  )
} else {
  text(fill: gray, size: 9pt)[Keine Festsetzungspositionen.]
}
#v(4pt)
#let result-label = if erstattung < 0 { "Verbleibender Erstattungsbetrag" } else { "Verbleibende Nachzahlung" }
#align(right)[
  #box(stroke: 0.8pt, inset: 6pt)[
    #text(weight: "bold")[#result-label: #geld(calc.abs(erstattung))]
  ]
]
#v(6pt)
#if erstattung < 0 [
  Der Erstattungsbetrag wird in den nächsten Tagen auf das Konto mit der Endung
  *#g("bescheid.iban_letzte4", default: "····")* überwiesen.
] else [
  Bitte zahlen Sie den Betrag bis spätestens *#g("bescheid.zahlungsfrist", default: "—")*
  unter Angabe der Steuernummer auf das Konto der Finanzkasse.
]
#v(12pt)

// Besteuerungsgrundlagen
#text(weight: "bold", size: 10.5pt)[Besteuerungsgrundlagen]
#v(3pt)
#let einkuenfte = data.at("bescheid", default: (:)).at("einkuenfte", default: ())
#if einkuenfte.len() > 0 {
  table(
    columns: (1fr, auto),
    align: (left, right),
    stroke: none,
    inset: 4pt,
    fill: (_, row) => if calc.odd(row) { rgb("#f4f2ec") } else { white },
    ..einkuenfte.map(e => (
      [#e.at("art", default: "")],
      [#geld(e.at("betrag", default: 0))],
    )).flatten()
  )
} else {
  text(fill: gray, size: 9pt)[Keine Angaben zu Einkünften.]
}
#v(14pt)

// Rechtsbehelfsbelehrung
#line(length: 100%, stroke: 0.4pt)
#v(3pt)
#text(size: 8pt)[
  #text(weight: "bold")[Rechtsbehelfsbelehrung] \
  #g("rechtsbehelf", default: "Gegen diesen Bescheid ist der Einspruch gegeben. Er ist innerhalb eines Monats nach Bekanntgabe beim oben bezeichneten Finanzamt einzulegen.")
]
#v(6pt)
#text(size: 8pt, fill: gray.darken(30%))[Dieser Bescheid wurde maschinell erstellt und ist ohne Unterschrift gültig.]
