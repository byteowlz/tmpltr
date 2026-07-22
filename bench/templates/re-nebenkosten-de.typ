// Nebenkostenabrechnung
// @description: Betriebskostenabrechnung mit Umlageschlüsseln und Anteilen
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

#let tanne = rgb("#2f5d50")
#let kosten = data.at("kosten", default: ())
#let saldo = float(g("ergebnis.nachzahlung_guthaben", default: 0))
#let ist-nachzahlung = saldo > 0

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray.lighten(30%))
    #v(2pt)
    #g("vermieter.name") · #g("vermieter.strasse") · #g("vermieter.plz_ort")
    #h(1fr) Betriebskostenabrechnung #g("abrechnung.jahr") · Seite 1 von 1
  ])
#set text(font: "Tinos", size: 10pt, lang: "de")

// Kopf: schlichte Hausverwaltung, Serifenschrift
#grid(columns: (1fr, auto), align: (left, right),
  [
    #text(size: 15pt, weight: "bold", fill: tanne)[#g("vermieter.name", default: "Hausverwaltung")]
    #v(1pt)
    #text(size: 9pt, fill: gray.darken(40%))[#g("vermieter.strasse") · #g("vermieter.plz_ort")]
  ],
  [
    #box(fill: tanne, inset: (x: 10pt, y: 7pt), radius: 2pt)[
      #text(fill: white, size: 9pt, weight: "bold")[Abrechnung #g("abrechnung.jahr", default: "—")]
    ]
  ])
#v(3pt)
#line(length: 100%, stroke: 1.5pt + tanne)
#v(12pt)

// Empfänger + Objektdaten
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(size: 8pt, fill: gray.darken(40%))[MIETPARTEI]
    #v(2pt)
    #text(weight: "bold")[#g("mieter.name")] \
    #g("mieter.wohnung") \
    #g("mieter.strasse") \
    #g("mieter.plz_ort")
  ],
  [
    #set text(size: 9.5pt)
    #table(columns: (auto, 1fr), stroke: none, inset: 2.5pt, align: (left, right),
      [Abrechnungszeitraum], [*#g("abrechnung.zeitraum", default: "—")*],
      [Wohnfläche], [#g("abrechnung.wohnflaeche_qm", default: "—") m²],
      [Gesamtfläche des Objekts], [#g("abrechnung.gesamtflaeche_qm", default: "—") m²],
      [Personen im Haushalt], [#g("abrechnung.personen", default: "—")])
  ])
#v(14pt)

#text(size: 14pt, weight: "bold")[Betriebskostenabrechnung #g("abrechnung.jahr")]
#v(2pt)
#text(size: 9.5pt, fill: gray.darken(30%))[gemäß § 556 BGB und Betriebskostenverordnung (BetrKV)]
#v(10pt)

// Kostentabelle mit Umlageschlüsseln
#if kosten.len() > 0 {
  table(
    columns: (1fr, auto, auto, auto),
    align: (left, right, center, right),
    inset: (x: 8pt, y: 5.5pt),
    stroke: (_, y) => (bottom: 0.5pt + gray.lighten(40%)),
    fill: (_, row) => if row == 0 { tanne } else if calc.even(row) { rgb("#eef4f1") } else { white },
    table.header(
      [#text(fill: white, weight: "bold", size: 9pt)[Kostenart]],
      [#text(fill: white, weight: "bold", size: 9pt)[Gesamtkosten]],
      [#text(fill: white, weight: "bold", size: 9pt)[Umlageschlüssel]],
      [#text(fill: white, weight: "bold", size: 9pt)[Ihr Anteil]]),
    ..kosten.map(k => (
      [#k.at("art", default: "")],
      [#geld(k.at("gesamtkosten", default: 0))],
      [#text(size: 9pt)[#k.at("umlageschluessel", default: "—")]],
      [#geld(k.at("anteil", default: 0))],
    )).flatten())
} else {
  text(fill: gray)[Keine Kostenpositionen vorhanden.]
}
#v(6pt)

#align(right)[
  #table(columns: (auto, auto), stroke: none, inset: 3.5pt, align: (left, right),
    [Summe Ihrer Anteile], [*#geld(g("ergebnis.summe_anteile", default: 0))*],
    [geleistete Vorauszahlungen], [−#geld(g("ergebnis.vorauszahlungen", default: 0))],
    table.hline(stroke: 1pt + tanne))
]
#v(6pt)

// Ergebniskasten
#{
  let fillc = if ist-nachzahlung { rgb("#fbeeea") } else { rgb("#e9f3ec") }
  let strokec = if ist-nachzahlung { rgb("#a4402c") } else { rgb("#2e7d32") }
  let label = if ist-nachzahlung { "Nachzahlung zu Ihren Lasten" } else { "Guthaben zu Ihren Gunsten" }
  box(width: 100%, fill: fillc, stroke: (left: 4pt + strokec), inset: 12pt)[
    #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      [
        #text(weight: "bold", size: 12pt, fill: strokec)[#label]
        #v(3pt)
        #text(size: 9pt)[
          #if ist-nachzahlung [
            Bitte überweisen Sie den Betrag bis zum *#g("ergebnis.frist", default: "—")*
            unter Angabe Ihrer Wohnungsnummer auf das Ihnen bekannte Hausverwaltungskonto.
          ] else [
            Das Guthaben wird bis zum *#g("ergebnis.frist", default: "—")* auf das uns
            bekannte Konto erstattet bzw. mit der nächsten Miete verrechnet.
          ]
        ]
      ],
      [#text(size: 18pt, weight: "bold", fill: strokec)[#geld(calc.abs(saldo))]])
  ]
}
#v(12pt)

#text(size: 8.5pt, fill: gray.darken(20%))[
  Die Belege zu dieser Abrechnung können nach Terminvereinbarung in unseren
  Geschäftsräumen eingesehen werden. Einwendungen gegen die Abrechnung sind
  gemäß § 556 Abs. 3 BGB innerhalb von zwölf Monaten nach Zugang geltend zu
  machen. Umlageschlüssel: "Wohnfläche" = Anteil #g("abrechnung.wohnflaeche_qm", default: "—") m²
  von #g("abrechnung.gesamtflaeche_qm", default: "—") m²; "Personen" = Anteil
  #g("abrechnung.personen", default: "—") Personen an der Gesamtpersonenzahl des Hauses.
]
