// Bestellbestätigung
// @description: Online-Shop Bestellbestätigung mit Lieferadresse und Versand
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

#let gruen = rgb("#2d6a35")
#let artikel = data.at("artikel", default: ())

#set page(paper: "a4", margin: (x: 2.2cm, top: 1.8cm, bottom: 2.2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr, 1fr),
      [#g("shop.name") · #g("shop.strasse") · #g("shop.plz_ort")],
      align(center)[USt-IdNr. #g("shop.ustid")],
      align(right)[#g("shop.email")])
  ])
#set text(font: "Adwaita Sans", size: 10pt)

// Header: wordmark left, meta right
#grid(columns: (1fr, auto), align: horizon,
  [
    #text(size: 19pt, weight: "bold", fill: gruen)[#g("shop.name", default: "Online-Shop")]
    #v(1pt)
    #text(size: 8.5pt, fill: gray.darken(40%))[#g("shop.strasse") · #g("shop.plz_ort")]
  ],
  align(right)[
    #box(fill: gruen, inset: (x: 10pt, y: 6pt), radius: 3pt)[
      #text(fill: white, weight: "bold", size: 10pt)[BESTELLBESTÄTIGUNG]
    ]
  ])
#v(4pt)
#line(length: 100%, stroke: 1.5pt + gruen)
#v(10pt)

Hallo #g("kunde.name", default: "liebe Kundin, lieber Kunde"),

vielen Dank für Ihre Bestellung! Wir haben sie erhalten und bereiten den Versand vor. Sobald Ihr Paket unser Lager verlässt, erhalten Sie eine Versandbestätigung mit Sendungsverfolgung an #text(weight: "bold")[#g("kunde.email", default: "Ihre E-Mail-Adresse")].

#v(10pt)

// Meta + Lieferadresse
#grid(columns: (1fr, 1fr), column-gutter: 18pt,
  block(width: 100%, fill: rgb("#f1f7f2"), inset: 10pt, radius: 3pt)[
    #text(size: 8pt, fill: gruen, weight: "bold")[BESTELLDATEN]
    #v(4pt)
    #set text(size: 9.5pt)
    #grid(columns: (auto, 1fr), column-gutter: 10pt, row-gutter: 4.5pt,
      [Bestellnummer], text(weight: "bold")[#g("bestellung.nummer")],
      [Bestelldatum], [#g("bestellung.datum")],
      [Kundennummer], [#g("kunde.kundennr")],
      [Zahlungsart], [#g("bestellung.zahlart")],
      [Versandart], [#g("bestellung.versandart")],
      [Lieferzeit], [#g("bestellung.lieferzeit")])
  ],
  block(width: 100%, stroke: 0.75pt + gray.lighten(30%), inset: 10pt, radius: 3pt)[
    #text(size: 8pt, fill: gruen, weight: "bold")[LIEFERADRESSE]
    #v(4pt)
    #set text(size: 9.5pt)
    #text(weight: "bold")[#g("lieferadresse.name")] \
    #g("lieferadresse.strasse") \
    #g("lieferadresse.plz_ort")
  ])
#v(12pt)

// Artikeltabelle
#if artikel.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto),
    align: (center, left, center, right, right),
    stroke: none,
    inset: 6.5pt,
    fill: (_, row) => if row == 0 { gruen } else if calc.even(row) { rgb("#f5faf6") } else { white },
    table.header(
      [#text(fill: white, weight: "bold", size: 9pt)[Pos.]],
      [#text(fill: white, weight: "bold", size: 9pt)[Artikel]],
      [#text(fill: white, weight: "bold", size: 9pt)[Menge]],
      [#text(fill: white, weight: "bold", size: 9pt)[Einzelpreis]],
      [#text(fill: white, weight: "bold", size: 9pt)[Gesamt]]),
    ..artikel.enumerate().map(((i, it)) => (
      [#(i + 1)],
      [#it.at("bezeichnung", default: "")],
      [#it.at("menge", default: 1)],
      [#geld(it.at("einzelpreis", default: 0))],
      [#geld(float(it.at("menge", default: 1)) * float(it.at("einzelpreis", default: 0)))],
    )).flatten()
  )
} else {
  text(fill: gray)[Keine Artikel in dieser Bestellung.]
}
#v(6pt)

// Summen
#align(right)[
  #table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3.5pt,
    [Zwischensumme], [#geld(g("summen.zwischensumme", default: 0))],
    [Versandkosten], [#geld(g("summen.versand", default: 0))],
    table.hline(stroke: 0.75pt + gruen),
    [#text(weight: "bold", size: 11pt)[Gesamtbetrag]],
    [#text(weight: "bold", size: 11pt, fill: gruen)[#geld(g("summen.gesamt", default: 0))]],
    [#text(size: 8.5pt, fill: gray.darken(30%))[enthaltene MwSt. (19 %)]],
    [#text(size: 8.5pt, fill: gray.darken(30%))[#geld(g("summen.mwst", default: 0))]])
]
#v(12pt)

#block(width: 100%, stroke: (left: 3pt + gruen), inset: (left: 10pt, y: 4pt))[
  #text(size: 9pt)[
    #text(weight: "bold")[Widerrufsrecht:] Sie können Ihre Bestellung innerhalb von 14 Tagen
    nach Erhalt der Ware ohne Angabe von Gründen widerrufen. Details finden Sie in unseren AGB.
  ]
]
#v(8pt)

#text(size: 9.5pt)[
  Bei Fragen zu Ihrer Bestellung erreichen Sie uns unter #text(weight: "bold", fill: gruen)[#g("shop.email")] —
  bitte geben Sie dabei Ihre Bestellnummer #text(weight: "bold")[#g("bestellung.nummer")] an.
]

#v(8pt)
Viele Grüße \
Ihr Team von #g("shop.name", default: "Ihrem Online-Shop")
