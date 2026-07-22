// Arztbrief
// @description: Entlass-/Befundbrief: Diagnosen, Anamnese, Therapie, Empfehlung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let weinrot = rgb("#7a1f2b")
// Fix: Ensure defaults for lists are arrays () to prevent .map() errors on strings
#let diagnosen = get(data, "brief.diagnosen", default: ())
#let medikation = get(data, "brief.medikation", default: ())

#set page(paper: "a4", margin: (top: 1.7cm, bottom: 2.3cm, left: 2.5cm, right: 2.0cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + weinrot)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [#g("absender.klinik", default: "") · #g("absender.abteilung", default: "") \
       #g("absender.strasse", default: "") · #g("absender.plz_ort", default: "") · Telefon #g("absender.telefon", default: "")],
      align(right + bottom)[Seite 1])
  ])
#set text(font: "Libertinus Serif", size: 10.5pt)
#set par(justify: true)

// Faltmarken (DIN 5008)
#place(top + left, dx: -2.0cm, dy: 8.7cm, line(length: 4mm, stroke: 0.4pt + gray))
#place(top + left, dx: -2.0cm, dy: 19.2cm, line(length: 4mm, stroke: 0.4pt + gray))

// Briefkopf
#align(center)[
  #text(size: 14pt, weight: "bold", fill: weinrot)[#g("absender.klinik", default: "Klinikum")] \
  #text(size: 10pt, style: "italic")[#g("absender.abteilung", default: "")] \
  #v(1pt)
  #text(size: 8.5pt, fill: gray.darken(50%))[Chefarzt: #g("absender.chefarzt", default: "") · #g("absender.strasse", default: "") · #g("absender.plz_ort", default: "") · Tel. #g("absender.telefon", default: "")]
]
#v(3pt)
#line(length: 100%, stroke: (paint: weinrot, thickness: 1.2pt))
#line(length: 100%, stroke: (paint: weinrot, thickness: 0.4pt))
#v(14pt)

// Anschrift + Datum
#grid(columns: (1fr, auto), column-gutter: 12pt,
  [
    #text(size: 7pt, fill: gray.darken(40%))[#g("absender.klinik", default: "") · #g("absender.strasse", default: "") · #g("absender.plz_ort", default: "")]
    #v(4pt)
    #g("empfaenger.name", default: "—") \
    #g("empfaenger.praxis", default: "") \
    #g("empfaenger.strasse", default: "") \
    #g("empfaenger.plz_ort", default: "")
  ],
  align(right)[
    #text(size: 9pt)[
      Datum: *#g("patient.entlassung", default: "—")* \
      Aufnahme: #g("patient.aufnahme", default: "—") \
      Entlassung: #g("patient.entlassung", default: "—")
    ]
  ])
#v(16pt)

#let pat_name = g("patient.name", default: "—")
#let pat_geb = g("patient.geburtsdatum", default: "")
#let pat_auf = g("patient.aufnahme", default: "—")
#let pat_ent = g("patient.entlassung", default: "—")

*Betr.: Ihr Patient #pat_name#if pat_geb != "" [, geb. #pat_geb]* \
#v(6pt)

Sehr geehrte Kollegin, sehr geehrter Kollege,

wir berichten über den oben genannten Patienten, der sich vom
#pat_auf bis zum #pat_ent
in unserer stationären Behandlung befand.

#v(6pt)
#text(weight: "bold", fill: weinrot)[Diagnosen]
#if type(diagnosen) == array and diagnosen.len() > 0 [
  #enum(..diagnosen.map(d => [#d]), indent: 4pt, spacing: 5pt)
] else [
  #text(fill: gray)[— keine Angaben —]
]

#let abschnitt(titel, pfad) = {
  let content = g(pfad, default: "")
  if content != "" [
    #v(5pt)
    #text(weight: "bold", fill: weinrot)[#titel] \
    #content
  ]
}
#abschnitt("Anamnese", "brief.anamnese")
#abschnitt("Befunde", "brief.befund")
#abschnitt("Therapie und Verlauf", "brief.therapie")

#if type(medikation) == array and medikation.len() > 0 [
  #v(5pt)
  #text(weight: "bold", fill: weinrot)[Medikation bei Entlassung] \
  #v(2pt)
  #block(inset: (left: 8pt), list(..medikation.map(m => [#m]), spacing: 4pt))
]

#abschnitt("Procedere / Empfehlung", "brief.empfehlung")

#v(10pt)
Mit freundlichen kollegialen Grüßen
#v(26pt)
#grid(columns: (auto, 1fr, auto), column-gutter: 20pt,
  [
    #line(length: 5.2cm, stroke: 0.5pt)
    #text(size: 9pt)[#g("unterzeichner.name", default: "—") \ #g("unterzeichner.position", default: "")]
  ],
  [],
  [
    #line(length: 5.2cm, stroke: 0.5pt)
    #text(size: 9pt)[#g("absender.chefarzt", default: "—") \ Chefarzt]
  ])
