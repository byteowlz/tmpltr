// Kündigungsbestätigung Versicherung
// @description: Bestätigung der Vertragskündigung mit Enddatum und Rückerstattung
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

#set text(font: "Libertinus Serif", size: 11pt, lang: "de")

// Header: Logo and Company Info
#let company-name = g("versicherer.name", default: "Versicherung AG")
#let initials = upper(company-name.clusters().slice(0, calc.min(2, company-name.clusters().len())).join(""))

#grid(columns: (1fr, auto),
  align(left)[
    #box(fill: rgb("#2e5a88"), inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 18pt)[#initials]
    ]
  ],
  align(right)[
    #text(weight: "bold", size: 12pt)[#company-name] \
    #g("versicherer.strasse", default: "") \
    #g("versicherer.plz_ort", default: "")
  ]
)

#v(1.5cm)

// Recipient Address
#block(width: 70%)[
  #text(size: 10pt)[
    #g("versicherungsnehmer.name", default: "") \
    #g("versicherungsnehmer.strasse", default: "") \
    #g("versicherungsnehmer.plz_ort", default: "")
  ]
]

#v(1cm)

// Subject and Date
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 13pt)[
      Bestätigung Ihrer Vertragskündigung \
      Versicherung: #g("kuendigung.sparte", default: "")
    ]
  ],
  align(right)[
    #text(size: 10pt)[#g("kuendigung.eingang_datum", default: "")]
  ]
)

#v(0.5cm)

// Content
#text(size: 11pt)[
  Sehr geehrte Damen und Herren, \
  hiermit bestätigen wir den Erhalt Ihrer Kündigung.
]

#v(0.5cm)

#set text(size: 11pt)
#table(
  columns: (1fr, 1fr),
  stroke: none,
  inset: 8pt,
  table.header([*Details zum Vertrag:*], []),
  [Vertragsnummer:], [*#g("kuendigung.vertragsnr", default: "—")*],
  [Versicherungsart:], [#g("kuendigung.sparte", default: "—")],
  [Kündigung wirksam zum:], [#g("kuendigung.wirksam_zum", default: "—")],
  [Eingangsdatum:], [#g("kuendigung.eingang_datum", default: "—")],
)

#v(0.8cm)

// Refund Section
#rect(
  width: 100%,
  stroke: 0.5pt + gray,
  fill: rgb("#f9f9f9"),
  inset: 15pt
)[
  #text(weight: "bold", size: 12pt)[Rückerstattung / Abrechnung]
  #v(5pt)
  #grid(columns: (1fr, auto),
    [Aufgrund der Kündigung steht Ihnen eine anteilige Rückerstattung zu:],
    [#geld(float(g("kuendigung.restbeitrag_erstattung", default: 0)))]
  )
  #v(5pt)
  #grid(columns: (1fr, auto),
    [Die Auszahlung erfolgt auf Ihr hinterlegtes Konto (Endnummer #g("kuendigung.iban_letzte4", default: "....")):],
    [#text(weight: "bold")[In Kürze] ]
  )
]

#v(1.5cm)

// Closing
#text(size: 11pt)[
  Wir danken Ihnen für das bisherige Vertrauen und stehen Ihnen bei Fragen gerne zur Verfügung.
  
  Mit freundlichen Grüßen \
  #company-name \
  Kundenservice
]

#v(2cm)

// Footer
#set page(footer: [
  #set text(size: 8pt, fill: gray)
  #line(length: 100%, stroke: 0.25pt + gray)
  #v(2pt)
  #align(center)[
    #g("versicherer.name", default: "") · #g("versicherer.strasse", default: "") · #g("versicherer.plz_ort", default: "") \
    Handelsregister: HR 12345 · USt-IdNr.: DE 987654321
  ]
])
