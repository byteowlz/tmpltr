// Gehaltsabrechnung
// @description: Deutsche Entgeltabrechnung: Brutto, SV-Beiträge, Lohnsteuer, Netto
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

#let ink = rgb("#2b2b2b")
#let hdr = rgb("#e8e8e4")
#let abzuege = data.at("abzuege", default: ())
#let abz-summe = abzuege.fold(0.0, (acc, a) => acc + float(a.at("betrag", default: 0)))

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 1.8cm, x: 1.8cm),
  footer: [
    #set text(size: 6.5pt, fill: gray.darken(30%), font: "Cousine")
    #line(length: 100%, stroke: 0.3pt + gray)
    #v(1pt)
    Entgeltabrechnung nach § 108 GewO · Aufbewahrung empfohlen · maschinell erstellt, ohne Unterschrift gültig
  ])
#set text(font: "Cousine", size: 8pt, fill: ink)

// Kopf
#grid(columns: (1fr, auto), align: (left, right),
  [
    #text(size: 11pt, weight: "bold")[#g("arbeitgeber.firma", default: "—")] \
    #text(size: 7.5pt)[#g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort") · Betriebsnr. #g("arbeitgeber.betriebsnummer")]
  ],
  [
    #text(size: 10pt, weight: "bold")[ENTGELTABRECHNUNG] \
    #text(size: 7.5pt)[Abrechnungsmonat: *#g("zeitraum.monat", default: "—")* · Zahltag: #g("zeitraum.zahltag", default: "—")]
  ])
#v(3pt)
#line(length: 100%, stroke: 1pt + ink)
#v(6pt)

// Stammdaten-Gitter
#let sd(label, value) = [
  #text(size: 6pt, fill: gray.darken(45%))[#upper(label)] \
  #text(size: 8pt)[#value]
]
#block(stroke: 0.5pt + ink, inset: 6pt, width: 100%)[
  #grid(columns: (1.5fr, 0.8fr, 0.7fr, 0.7fr, 0.7fr, 1.3fr), row-gutter: 5pt, column-gutter: 6pt,
    sd("Name", g("arbeitnehmer.name", default: "—")),
    sd("Personal-Nr.", g("arbeitnehmer.personalnr", default: "—")),
    sd("StKl.", g("arbeitnehmer.steuerklasse", default: "—")),
    sd("Ki.-Frbtr.", g("arbeitnehmer.kinderfreibetraege", default: "—")),
    sd("Konf.", g("arbeitnehmer.konfession", default: "—")),
    sd("SV-Nummer", g("arbeitnehmer.sv_nummer", default: "—")),
    sd("Krankenkasse", g("arbeitnehmer.krankenkasse", default: "—")),
    sd("Eintritt", g("arbeitnehmer.eintritt", default: "—")),
    [], [], [], [])
]
#v(8pt)

// Brutto-Block
#text(weight: "bold", size: 8.5pt)[BRUTTOBEZÜGE]
#v(2pt)
#table(columns: (0.5fr, 2fr, 1fr), inset: 4.5pt, align: (left, left, right),
  stroke: (x, y) => (bottom: 0.3pt + gray.lighten(30%)),
  fill: (x, y) => if y == 0 { hdr } else { white },
  [*Lfd.*], [*Bezeichnung*], [*Betrag*],
  [001], [Grundgehalt], [#geld(g("brutto.grundgehalt", default: 0))],
  [002], [Zulagen / Schichtzuschläge], [#geld(g("brutto.zulagen", default: 0))],
  [003], [Vermögenswirksame Leistungen (AG-Anteil)], [#geld(g("brutto.vwl", default: 0))],
  table.cell(fill: hdr)[], table.cell(fill: hdr)[*Gesamtbrutto*], table.cell(fill: hdr)[*#geld(g("brutto.gesamt", default: 0))*])
#v(8pt)

// Abzüge
#text(weight: "bold", size: 8.5pt)[GESETZLICHE ABZÜGE (STEUER / SOZIALVERSICHERUNG)]
#v(2pt)
#if abzuege.len() > 0 {
  table(columns: (2.5fr, 1fr), inset: 4.5pt, align: (left, right),
    stroke: (x, y) => (bottom: 0.3pt + gray.lighten(30%)),
    fill: (x, y) => if y == 0 { hdr } else { white },
    [*Bezeichnung*], [*Betrag*],
    ..abzuege.map(a => ([#a.at("bezeichnung", default: "")], [#geld(a.at("betrag", default: 0))])).flatten(),
    table.cell(fill: hdr)[*Summe Abzüge*], table.cell(fill: hdr)[*#geld(abz-summe)*])
} else {
  text(fill: gray)[Keine Abzüge erfasst.]
}
#v(8pt)

// Netto
#block(stroke: 1.2pt + ink, inset: 8pt, width: 100%)[
  #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    [
      #text(size: 8pt)[*AUSZAHLUNGSBETRAG* — Überweisung auf Konto IBAN DE·· ···· ···· ···· #g("netto.iban_letzte4", default: "····")]
    ],
    text(size: 13pt, weight: "bold")[#geld(g("netto.auszahlung", default: 0))])
]
#v(6pt)
#text(size: 6.5pt, fill: gray.darken(25%))[
  Verdienstbescheinigung im Sinne des § 108 Abs. 3 GewO. Steuer- und SV-Tage: 30/30.
  Beitragsgruppenschlüssel 1111. Etwaige Rückfragen richten Sie bitte unter Angabe der
  Personalnummer an die Entgeltabrechnung.
]
