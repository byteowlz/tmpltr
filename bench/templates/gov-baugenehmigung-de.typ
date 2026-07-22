// Baugenehmigung
// @description: Genehmigungsbescheid mit Auflagen und Gebühren
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

// Layout settings
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)
#set text(font: "Libertinus Serif", size: 11pt, lang: "de")
#set par(justify: true)

// Header: Authority info
#grid(columns: (1fr, auto),
  [
    #text(size: 14pt, weight: "bold")[#g("behoerde.name", default: "Behörde")] \
    #text(size: 10pt)[#g("behoerde.strasse", default: "") \ #g("behoerde.plz_ort", default: "")]
  ],
  align(right)[
    #text(weight: "bold")[Aktenzeichen: #g("behoerde.aktenzeichen", default: "-")] \
    #text(size: 10pt)[Datum: #g("genehmigung.datum", default: "-")]
  ]
)

#v(1cm)

// Title Block
#align(center)[
  #text(size: 18pt, weight: "bold")[BESCHEID] \
  #text(size: 14pt, weight: "medium")[über die Baugenehmigung]
]

#v(0.5cm)

// Subject / Parties
#block(stroke: 0.5pt + black, inset: 12pt, width: 100%)[
  #set text(size: 10pt)
  #grid(columns: (1fr, 1fr), column-gutter: 20pt,
    [
      *Bauherr:* \
      #g("bauherr.name", default: "") \
      #g("bauherr.strasse", default: "") \
      #g("bauherr.plz_ort", default: "")
    ],
    [
      *Vorhaben:* \
      #g("vorhaben.bezeichnung", default: "") \
      #g("vorhaben.grundstueck", default: "") \
      #g("vorhaben.flurstueck", default: ""), #g("vorhaben.gemarkung", default: "")
    ]
  )
]

#v(0.8cm)

// Decision Text
#text(weight: "bold")[Bescheidtext:] \
#v(2pt)
Die Untere Bauaufsichtsbehörde hat das Bauvorhaben gemäß der eingereichten Unterlagen geprüft. Auf Grundlage der geltenden Bauordnung wird die beantragte bauliche Nutzung hiermit **genehmigt**.

#v(0.5cm)

// Conditions (Auflagen)
#text(weight: "bold", size: 12pt)[Besondere Auflagen und Bedingungen:] \
#v(4pt)
#let auflagen = data.at("genehmigung.auflagen", default: ())
#if auflagen.len() > 0 {
  list(..auflagen.map(item => [
    #item
  ]))
} else {
  [Es wurden keine besonderen Auflagen erteilt.]
}

#v(0.5cm)

// Validity and Fees
#grid(columns: (1fr, 1fr), stroke: none,
  [
    *Befristung:* \
    Die Genehmigung ist befristet bis zum #g("genehmigung.befristung", default: "unbefristet").
  ],
  align(right)[
    *Gebühr:* \
    #geld(g("genehmigung.gebuehr", default: 0))
  ]
)

#v(1.5cm)

// Legal Remedy
#block(fill: gray.lighten(90%), inset: 10pt, width: 100%)[
  #text(size: 9pt, weight: "bold")[Rechtsbehelfsbelehrung:] \
  #text(size: 9pt)[#g("rechtsbehelf", default: "")]
]

#v(1cm)

// Footer (Signature area placeholder)
#align(right)[
  #v(1cm)
  #line(length: 5cm, stroke: 0.5pt) \
  #text(size: 10pt)[Unterschrift / Dienstsiegel] \
  #text(size: 9pt, fill: gray)[Untere Bauaufsichtsbehörde]
]
