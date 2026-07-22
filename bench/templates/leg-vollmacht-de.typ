// Vollmacht
// @description: Allgemeine/besondere Vollmacht mit Umfang und Widerruf
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let umfang = {
  let u = get(data, "vollmacht.umfang", default: ())
  if type(u) == array { u } else { () }
}
#let widerruflich = g("vollmacht.widerruflich", default: true)

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.2cm, left: 2.4cm, right: 2.4cm))
#set text(font: "Libertinus Serif", size: 11pt, lang: "de")
#set par(justify: true, leading: 0.75em)

// Certificate frame
#block(width: 100%, height: 100%, stroke: 1.4pt + rgb("#3b3b3b"), inset: 6pt)[
  #block(width: 100%, height: 100%, stroke: 0.5pt + rgb("#3b3b3b"), inset: (x: 1.6cm, y: 1.4cm))[

    #align(center)[
      #text(size: 22pt, weight: "bold", tracking: 5pt)[VOLLMACHT]
      #v(4pt)
      #line(length: 30%, stroke: 0.8pt)
      #v(2pt)
      #text(size: 10pt, style: "italic", fill: gray.darken(55%))[#g("vollmacht.art", default: "Vollmacht")]
    ]

    #v(22pt)

    #text(size: 9pt, tracking: 1.2pt, fill: gray.darken(45%))[VOLLMACHTGEBER/IN]
    #v(4pt)
    #text(size: 12pt, weight: "bold")[#g("vollmachtgeber.name", default: "—")] \
    #g("vollmachtgeber.strasse", default: "—"), #g("vollmachtgeber.plz_ort", default: "—") \
    geboren am #g("vollmachtgeber.geburtsdatum", default: "—"), Ausweis-Nr. #g("vollmachtgeber.ausweis_nr", default: "—")

    #v(14pt)
    #align(center)[#text(style: "italic")[erteilt hiermit]]
    #v(14pt)

    #text(size: 9pt, tracking: 1.2pt, fill: gray.darken(45%))[BEVOLLMÄCHTIGTE/R]
    #v(4pt)
    #text(size: 12pt, weight: "bold")[#g("bevollmaechtigter.name", default: "—")] \
    #g("bevollmaechtigter.strasse", default: "—"), #g("bevollmaechtigter.plz_ort", default: "—") \
    geboren am #g("bevollmaechtigter.geburtsdatum", default: "—")

    #v(14pt)
    Vollmacht, mich in den nachfolgend bezeichneten Angelegenheiten gerichtlich und
    außergerichtlich zu vertreten:

    #v(6pt)
    #if umfang.len() > 0 [
      #pad(left: 0.5cm)[
        #for (i, u) in umfang.enumerate() [
          #grid(columns: (auto, 1fr), column-gutter: 8pt, row-gutter: 0pt,
            text(weight: "bold")[#(i + 1).],
            [#u])
          #v(5pt)
        ]
      ]
    ] else [
      #pad(left: 0.5cm)[#text(fill: gray)[— Umfang gemäß gesonderter Aufstellung —]]
    ]

    #v(10pt)
    Die Vollmacht gilt ab dem *#g("vollmacht.gueltig_ab", default: "—")*
    #if g("vollmacht.gueltig_bis") != "" [bis einschließlich *#g("vollmacht.gueltig_bis")*]
    #if widerruflich == false [
      und ist *unwiderruflich* erteilt.
    ] else [
      und kann jederzeit ohne Angabe von Gründen schriftlich *widerrufen* werden.
    ]
    Der Bevollmächtigte ist von den Beschränkungen des § 181 BGB nicht befreit.
    Untervollmacht darf nicht erteilt werden.

    #v(1fr)

    #grid(columns: (1fr, 1fr), column-gutter: 1.6cm,
      [
        #v(26pt)
        #line(length: 100%, stroke: 0.7pt)
        #text(size: 9pt)[#g("unterschrift.ort", default: "Ort"), den #g("unterschrift.datum", default: "") \ Unterschrift Vollmachtgeber/in]
      ],
      [
        #v(26pt)
        #line(length: 100%, stroke: 0.7pt)
        #text(size: 9pt)[#g("unterschrift.ort", default: "Ort"), den #g("unterschrift.datum", default: "") \ Unterschrift Bevollmächtigte/r]
      ])
  ]
]
