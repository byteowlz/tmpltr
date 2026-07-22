// Kindergeldbescheid
// @description: Festsetzung von Kindergeld je Kind mit Zahlbetrag
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

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)

#set text(font: "Libertinus Serif", size: 10.5pt, lang: "de")

// Header: Official Agency Look
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 14pt)[#g("familienkasse.name")] \
    #text(size: 9pt)[#g("familienkasse.strasse") \ #g("familienkasse.plz_ort")] \
    #text(size: 9pt)[Kindergeldnummer: #g("familienkasse.kindergeldnr")]
  ],
  align(right)[
    #text(size: 9pt)[#g("bescheid.datum")] \
    #v(4pt)
    #text(weight: "bold")[Bescheid über Kindergeld]
  ]
)

#v(1.5cm)

// Recipient Block
#block(width: 100%, inset: (left: 0pt))[
  #text(size: 9pt, fill: gray.darken(50%))[An:] \
  #text(weight: "bold")[#g("berechtigter.name")] \
  #g("berechtigter.strasse") \
  #g("berechtigter.plz_ort") \
  #if g("berechtigter.steuer_id") != "" [Steuer-ID: #g("berechtigter.steuer_id")]
]

#v(1cm)

// Main Content
#text(weight: "bold", size: 12pt)[Festsetzung]
#v(0.5cm)

#text(style: "italic", size: 10pt)[
  Sehr geehrte(r) #g("berechtigter.name"), \
  hiermit setzen wir das Kindergeld für die nachfolgend aufgeführten Kinder fest.
]

#v(0.5cm)

// Children Table
#let children = if data.at("kinder", default: none) != none { data.at("kinder", default: ()) } else { () }
#if children.len() > 0 {
  let rows = children.map((it) => {
    (
      [#it.at("name", default: "-")],
      [#it.at("geburtsdatum", default: "-")],
      [#it.at("steuer_id", default: "-")],
      [#geld(it.at("betrag", default: 0))],
    )
  }).flatten()

  table(
    columns: (1fr, 1fr, 1fr, auto),
    stroke: none,
    inset: 6pt,
    table.header(
      [#text(weight: "bold")[Name des Kindes]],
      [#text(weight: "bold")[Geburtsdatum]],
      [#text(weight: "bold")[Steuer-ID]],
      [#text(weight: "bold")[Betrag]]
    ),
    table.hline(stroke: 0.5pt),
    ..rows
  )
  v(0.5pt)
  table.hline(stroke: 0.5pt)
}

#v(0.5cm)

// Total Block
#align(right)[
  #set text(size: 11pt)
  #grid(columns: (auto, auto), column-gutter: 20pt, row-gutter: 4pt,
    [Gesamtbetrag pro Monat:], [#text(weight: "bold")[#geld(g("bescheid.gesamtbetrag", default: 0))]],
    [Zahlbeginn ab:], [#g("bescheid.zahlbeginn")]
  )
]

#v(1cm)

// Payment Info
#block(fill: gray.lighten(90%), inset: 10pt, radius: 2pt, width: 100%)[
  #set text(size: 9pt)
  #text(weight: "bold")[Auszahlungsinformationen] \
  Die Auszahlung erfolgt auf das Ihnen bekannte Konto (Endnummer: *#g("bescheid.iban_letzte4", default: "----")*).
]

#v(1cm)

// Legal Notice
#text(size: 8.5pt, fill: gray.darken(40%))[
  #text(weight: "bold", fill: black)[Rechtsbehelfsbelehrung] \
  #g("rechtsbehelf")
]

#v(2cm)

// Footer / Signature Area
#grid(columns: (1fr, 1fr),
  [],
  align(right)[
    #text(size: 9pt)[#g("familienkasse.name")] \
    #v(10pt)
    #text(size: 9pt, style: "italic")[Elektronisch erstellt]
  ]
)
