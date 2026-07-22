// Kontoauszug
// @description: Deutscher Kontoauszug mit Buchungen, alter/neuer Saldo
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

#let rot = rgb("#c8102e")
#let buchungen = data.at("buchungen", default: ())

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 2cm, left: 2cm, right: 1.8cm),
  footer: [
    #set text(font: "Cousine", size: 6.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(1.5pt)
    #g("bank.name") · #g("bank.strasse") · #g("bank.plz_ort") · BIC #g("bank.bic") #h(1fr) Bitte prüfen Sie diesen Auszug. Einwendungen innerhalb von 6 Wochen.
  ])
#set text(font: "Arimo", size: 9pt, lang: "de")

// Kopf: Sparkassen-Stil, rotes Band
#grid(columns: (auto, 1fr), column-gutter: 0pt,
  block(fill: rot, inset: (x: 12pt, y: 8pt))[
    #text(fill: white, size: 15pt, weight: "bold")[#g("bank.name", default: "Kontoauszug")]
  ],
  block(fill: rot.lighten(85%), inset: (x: 12pt, y: 8pt), width: 100%, height: auto)[
    #align(right + horizon)[#text(fill: rot, size: 13pt, weight: "bold")[Kontoauszug #g("konto.auszug_nr")]]
  ])
#v(6pt)

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #text(size: 7pt, fill: gray.darken(30%))[#g("bank.name") · #g("bank.strasse") · #g("bank.plz_ort")]
    #v(4pt)
    #text(weight: "bold", size: 10pt)[#g("konto.inhaber")]
  ],
  align(right)[
    #set text(font: "Cousine", size: 8pt)
    IBAN: #g("konto.iban") \
    BIC: #g("bank.bic") \
    Zeitraum: #g("konto.zeitraum") \
    Erstellt am: 18.07.2026
  ])
#v(8pt)

// Buchungstabelle im Kontoauszugs-Stil (monospace)
#set text(font: "Cousine", size: 8pt)
#block(stroke: (top: 1.2pt + rot, bottom: 1.2pt + rot), width: 100%, inset: 0pt)[
  #table(
    columns: (auto, auto, 1fr, auto),
    align: (left, left, left, right),
    stroke: none,
    inset: (x: 5pt, y: 3.5pt),
    table.header(
      [#text(weight: "bold")[Buchung]], [#text(weight: "bold")[Wert]],
      [#text(weight: "bold")[Verwendungszweck / Auftraggeber]], [#text(weight: "bold")[Betrag EUR]]),
    table.hline(stroke: 0.6pt + rot),
    [], [], [#text(weight: "bold")[Kontostand am Beginn des Zeitraums (alter Saldo)]],
    [#text(weight: "bold")[#geld(g("salden.alt", default: 0))]],
    ..buchungen.map(b => {
      let betrag = float(b.at("betrag", default: 0))
      ([#b.at("buchungstag", default: "")],
       [#b.at("wertstellung", default: "")],
       [#text(weight: "bold")[#b.at("auftraggeber", default: "")] #linebreak() #b.at("verwendungszweck", default: "")],
       [#if betrag < 0 { text(fill: rot)[#geld(betrag)] } else { geld(betrag) }])
    }).flatten(),
    table.hline(stroke: 0.6pt + rot),
    [], [], [#text(weight: "bold")[Kontostand am Ende des Zeitraums (neuer Saldo)]],
    [#text(weight: "bold")[#geld(g("salden.neu", default: 0))]],
  )
]
#v(8pt)

#set text(font: "Arimo", size: 7.5pt, fill: gray.darken(35%))
Rechnungen für Kontoführungsentgelte gelten als anerkannt, wenn innerhalb von sechs Wochen nach Zugang
keine Einwendungen erhoben werden. Sichern Sie diesen Auszug: er wird beim nächsten Abruf nicht erneut bereitgestellt.
Ihre Einlagen sind durch die Sicherungssysteme der Sparkassen-Finanzgruppe geschützt.
