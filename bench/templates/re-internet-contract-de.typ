// Internet-Vertragsbestätigung
// @description: DSL/Glasfaser-Auftragsbestätigung mit Tarif und Schaltungstermin
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, sym: "$") = {
  // Guard against empty strings or non-numeric input before converting to float
  let val_str = str(x)
  if val_str == "" { return sym + "0,00" }
  
  let v = calc.round(float(val_str), digits: 2)
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
  let val_str = str(x)
  if val_str == "" { return "0,00 €" }
  let s = money(val_str, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

// Styling constants
#let accent = rgb("#005bb7")
#let secondary = rgb("#f0f4f8")
#let text-main = rgb("#333333")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Adwaita Sans", size: 10pt, fill: text-main)

// Header: Logo and Title
#grid(columns: (1fr, auto),
  [
    #let provider = g("anbieter.name", default: "Telekom")
    // Guard array indexing for initials
    #let provider_clusters = provider.clusters()
    #let initials = upper(provider_clusters.slice(0, calc.min(2, provider_clusters.len())).join(""))
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#initials]
    ]
    #v(4pt)
    #text(size: 9pt, fill: gray.darken(50%))[#g("anbieter.hotline", default: "")]
  ],
  align(right)[
    #text(size: 18pt, weight: "bold", fill: accent)[Vertragsbestätigung] \
    #text(size: 10pt, fill: gray.darken(50%))[Datum: #g("vertrag.datum", default: "")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 0.5pt + accent)
#v(10pt)

// Sender and Receiver
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #text(weight: "bold", size: 9pt, fill: accent)[Absender] \
    #v(2pt)
    #g("anbieter.name", default: "") \
    #g("anbieter.strasse", default: "") \
    #g("anbieter.plz_ort", default: "")
  ],
  [
    #text(weight: "bold", size: 9pt, fill: accent)[Empfänger] \
    #v(2pt)
    #g("kunde.name", default: "") \
    #g("kunde.strasse", default: "") \
    #g("kunde.plz_ort", default: "") \
    #text(size: 9pt, fill: gray.darken(50%))[Kundennummer: #g("kunde.kundennr", default: "")]
  ]
)

#v(20pt)

// Contract Summary Card
#block(fill: secondary, inset: 15pt, radius: 4pt, width: 100%)[
  #grid(columns: (1fr, 1fr, 1fr),
    [
      #text(size: 8pt, weight: "bold", fill: accent)[TARIF] \
      #v(4pt)
      #text(size: 12pt, weight: "bold")[#g("vertrag.tarif", default: "")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: accent)[SPEED] \
      #v(4pt)
      #text(size: 12pt, weight: "bold")[#g("vertrag.download_mbit", default: "0") / #g("vertrag.upload_mbit", default: "0") Mbit/s]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: accent)[SCHALTUNG] \
      #v(4pt)
      #text(size: 10pt, weight: "bold")[#g("vertrag.schaltungstermin", default: "")]
    ]
  )
]

#v(15pt)

// Detailed breakdown
#text(size: 12pt, weight: "bold")[Details zu Ihrem Anschluss]
#v(5pt)

#table(
  columns: (1fr, auto),
  stroke: none,
  inset: 6pt,
  column-gutter: 10pt,
  row-gutter: 8pt,
  [Monatliche Grundgebühr (#g("vertrag.laufzeit_monate", default: "0") Monate)], [#geld(g("vertrag.monatspreis", default: "0"))],
  [Einmalige Bereitstellung], [#geld(g("vertrag.einrichtungspreis", default: "0"))],
  [Hardware (#g("vertrag.router", default: ""))], [#text(size: 9pt, style: "italic", fill: gray.darken(50%))[inklusive]],
  [Rufnummern], [#g("vertrag.rufnummern", default: "-")]
)

#v(10pt)
#line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
#v(5pt)

// Financial Summary
#align(right)[
  #let m_preis = if g("vertrag.monatspreis", default: "0") == "" { 0.0 } else { float(g("vertrag.monatspreis", default: "0")) }
  #let e_preis = if g("vertrag.einrichtungspreis", default: "0") == "" { 0.0 } else { float(g("vertrag.einrichtungspreis", default: "0")) }
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 2pt,
    [#text(size: 9pt)[Gesamtbetrag erste Rechnung:]], [#text(weight: "bold")[#geld(m_preis + e_preis)]]
  )
]

#v(20pt)

// Footer Info
#block(width: 100%, stroke: (left: 2pt + accent), inset: (left: 10pt))[
  #text(size: 9pt)[
    *Wichtige Hinweise:* \
    Die Schaltung erfolgt zum oben genannten Termin. Bitte stellen Sie sicher, dass der Techniker Zugang zum Hausanschluss hat. 
    Die monatlichen Kosten verstehen sich inklusive der gesetzlichen Mehrwertsteuer.
  ]
]

#v(1fr)

#set text(size: 7pt, fill: gray.darken(50%))
#align(center)[
  #g("anbieter.name", default: "") · #g("anbieter.strasse", default: "") · #g("anbieter.plz_ort", default: "") \
  Handelsregister: HRB 12345 · USt-IdNr.: DE 987654321 \
  Support-Hotline: #g("anbieter.hotline", default: "")
]
