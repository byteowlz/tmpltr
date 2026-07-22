// SEPA-Lastschriftmandat
// @description: Einzugsermächtigung mit Gläubiger-ID, Mandatsreferenz, Kontodaten
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Libertinus Serif", size: 10pt, lang: "de")

// Header / Gläubiger Section
#grid(columns: (1fr, auto),
  align(left)[
    #text(size: 18pt, weight: "bold")[SEPA-Lastschriftmandat] \
    #text(size: 10pt, fill: gray.darken(50%))[Einzugsermächtigung]
  ],
  align(right)[
    #box(fill: rgb("#e0e0e0"), inset: 8pt, radius: 2pt)[
      #text(size: 8pt, weight: "bold")[Gläubiger-ID] \
      #text(size: 10pt, font: "Cousine")[#g("glaeubiger.glaeubiger_id", default: "DE00ZZZ00000000000000")]
    ]
  ]
)

#v(12pt)
#line(length: 100%, stroke: 0.5pt + black)
#v(12pt)

// Mandatsdetails
#text(weight: "bold", size: 11pt)[Mandatsinformationen]
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #text(fill: gray.darken(50%), size: 8pt)[Mandatsreferenz] \
    #g("mandat.referenz", default: "—")
  ],
  [
    #text(fill: gray.darken(50%), size: 8pt)[Art der Zahlung] \
    #g("mandat.art", default: "—")
  ]
)

#v(12pt)

// Zahler Section
#text(weight: "bold", size: 11pt)[Zahlungsempfänger (Gläubiger)]
#v(2pt)
#g("glaeubiger.name", default: "—") \
#g("glaeubiger.strasse", default: "—") \
#g("glaeubiger.plz_ort", default: "—")

#v(12pt)

#text(weight: "bold", size: 11pt)[Kontoinhaber (Zahler)]
#v(2pt)
#g("zahler.name", default: "—") \
#g("zahler.strasse", default: "—") \
#g("zahler.plz_ort", default: "—")

#v(12pt)

// Bankverbindung Box
#rect(width: 100%, stroke: 0.5pt + black, inset: 12pt, radius: 2pt)[
  #text(weight: "bold", size: 10pt)[Bankverbindung des Zahlers]
  #v(6pt)
  #grid(columns: (auto, 1fr), column-gutter: 10pt,
    [Bank:], [#g("zahler.bank", default: "—")],
    [IBAN:], [#text(font: "Cousine", size: 11pt)[#g("zahler.iban", default: "—")]],
    [BIC:], [#text(font: "Cousine")[#g("zahler.bic", default: "—")]]
  )
]

#v(12pt)

// Instruction Text
// We use a scoped set rule to avoid passing 'leading' to the text() function
#set text(size: 9pt)
#set par(leading: 1.2em)
[
  Ich ermächtige den oben genannten Gläubiger, Zahlungen von meinem Konto einzuziehen. 
  Diese Einzugsermächtigung ist gültig bis auf Widerruf. 
  Die Zahlungen erfolgen gemäß den Bedingungen der SEPA-Lastschrift.
]

#v(24pt)

// Signature Area
#grid(columns: (1fr, 1fr),
  align(left)[
    #text(size: 9pt, fill: gray.darken(50%))[Ort, Datum] \
    #v(10pt)
    #g("unterschrift.ort", default: "—"), #g("unterschrift.datum", default: "—"),
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(50%))[Unterschrift des Kontoinhabers] \
    #v(20pt)
    #line(length: 80%, stroke: 0.5pt + black)
  ]
)

#v(1fr)

// Footer
#set text(size: 7pt, fill: gray)
#align(center)[
  Dies ist ein rechtlich bindendes SEPA-Lastschriftmandat. 
  Bei Rückfragen wenden Sie sich bitte an den Kundenservice.
]
