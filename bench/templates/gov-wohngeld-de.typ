// Wohngeldbescheid
// @description: Bewilligung von Wohngeld mit Berechnungsgrundlagen
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let geld(x) = {
  let val = float(x)
  let v = calc.round(val, digits: 2)
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
  out + "," + (if c < 10 { "0" } else { "" }) + str(c) + " €"
}

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)
#set text(font: "Libertinus Serif", size: 10.5pt, lang: "de")

// Header: Authority Info
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 12pt)[#g("behoerde.name", default: "Behörde")] \
    #text(size: 10pt)[#g("behoerde.strasse", default: "") \ #g("behoerde.plz_ort", default: "")]
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(50%))[Aktenzeichen: #g("behoerde.aktenzeichen", default: "-")] \
    #text(size: 9pt, fill: gray.darken(50%))[Datum: #g("bescheid.datum", default: "-")]
  ]
)

#v(1.5cm)

// Recipient
#block(width: 100%, inset: (bottom: 1cm))[
  #text(size: 11pt, weight: "bold")[#g("antragsteller.name", default: "")] \
  #g("antragsteller.strasse", default: "") \
  #g("antragsteller.plz_ort", default: "")
]

#v(0.5cm)

// Title
#align(center)[
  #text(size: 16pt, weight: "bold")[Bescheid über Wohngeld] \
  #v(2pt)
  #text(size: 11pt, style: "italic")[Bewilligung]
]

#v(1cm)

// Main Content
#text(weight: "bold")[Sehr geehrte(r) #g("antragsteller.name", default: ""),] \
#v(0.5cm)

// Fix: Use set par(justify: true) instead of text(justify: true)
#set par(justify: true)
hiermani wird festgestellt, dass für den Zeitraum von *#g("bescheid.bewilligung_von", default: "-")* bis *#g("bescheid.bewilligung_bis", default: "-")* ein Anspruch auf Wohngeld besteht. Der monatliche Bewilligungsbetrag beläuft sich auf *#geld(g("bescheid.monatlicher_betrag", default: 0))*.

#v(0.8cm)

// Calculation Details Table
#text(weight: "bold")[Berechnungsgrundlagen:]
#v(0.3cm)
#table(
  columns: (1fr, 1fr),
  stroke: none,
  inset: 6pt,
  table.hline(stroke: 0.5pt),
  [Gesamteinkommen:], [#g("bescheid.gesamteinkommen", default: "0")], 
  [Berücksichtigte Miete:], [#geld(g("bescheid.miete_beruecksichtigt", default: 0))],
  [#text(weight: "bold")[Monatlicher Wohngeldbetrag:]], [#text(weight: "bold")[#geld(g("bescheid.monatlicher_betrag", default: 0))]],
  table.hline(stroke: 0.5pt),
)

#v(0.5cm)
#table(
  columns: (1fr, 1fr),
  stroke: none,
  inset: 4pt,
  [Gesamteinkommen:], [ #geld(g("bescheid.gesamteinkommen", default: 0)) ],
  [Berücksichtigte Miete:], [ #geld(g("bescheid.miete_beruecksichtigt", default: 0)) ],
  [#text(weight: "bold")[Monatlicher Wohngeldbetrag:]], [#text(weight: "bold")[#geld(g("bescheid.monatlicher_betrag", default: 0))] ],
)

#v(1cm)

// Household Members
#text(weight: "bold")[Haushaltsmitglieder:]
#v(0.2cm)
#let members = data.at("antragsteller.haushaltsmitglieder", default: ())
#if members.len() > 0 {
  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    stroke: (x, y) => if y == 0 { (bottom: 0.5pt + black) } else { none },
    inset: 5pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    [*Name*], [*Rolle*], [*Alter*], [*Status*],
    ..members.map(m => (
      [#m.at("name", default: "")],
      [#m.at("rolle", default: "")],
      [#m.at("alter", default: "-")],
      [#m.at("behoerdestatus", default: "")]
    )).flatten()
  )
}

#v(1cm)

// Payment Info
#block(fill: gray.lighten(90%), inset: 10pt, radius: 2pt, width: 100%)[
  #text(size: 9pt)[
    *Auszahlung:* Die Auszahlung erfolgt auf das Ihnen bekannte Konto (Endnummer: *#g("bescheid.iban_letzte4", default: "----")*).
  ]
]

#v(1cm)

// Rechtsbehelf
#text(weight: "bold")[Rechtsbehelf:] \
#v(0.2cm)
#text(size: 9pt)[
  #g("rechtsbehelf.hinweis", default: "") \
  #v(4pt)
  #text(style: "italic")[#g("rechtsbehelf.typ", default: ""): #g("rechtsbehelf.frist", default: "")] \
  #v(2pt)
  #g("rechtsbehelf.adresse", default: "")
]

#v(2cm)

// Footer/Signature area
#grid(columns: (1fr, 1fr),
  [],
  align(center)[
    #v(1cm)
    #line(length: 60%, stroke: 0.5pt) \
    #text(size: 9pt)[Unterschrift / Dienstsiegel]
  ]
)
