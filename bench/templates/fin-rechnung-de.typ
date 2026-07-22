// Rechnung
// @description: Deutsche B2B-Rechnung mit Positionen, USt., Zahlungsziel
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

#let accent = rgb("#0e6e63")

#let positionen = data.at("positionen", default: ())
#let netto = positionen.fold(0.0, (acc, p) => acc + float(p.at("menge", default: 0)) * float(p.at("einzelpreis", default: 0)))
#let ust-satz = float(g("rechnung.ust_satz", default: 0))
#let ust = netto * ust-satz / 100
#let brutto = netto + ust

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.6cm, left: 2.5cm, right: 2cm),
  background: [
    // DIN 5008 Falzmarken
    #place(top + left, dx: 5mm, dy: 105mm, line(length: 4mm, stroke: 0.4pt + gray))
    #place(top + left, dx: 5mm, dy: 210mm, line(length: 4mm, stroke: 0.4pt + gray))
    #place(top + left, dx: 5mm, dy: 148.5mm, line(length: 6mm, stroke: 0.4pt + gray))
  ],
  footer: [
    #set text(size: 7pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + accent)
    #v(2pt)
    #grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt,
      [#g("absender.firma") \ #g("absender.strasse") · #g("absender.plz") #g("absender.ort")],
      [USt-IdNr. #g("absender.ustid") \ Steuernr. #g("absender.steuernr")],
      align(right)[#g("absender.bank") \ IBAN #g("absender.iban") · BIC #g("absender.bic")])
  ])
#set text(font: "Adwaita Sans", size: 10pt, lang: "de")

// Kopf
#grid(columns: (1fr, auto),
  [
    #text(size: 20pt, weight: "bold", fill: accent)[#g("absender.firma", default: "Rechnung")]
    #v(1pt)
    #text(size: 8.5pt, fill: gray.darken(40%))[Metall- und Stahlbau · Meisterbetrieb]
  ],
  align(right)[
    #text(size: 8.5pt)[#g("absender.strasse") \ #g("absender.plz") #g("absender.ort") \ Tel. #g("absender.telefon") \ #g("absender.email")]
  ])
#v(4pt)
#line(length: 100%, stroke: 1.2pt + accent)
#v(10pt)

// Anschriftfeld + Infoblock
#grid(columns: (10cm, 1fr), column-gutter: 12pt,
  [
    #text(size: 6.5pt, fill: gray.darken(30%))[#underline[#g("absender.firma") · #g("absender.strasse") · #g("absender.plz") #g("absender.ort")]]
    #v(8pt)
    #g("empfaenger.firma") \
    #g("empfaenger.ansprechpartner") \
    #g("empfaenger.strasse") \
    #g("empfaenger.plz") #g("empfaenger.ort")
  ],
  align(right)[
    #table(columns: 2, stroke: none, align: (left, right), inset: 2.5pt,
      text(size: 9pt)[Rechnungs-Nr.], text(size: 9pt, weight: "bold")[#g("rechnung.nummer")],
      text(size: 9pt)[Rechnungsdatum], text(size: 9pt)[#g("rechnung.datum")],
      text(size: 9pt)[Leistungszeitraum], text(size: 9pt)[#g("rechnung.leistungsdatum")],
      text(size: 9pt)[USt-IdNr.], text(size: 9pt)[#g("absender.ustid")])
  ])
#v(20pt)

#text(size: 14pt, weight: "bold")[Rechnung Nr. #g("rechnung.nummer")]
#v(8pt)

Sehr geehrte Damen und Herren,

für die erbrachten Leistungen berechnen wir Ihnen wie folgt:
#v(6pt)

#if positionen.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto, auto),
    align: (center, left, right, left, right, right),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + accent) } else { (bottom: 0.4pt + gray.lighten(40%)) },
    inset: 5.5pt,
    table.header(
      [*Pos.*], [*Bezeichnung*], [*Menge*], [*Einheit*], [*Einzelpreis*], [*Gesamt*]),
    ..positionen.enumerate().map(((i, p)) => (
      [#(i + 1)],
      [#p.at("beschreibung", default: "")],
      [#p.at("menge", default: 0)],
      [#p.at("einheit", default: "")],
      [#geld(p.at("einzelpreis", default: 0))],
      [#geld(float(p.at("menge", default: 0)) * float(p.at("einzelpreis", default: 0)))],
    )).flatten()
  )
} else {
  text(fill: gray)[Keine Positionen.]
}
#v(4pt)

#align(right)[
  #table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3.5pt,
    [Nettobetrag], [#geld(netto)],
    [zzgl. #{ust-satz}% USt.], [#geld(ust)],
    table.hline(stroke: 1pt + accent),
    [#text(weight: "bold", size: 11pt)[Rechnungsbetrag]], [#text(weight: "bold", size: 11pt, fill: accent)[#geld(brutto)]])
]
#v(10pt)

#text(size: 9.5pt)[
  Zahlbar innerhalb von *#g("rechnung.zahlungsziel_tage", default: "14") Tagen* ab Rechnungsdatum
  ohne Abzug auf unser Konto bei der #g("absender.bank"),
  IBAN *#g("absender.iban")*, BIC #g("absender.bic").
]
#if g("hinweis") != "" [
  #v(6pt)
  #text(size: 8.5pt, fill: gray.darken(30%))[#g("hinweis")]
]
#v(10pt)
Mit freundlichen Grüßen \
#g("absender.firma")
