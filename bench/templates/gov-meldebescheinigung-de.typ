// Meldebescheinigung
// @description: Amtliche Meldebestätigung mit Wohnsitz und Einzugsdatum
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)

#set text(font: "Libertinus Serif", size: 11pt, lang: "de")

// Header: Authority Info
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(weight: "bold", size: 14pt)[#g("behoerde.name")] \
    #text(size: 10pt)[#g("behoerde.strasse")] \
    #g("behoerde.plz_ort")
  ],
  [
    #text(size: 10pt)[Ausstellungsdatum: #g("ausstellung.datum")]
  ]
)

#v(2cm)

// Title
#align(center)[
  #text(size: 22pt, weight: "bold")[Meldebescheinigung] \
  #v(4pt)
  #text(size: 12pt, style: "italic")[gemäß Bundesmeldegesetz (BMG)]
]

#v(1.5cm)

// Main Content Section
#block(width: 100%, stroke: 0.5pt + gray, inset: 15pt, radius: 2pt)[
  #text(weight: "bold", size: 12pt)[Angaben zur Person:]
  #v(8pt)
  #grid(
    columns: (1fr, 1.5fr),
    row-gutter: 10pt,
    column-gutter: 20pt,
    [Name,],
    [#g("person.name")],
    [Geburtsdatum,],
    [#g("person.geburtsdatum")],
    [Geburtsort,],
    [#g("person.geurtsort", default: g("person.geburtsort"))],
    [Staatsangehörigkeit,],
    [#g("person.staatsangehoerigkeit")],
    [Familienstand,],
    [#g("person.familienstand")],
  )
]

#v(1cm)

#block(width: 100%, stroke: 0.5pt + gray, inset: 15pt, radius: 2pt)[
  #text(weight: "bold", size: 12pt)[Wohnsitzangaben:]
  #v(8pt)
  #grid(
    columns: (1fr, 1.5fr),
    row-gutter: 10pt,
    column-gutter: 20pt,
    [Anschrift,],
    [#g("meldung.wohnung_strasse"), #g("meldung.wohnung_plz_ort")],
    [Einzugsdatum,],
    [#g("meldung.einzugsdatum")],
    [Wohnungsstatus,],
    [#g("meldung.wohnungsstatus")],
    [Weitere Wohnsitze,],
    [#g("meldung.weitere_wohnsitze")],
  )
]

#v(2cm)

// Signature / Footer Section
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 10pt)[
      *Bescheinigung über:* \
      #g("meldung.wohnungsstatus", default: "den aktuellen Wohnsitz") \
      #v(4pt)
      *Gebühr:* #g("ausstellung.gebuehr", default: "0,00 €")
    ]
  ],
  align(right)[
    #v(10pt)
    #text(size: 10pt)[
      #g("ausstellung.sachbearbeiter", default: "–") \
      #line(length: 4cm, stroke: 0.5pt) \
      #text(size: 9pt, style: "italic")[Dienstsiegel / Unterschrift]
    ]
  ]
)

#v(1fr)

// Bottom Disclaimer
#set text(size: 8pt, fill: gray.darken(50%))
#align(center)[
  Diese Bescheinigung dient als amtlicher Nachweis über den gemeldeten Wohnsitz. 
  Eine Fälschung dieses Dokuments wird strafrechtlich verfolgt.
]
