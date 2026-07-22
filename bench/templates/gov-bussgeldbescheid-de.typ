// Bußgeldbescheid
// @description: Verkehrsordnungswidrigkeit: Tatvorwurf, Beweismittel, Bußgeld, Punkte
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

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Libertinus Serif", size: 10.5pt, lang: "de")

// Header: Authority Info
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 12pt)[#g("behoerde.name")] \
    #text(size: 10pt)[#g("behoerde.strasse") \ #g("behoerde.plz_ort")]
  ],
  align(right)[
    #text(weight: "bold")[Aktenzeichen: #g("behoerde.aktenzeichen")] \
    #text(size: 10pt)[Datum: #g("tat.datum")]
  ]
)

#v(1.5cm)

// Title
#align(center)[
  #text(size: 18pt, weight: "bold")[BUßGELDBESCHEID] \
  #v(2pt)
  #text(size: 11pt, style: "italic")[Verwaltungsakt gemäß § 67 OWiG]
]

#v(1cm)

// Recipient
#block(inset: (left: 1cm))[
  #text(weight: "bold")[An: #g("betroffener.name")] \
  #g("betroffener.strasse") \
  #g("betroffener.plz_ort")
]

#v(0.8cm)

// Subject Line
#text(weight: "bold", size: 12pt)[
  Betreff: Bußgeldbescheid wegen Ordnungswidrigkeit
]
#v(0.4cm)

// Section 1: The Offense
#text(weight: "bold", size: 11pt)[1. Sachverhalt und Tatvorwurf]
#v(4pt)
#text(style: "italic")[Tatzeit: #g("tat.datum"), #g("tat.uhrzeit")] \
#text(style: "italic")[Tatort: #g("tat.ort")] \
#v(4pt)
#text(weight: "bold")[Vorwurf:] #g("tat.vorwurf") \
#v(2pt)
#text(weight: "bold")[Fahrzeug:] #g("tat.fahrzeug") (#g("tat.kennzeichen")) \
#v(2pt)
#text(weight: "bold")[Messverfahren:] #g("tat.messverfahren") \
#v(2pt)
#text(weight: "bold")[Messwert:] #g("tat.messwert") (Toleranz: #g("tat.toleranz"))

#v(0.8cm)

// Section 2: Sanctions
#text(weight: "bold", size: 11pt)[2. Sanktionen und Bußgeld]
#v(4pt)
#table(
  columns: (1fr, auto),
  stroke: none,
  inset: 4pt,
  [Bußgeld: #g("tat.vorwurf", default: "")], [#geld(g("sanktion.bussgeld", default: 0))],
  [Gebühren und Auslagen:], [
    #if g("sanktion.gebuehren", default: "0") != "0" [
      #geld(g("sanktion.gebuehren", default: 0)) \
    ]
    #if g("sanktion.auslagen", default: "0") != "0" [
      #geld(g("sanktion.auslagen", default: 0)) \
    ]
  ],
  table.hline(stroke: 0.5pt + gray),
  [#text(weight: "bold")[Gesamtbetrag:]], [#text(weight: "bold")[#geld(g("sanktion.gesamt", default: 0))]],
)

#v(4pt)
#grid(columns: (1fr, 1fr),
  [
    #text(weight: "bold")[Punkte im Fahreignungsregister:] \
    #g("sanktion.punkte", default: "0")
  ],
  [
    #text(weight: "bold")[Fahrverbot:] \
    #if g("sanktion.fahrverbot_monate", default: "0") == "0" [Keines] else [#g("sanktion.fahrverbot_monate") Monate]
  ]
)

#v(0.8cm)

// Section 3: Payment
#text(weight: "bold", size: 11pt)[3. Zahlungsanweisung]
#v(4pt)
Der Gesamtbetrag in Höhe von *#geld(g("sanktion.gesamt", default: 0))* ist bis spätestens zum 
#g("sanktion.zahlungsfrist", default: "—") an die oben genannte Behörde zu entrichten. 
Bitte geben Sie bei der Zahlung das Aktenzeichen *#g("behoerde.aktenzeichen")* an.

#v(1cm)

// Section 4: Legal Remedy
#text(weight: "bold", size: 11pt)[4. Rechtsbehelfsbelehrung]
#v(4pt)
#set text(size: 9.5pt)
#g("rechtsbehelf", default: "Gegen diesen Bescheid kann Einspruch eingelegt werden.")

#v(2cm)

// Signature/Footer Area
#align(right)[
  #text(size: 10pt)[
    #v(1cm)
    __________________________ \
    #text(size: 9pt, style: "italic")[Stempel und Unterschrift]
  ]
]
