// Versicherungsschein
// @description: Police: Versicherungsnehmer, Tarif, Beiträge, Laufzeit
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

#let dunkelblau = rgb("#12325c")
#let leistungen = data.at("leistungen", default: ())

#set page(paper: "a4", margin: (top: 1.9cm, bottom: 2.3cm, x: 2.2cm),
  footer: [
    #set text(size: 6.8pt, fill: gray.darken(40%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr, 1fr),
      [#g("versicherer.name"), #g("versicherer.strasse"), #g("versicherer.plz_ort")],
      align(center)[Vorstand: Dr. H. Wielandt (Vors.), C. Möbius · Aufsichtsrat: P. Steinhagen],
      align(right)[Sitz Köln · Amtsgericht Köln HRB 44127 · Seite 1 von 1])
  ])
#set text(font: "Tinos", size: 10pt, lang: "de")

// Sober header: insurer left, document id right
#grid(columns: (1fr, auto), column-gutter: 14pt,
  [
    #text(size: 14pt, weight: "bold", fill: dunkelblau)[#g("versicherer.name", default: "Versicherer")]\
    #text(size: 8.5pt)[#g("versicherer.strasse") · #g("versicherer.plz_ort") · Telefon #g("versicherer.telefon")]
  ],
  align(right + top)[
    #text(size: 8.5pt, fill: gray.darken(40%))[Versicherungsschein-Nr.]\
    #text(size: 11.5pt, weight: "bold")[#g("vertrag.nummer", default: "—")]
  ])
#v(6pt)
#line(length: 100%, stroke: 2pt + dunkelblau)
#v(14pt)

#align(center)[
  #text(size: 19pt, weight: "bold", fill: dunkelblau)[Versicherungsschein]\
  #v(2pt)
  #text(size: 11pt)[#g("vertrag.sparte", default: "—")]
]
#v(14pt)

// Vertragsdaten framed box
#block(stroke: 0.7pt + dunkelblau, inset: 0pt, radius: 2pt, width: 100%)[
  #block(fill: dunkelblau, inset: (x: 10pt, y: 5pt), width: 100%)[
    #text(fill: white, weight: "bold", size: 9.5pt)[VERTRAGSDATEN]
  ]
  #pad(x: 10pt, y: 8pt)[
    #grid(columns: (1fr, 1fr), column-gutter: 24pt, row-gutter: 8pt,
      [
        #text(size: 8pt, fill: gray.darken(40%))[Versicherungsnehmer]\
        #text(weight: "bold")[#g("versicherungsnehmer.name")]\
        #g("versicherungsnehmer.strasse")\
        #g("versicherungsnehmer.plz_ort")\
        #text(size: 9pt)[geboren am #g("versicherungsnehmer.geburtsdatum", default: "—")]
      ],
      [
        #table(columns: (auto, 1fr), stroke: none, inset: (x: 3pt, y: 2.5pt),
          [#text(size: 9pt, fill: gray.darken(35%))[Tarif]], [*#g("vertrag.tarif", default: "—")*],
          [#text(size: 9pt, fill: gray.darken(35%))[Versicherungsbeginn]], [#g("vertrag.beginn", default: "—")],
          [#text(size: 9pt, fill: gray.darken(35%))[Ablauf]], [#g("vertrag.ablauf", default: "—")],
          [#text(size: 9pt, fill: gray.darken(35%))[Zahlweise]], [#g("vertrag.zahlweise", default: "—")])
      ])
  ]
]
#v(14pt)

// Leistungen
#text(weight: "bold", size: 11pt, fill: dunkelblau)[Versicherte Leistungen und Beiträge]
#v(5pt)
#if leistungen.len() > 0 {
  table(
    columns: (1fr, auto, auto, auto),
    align: (left, left, right, right),
    stroke: 0.4pt + gray.darken(10%),
    inset: (x: 7pt, y: 5.5pt),
    fill: (_, row) => if row == 0 { gray.lighten(78%) } else { white },
    table.header(
      [#text(size: 9pt, weight: "bold")[Leistungsbaustein]],
      [#text(size: 9pt, weight: "bold")[Versicherungssumme]],
      [#text(size: 9pt, weight: "bold")[Selbstbehalt]],
      [#text(size: 9pt, weight: "bold")[Jahresbeitrag]]),
    ..leistungen.map(l => (
      [#l.at("baustein", default: "")],
      [#l.at("summe", default: "—")],
      [#l.at("selbstbehalt", default: "—")],
      [#geld(l.at("beitrag", default: 0))],
    )).flatten(),
    table.cell(colspan: 3, align: right)[#text(weight: "bold")[Gesamtbeitrag inkl. Versicherungsteuer]],
    table.cell(align: right)[#text(weight: "bold", fill: dunkelblau)[#geld(g("gesamtbeitrag", default: 0))]]
  )
} else {
  text(fill: gray, size: 9pt)[Keine Leistungsbausteine vereinbart.]
}
#v(14pt)

#text(size: 8.5pt)[
  Dem Vertrag liegen die Allgemeinen Versicherungsbedingungen (Stand 01.2026)
  sowie die im Antrag getroffenen Vereinbarungen zugrunde. Der Beitrag wird
  jeweils zu Beginn der Versicherungsperiode fällig. Es gilt deutsches Recht.
]
#v(20pt)
#grid(columns: (1fr, 1fr), column-gutter: 36pt,
  [
    #g("versicherer.plz_ort", default: "Köln"), den #g("vertrag.beginn", default: "—")
  ],
  align(right)[
    #line(length: 80%, stroke: 0.6pt)
    #text(size: 8pt, fill: gray.darken(40%))[#g("versicherer.name") — Der Vorstand]
  ])
