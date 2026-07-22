// Abmahnung
// @description: Arbeitsrechtliche Abmahnung mit Sachverhalt, Pflichtverletzung, Konsequenzen
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.2cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(1pt)
    #g("arbeitgeber.firma") · #g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort") — Dieses Schreiben wird zur Personalakte genommen.
  ])
#set text(font: "Arimo", size: 10.5pt, lang: "de")
#set par(justify: true, leading: 0.68em, spacing: 0.95em)

// DIN 5008 fold marks
#place(top + left, dx: -1.7cm, dy: 8.7cm, line(length: 4mm, stroke: 0.5pt + gray))
#place(top + left, dx: -1.7cm, dy: 19.2cm, line(length: 4mm, stroke: 0.5pt + gray))

// Plain sober letterhead, right-aligned block
#align(right)[
  #text(weight: "bold", size: 12pt)[#g("arbeitgeber.firma", default: "—")] \
  #text(size: 9pt, fill: gray.darken(35%))[#g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort") \ Personalabteilung]
]
#v(8pt)
#text(size: 7pt, fill: gray.darken(30%))[#underline[#g("arbeitgeber.firma") · #g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort")]]
#v(6pt)
#g("arbeitnehmer.name", default: "—") \
#if g("arbeitnehmer.abteilung") != "" [Abteilung #g("arbeitnehmer.abteilung") \ ]
#if g("arbeitnehmer.personalnr") != "" [— persönlich / vertraulich —]
#v(14pt)
#grid(columns: (1fr, auto),
  [
    #text(size: 8.5pt, fill: gray.darken(35%))[
      Personal-Nr.: #g("arbeitnehmer.personalnr", default: "—")
    ]
  ],
  align(right)[#g("arbeitgeber.plz_ort", default: "—").split(" ").at(1, default: "") , den #g("abmahnung.datum", default: "—")])
#v(14pt)

#text(weight: "bold", size: 12.5pt)[Abmahnung]
#v(2pt)
#text(size: 9.5pt, fill: gray.darken(30%))[wegen Verletzung arbeitsvertraglicher Pflichten — Vorfall vom #g("abmahnung.vorfall_datum", default: "—")]
#v(10pt)

Sehr geehrte#{if lower(g("arbeitnehmer.name", default: "")).starts-with("frau") [] else [r]} #g("arbeitnehmer.name", default: "Mitarbeiter/in"),

wir müssen Sie leider wegen des nachfolgend dargestellten Sachverhalts förmlich abmahnen.

#text(weight: "bold", size: 10.5pt)[1. Sachverhalt]
#v(2pt)
#if g("abmahnung.sachverhalt") != "" [
  #g("abmahnung.sachverhalt")
] else [
  #text(fill: gray, style: "italic")[Der Sachverhalt wird gesondert dargelegt.]
]
#v(6pt)

#text(weight: "bold", size: 10.5pt)[2. Pflichtverletzung]
#v(2pt)
Ihr Verhalten stellt #g("abmahnung.pflichtverletzung", default: "eine Verletzung Ihrer arbeitsvertraglichen Pflichten") dar. Ein solches Verhalten können und werden wir nicht hinnehmen.
#v(6pt)

#text(weight: "bold", size: 10.5pt)[3. Aufforderung]
#v(2pt)
#g("abmahnung.frist", default: "Wir fordern Sie auf, Ihre arbeitsvertraglichen Pflichten künftig ordnungsgemäß zu erfüllen.")
#v(6pt)

#text(weight: "bold", size: 10.5pt)[4. Rechtsfolgen bei Wiederholung]
#v(2pt)
#g("abmahnung.konsequenzen", default: "Im Wiederholungsfall behalten wir uns weitere arbeitsrechtliche Schritte vor.")
#v(8pt)

Eine Kopie dieser Abmahnung wird zu Ihrer Personalakte genommen. Es steht
Ihnen frei, hierzu eine schriftliche Gegendarstellung abzugeben, die
ebenfalls zur Personalakte genommen wird.

#v(16pt)
Mit freundlichen Grüßen
#v(28pt)
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #line(length: 100%, stroke: 0.5pt + black)
    #v(-2pt)
    #text(size: 9pt)[#g("unterschrift.name", default: "—") \ #text(fill: gray.darken(35%))[#g("unterschrift.position")]]
  ],
  [
    #v(0pt)
  ])
#v(14pt)
#line(length: 100%, stroke: (dash: "dashed", paint: gray.darken(10%), thickness: 0.5pt))
#v(4pt)
#text(size: 9pt, fill: gray.darken(30%))[Erhalt der Abmahnung bestätigt:]
#v(18pt)
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [#line(length: 100%, stroke: 0.5pt + black) #text(size: 8pt, fill: gray.darken(35%))[Ort, Datum]],
  [#line(length: 100%, stroke: 0.5pt + black) #text(size: 8pt, fill: gray.darken(35%))[Unterschrift #g("arbeitnehmer.name", default: "Arbeitnehmer/in")]])
