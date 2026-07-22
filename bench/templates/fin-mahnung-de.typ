// Mahnung
// @description: Zahlungserinnerung/Mahnung mit Mahnstufe, Mahngebühr, Frist
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

#let stufe = g("mahnung.stufe", default: 1)
#let titel = if stufe == 1 { "Zahlungserinnerung" } else { str(stufe) + ". Mahnung" }

#set page(paper: "a4", margin: (top: 2cm, bottom: 3cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(25%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr, 1fr), column-gutter: 8pt,
      [#g("absender.firma") \ #g("absender.strasse") · #g("absender.plz_ort")],
      align(center)[Tel. #g("absender.telefon") \ #g("absender.email")],
      align(right)[IBAN #g("absender.iban") \ BIC #g("absender.bic")])
  ])
#set text(font: "Tinos", size: 10.5pt, lang: "de")

// DIN-5008 fold marks
#place(top + left, dx: -2cm, dy: 8.7cm, line(length: 4mm, stroke: 0.5pt + gray))
#place(top + left, dx: -2cm, dy: 18.6cm, line(length: 4mm, stroke: 0.5pt + gray))

// Briefkopf
#align(right)[
  #text(weight: "bold", size: 13pt)[#g("absender.firma")] \
  #text(size: 9pt, fill: gray.darken(40%))[#g("absender.strasse") · #g("absender.plz_ort")]
]
#v(10pt)
#text(size: 7pt, fill: gray.darken(30%))[#underline[#g("absender.firma") · #g("absender.strasse") · #g("absender.plz_ort")]]
#v(4pt)
#g("empfaenger.firma") \
#g("empfaenger.ansprechpartner") \
#g("empfaenger.strasse") \
#g("empfaenger.plz_ort")
#v(14pt)
#let ort-kurz = str(g("absender.plz_ort")).split(" ").at(1, default: "")
#align(right)[#(ort-kurz + ", den " + str(g("mahnung.datum")))]
#v(10pt)

#text(weight: "bold", size: 12.5pt)[#titel — Rechnung Nr. #g("mahnung.rechnungsnr")]
#v(10pt)

#let ansp = str(g("empfaenger.ansprechpartner", default: ""))
#let anrede = if ansp == "" { "Sehr geehrte Damen und Herren," } else if ansp.starts-with("Frau") { "Sehr geehrte " + ansp + "," } else { "Sehr geehrter " + ansp + "," }
#anrede

auf unsere Rechnung Nr. #g("mahnung.rechnungsnr") vom #g("mahnung.rechnungsdatum")
konnten wir bis heute keinen Zahlungseingang feststellen. Sicherlich handelt es
sich nur um ein Versehen. Wir bitten Sie, den offenen Betrag nunmehr umgehend
auszugleichen.

#v(8pt)
#align(center)[
  #table(columns: (auto, auto), stroke: none, align: (left, right), inset: (x: 14pt, y: 4pt),
    [Rechnungsbetrag (Rg. Nr. #g("mahnung.rechnungsnr")):], [#geld(g("mahnung.betrag", default: 0))],
    [Mahngebühr:], [#geld(g("mahnung.mahngebuehr", default: 0))],
    table.hline(stroke: 0.8pt + black),
    [*Offener Gesamtbetrag:*], [*#geld(g("mahnung.gesamtbetrag", default: 0))*])
]
#v(8pt)

Bitte überweisen Sie den Gesamtbetrag bis spätestens zum

#align(center)[#text(weight: "bold", size: 11.5pt)[#g("mahnung.frist")]]

auf unser unten genanntes Konto unter Angabe der Rechnungsnummer. Sollten Sie
den Betrag zwischenzeitlich bereits angewiesen haben, betrachten Sie dieses
Schreiben bitte als gegenstandslos.

#if stufe >= 2 [
  Sollte auch diese Frist ergebnislos verstreichen, sehen wir uns leider
  gezwungen, den Vorgang ohne weitere Ankündigung an unser Inkassobüro zu
  übergeben bzw. das gerichtliche Mahnverfahren einzuleiten. Zudem berechnen
  wir Verzugszinsen in gesetzlicher Höhe (§ 288 BGB).
]

#v(6pt)
Bankverbindung: IBAN *#g("absender.iban")*, BIC #g("absender.bic")

#v(14pt)
Mit freundlichen Grüßen
#v(20pt)
*#g("absender.firma")* \
#text(size: 9pt, fill: gray.darken(30%))[Rechnungswesen / Forderungsmanagement]
