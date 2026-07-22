// Stromrechnung Jahresabrechnung
// @description: Jahresverbrauchsabrechnung mit Zählerständen, Abschlägen, Guthaben/Nachzahlung
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

#let orange = rgb("#e8630a")
#let dunkel = rgb("#20374f")
#let posten = data.at("posten", default: ())
#let saldo = float(g("ergebnis.guthaben_nachzahlung", default: 0))
#let ist-guthaben = saldo <= 0

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 2.4cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(20%))
    #line(length: 100%, stroke: 0.5pt + gray.lighten(30%))
    #v(2pt)
    #grid(columns: (1fr, 1fr, 1fr),
      [#g("versorger.name") \ #g("versorger.strasse"), #g("versorger.plz_ort")],
      align(center)[Kundenservice: #g("versorger.hotline") \ USt-IdNr. #g("versorger.ustid")],
      align(right)[Amtsgericht Iserlohn HRB 4482 \ Seite 1 von 1])
  ])
#set text(font: "Arimo", size: 10pt, lang: "de")

// Faltmarken (DIN 5008)
#place(top + left, dx: -1.8cm, dy: 8.7cm, line(length: 4mm, stroke: 0.5pt + gray))
#place(top + left, dx: -1.8cm, dy: 19.2cm, line(length: 4mm, stroke: 0.5pt + gray))

// Kopf
#grid(columns: (1fr, auto),
  [
    #text(size: 20pt, weight: "bold")[#text(fill: orange)[⚡] #text(fill: dunkel)[#g("versorger.name", default: "Stadtwerke")]]
  ],
  align(right)[
    #set text(size: 8.5pt, fill: gray.darken(40%))
    #g("versorger.strasse") \
    #g("versorger.plz_ort") \
    Hotline #g("versorger.hotline")
  ])
#v(2pt)
#line(length: 100%, stroke: 3pt + orange)
#v(10pt)

// Anschriftfeld + Infoblock
#grid(columns: (9cm, 1fr), column-gutter: 1cm,
  [
    #text(size: 6.5pt, fill: gray)[#g("versorger.name") · #g("versorger.strasse") · #g("versorger.plz_ort")]
    #v(4pt)
    #g("kunde.name") \
    #g("kunde.strasse") \
    #g("kunde.plz_ort")
  ],
  [
    #set text(size: 9pt)
    #table(columns: (auto, 1fr), stroke: none, inset: 2pt, align: (left, right),
      [Kundennummer], [*#g("kunde.kundennr")*],
      [Vertragskonto], [#g("kunde.vertragskonto")],
      [Zählernummer], [#g("kunde.zaehlernr")],
      [Rechnungsnr.], [#g("abrechnung.nummer")],
      [Rechnungsdatum], [#g("abrechnung.datum")])
  ])
#v(14pt)

#text(size: 14pt, weight: "bold", fill: dunkel)[Ihre Jahresabrechnung Strom]
#v(1pt)
#text(size: 9.5pt)[Abrechnungszeitraum: *#g("abrechnung.zeitraum", default: "—")*]
#v(10pt)

// Verbrauchskasten
#box(width: 100%, fill: rgb("#fdf1e7"), stroke: (left: 3pt + orange), inset: 10pt)[
  #text(weight: "bold", size: 9.5pt, fill: dunkel)[IHR VERBRAUCH]
  #v(6pt)
  #grid(columns: (1fr, 1fr, 1fr), align: center,
    [
      #text(size: 8pt, fill: gray.darken(40%))[Zählerstand alt (01.07.2025)] \
      #text(size: 13pt, weight: "bold")[#g("verbrauch.zaehlerstand_alt", default: "—") kWh]
    ],
    [
      #text(size: 8pt, fill: gray.darken(40%))[Zählerstand neu (30.06.2026)] \
      #text(size: 13pt, weight: "bold")[#g("verbrauch.zaehlerstand_neu", default: "—") kWh]
    ],
    [
      #text(size: 8pt, fill: gray.darken(40%))[Jahresverbrauch] \
      #text(size: 13pt, weight: "bold", fill: orange)[#g("verbrauch.kwh", default: "—") kWh]
    ])
]
#v(12pt)

// Posten
#text(weight: "bold", size: 10.5pt, fill: dunkel)[Rechnungsposten]
#v(3pt)
#if posten.len() > 0 {
  table(columns: (1fr, auto),
    stroke: (_, y) => (bottom: 0.5pt + gray.lighten(50%)),
    inset: (x: 6pt, y: 6pt), align: (left, right),
    ..posten.map(p => (
      [#p.at("bezeichnung", default: "")],
      [#geld(p.at("betrag", default: 0))],
    )).flatten())
} else {
  text(fill: gray)[Keine Posten vorhanden.]
}
#v(2pt)
#align(right)[
  #table(columns: (auto, auto), stroke: none, inset: 3pt, align: (left, right),
    [Rechnungsbetrag brutto], [*#geld(g("ergebnis.rechnungsbetrag", default: 0))*],
    [abzüglich gezahlter Abschläge], [−#geld(g("ergebnis.gezahlte_abschlaege", default: 0))])
]
#v(6pt)

// Ergebniskasten
#{
  let fillc = if ist-guthaben { rgb("#e5f3e8") } else { rgb("#fdeaea") }
  let strokec = if ist-guthaben { rgb("#2e7d32") } else { rgb("#b52a2a") }
  let label = if ist-guthaben { "Ihr Guthaben" } else { "Ihre Nachzahlung" }
  box(width: 100%, fill: fillc, stroke: 1.5pt + strokec, radius: 4pt, inset: 12pt)[
    #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      [
        #text(weight: "bold", size: 12pt, fill: strokec)[#label: #geld(calc.abs(saldo))]
        #v(3pt)
        #text(size: 9pt)[
          #if ist-guthaben [
            Wir erstatten das Guthaben in den nächsten Tagen auf Ihr Konto mit der
            Endung *#g("ergebnis.iban_letzte4", default: "····")*.
          ] else [
            Bitte überweisen Sie den Betrag bis zum *#g("abrechnung.faelligkeit", default: "—")*.
            Bei erteiltem SEPA-Mandat buchen wir vom Konto mit der Endung
            *#g("ergebnis.iban_letzte4", default: "····")* ab.
          ]
        ]
      ],
      [
        #text(size: 8.5pt, fill: gray.darken(40%))[Neuer monatlicher Abschlag] \
        #text(size: 14pt, weight: "bold", fill: dunkel)[#geld(g("ergebnis.neuer_abschlag", default: 0))]
      ])
  ]
}
#v(12pt)

#text(size: 8.5pt, fill: gray.darken(20%))[
  Ihr neuer Abschlag wird erstmals zum 01.09.2026 fällig. Die Stromkennzeichnung
  nach § 42 EnWG sowie Informationen zu Ihren Wechselrechten finden Sie unter
  www.stadtwerke-halversen.de/kennzeichnung. Fragen zur Rechnung beantwortet unser
  Kundenservice unter #g("versorger.hotline") (Mo–Fr 8–18 Uhr).
]
