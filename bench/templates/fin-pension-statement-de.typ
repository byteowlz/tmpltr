// Renteninformation (Pension Statement)
// @description: Jährliche Renteninformation der DRV mit Anwartschaften
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

// Styling
#let accent = rgb("#003366") // Deep blue typical for German authorities
#let light-gray = rgb("#f4f4f4")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Libertinus Serif", size: 10pt, lang: "de")

// Header: Authority Info
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 12pt, fill: accent)[#g("traeger.name", default: "")] \
    #g("traeger.strasse", default: "") \
    #g("traeger.plz_ort", default: "")
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(50%))[Stand der Berechnung: \ #g("rente.stand", default: "—")]
  ]
)

#v(1cm)

// Recipient Block
#block(width: 100%, inset: 10pt, fill: light-gray, radius: 2pt)[
  #text(size: 9pt, weight: "bold", fill: accent)[Versicherter:] \
  #v(2pt)
  #text(size: 11pt)[#g("versicherter.name", default: "")] \
  #g("versicherter.strasse", default: "") \
  #g("versicherter.plz_ort", default: "")
]

#v(0.5cm)

// Subject Line
#text(size: 14pt, weight: "bold")[Renteninformation] \
#v(2pt)
#line(length: 100%, stroke: 1pt + accent)

#v(0.5cm)

// Personal Details Grid
#text(weight: "bold")[Persönliche Daten:]
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [Versicherungsnummer: #g("versicherter.versicherungsnummer", default: "—")],
  [Geburtsdatum: #g("versicherter.geburtsdatum", default: "—")],
  [Beitragsjahre: #g("rente.beitragsjahre", default: "0")],
  [Voraussichtl. Rentenbeginn: #g("rente.regelaltersrente_datum", default: "—")]
)

#v(1cm)

// Main Content: Pension Projections
#text(size: 12pt, weight: "bold", fill: accent)[Ihre Rentenansprüche]
#v(4pt)
#text(style: "italic", size: 9pt)[Die folgenden Werte sind Hochrechnungen auf Basis Ihrer bisherigen Beitragszahlungen. Sie stellen keine verbindliche Zusage dar.]

#v(0.5cm)

#table(
  columns: (1fr, auto),
  stroke: none,
  inset: 8pt,
  fill: (x, y) => if y == 0 { accent } else if calc.even(y) { white } else { light-gray },
  table.header(
    [#text(fill: white, weight: "bold")[Art der Leistung]],
    [#text(fill: white, weight: "bold")[Betrag (monatlich)]]
  ),
  [Bisherige Anwartschaft], [#geld(g("rente.bisherige_anwartschaft", default: 0))],
  [Hochrechnung (Regelaltersrente)], [#geld(g("rente.hochrechnung", default: 0))],
  [Erwerbsminderungsrente], [#geld(g("rente.erwerbsminderung", default: 0))]
)

#v(1cm)

// Disclaimer / Footer Info
#block(stroke: 0.5pt + gray, inset: 10pt, radius: 2pt)[
  #text(size: 9pt)[
    *Hinweis:* Diese Information dient Ihrer persönlichen Planung. Die tatsächliche Rentenhöhe bei Rentenbeginn kann aufgrund von Gesetzesänderungen, der Entwicklung der Rentenwerte oder Änderungen Ihrer persönlichen Verhältnisse abweichen. 
    
    Bitte prüfen Sie die Angaben auf Richtigkeit. Sollten sich Änderungen in Ihrer Erwerbssituation ergeben, empfehlen wir eine erneute Prüfung.
  ]
]

#v(1fr)

#align(center)[
  #text(size: 8pt, fill: gray.darken(50%))[
    Dies ist ein computergeneriertes Dokument der #g("traeger.name", default: "").
  ]
]
