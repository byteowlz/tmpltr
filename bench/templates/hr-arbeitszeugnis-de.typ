// Arbeitszeugnis
// @description: Qualifiziertes Arbeitszeugnis mit Tätigkeiten, Leistungsbeurteilung, Schlussformel
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(paper: "a4", margin: (top: 2.6cm, bottom: 2.8cm, x: 2.8cm),
  footer: [
    #set text(size: 8pt, fill: gray.darken(20%))
    #align(center)[#g("arbeitgeber.firma") · #g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort")]
  ])
#set text(font: "New Computer Modern", size: 11pt, hyphenate: true, lang: "de")
#set par(justify: true, leading: 0.72em, spacing: 1.05em)

// Centered classic letterhead
#align(center)[
  #text(size: 15pt, weight: "bold", tracking: 0.6pt)[#g("arbeitgeber.firma")]
  #v(1pt)
  #text(size: 9.5pt)[#g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort")]
  #if g("arbeitgeber.branche") != "" [
    #v(0pt)
    #text(size: 9pt, style: "italic", fill: gray.darken(45%))[#g("arbeitgeber.branche")]
  ]
]
#v(4pt)
#line(length: 100%, stroke: 0.7pt + black)
#v(0pt, weak: true)
#line(length: 100%, stroke: 0.3pt + black)
#v(26pt)

#align(center)[
  #text(size: 14pt, weight: "bold", tracking: 3pt)[ARBEITSZEUGNIS]
]
#v(16pt)

#let an-name = g("arbeitnehmer.name", default: "—")
#let position = g("arbeitnehmer.position", default: "—")

#an-name, geboren am #g("arbeitnehmer.geburtsdatum", default: "—"), war vom
*#g("arbeitnehmer.eintritt", default: "—")* bis zum
*#g("arbeitnehmer.austritt", default: "—")* als
*#position* in unserem Unternehmen tätig.

#if g("arbeitgeber.branche") != "" [
  Unser Unternehmen ist im Bereich #g("arbeitgeber.branche") tätig.
]

#let taet = g("zeugnis.taetigkeiten")
#if taet != "" [
  Das Aufgabengebiet umfasste insbesondere:
  #v(2pt)
  #pad(left: 10pt)[
    #for t in taet.split(";") [
      #box(width: 8pt)[–] #t.trim()\
    ]
  ]
]

#if g("zeugnis.leistung_note_text") != "" [
  #g("zeugnis.leistung_note_text")
]

#if g("zeugnis.verhalten_text") != "" [
  #g("zeugnis.verhalten_text")
]

#if g("zeugnis.austrittsgrund") != "" [
  Das Arbeitsverhältnis endet zum #g("arbeitnehmer.austritt", default: "—")
  #g("zeugnis.austrittsgrund").
]

#if g("zeugnis.schlussformel") != "" [
  #g("zeugnis.schlussformel")
]

#v(28pt)
#g("ausstellung.ort", default: "—"), den #g("ausstellung.datum", default: "—")
#v(34pt)
#line(length: 6.2cm, stroke: 0.5pt + black)
#v(-3pt)
#text(size: 10pt)[
  #g("ausstellung.unterzeichner", default: "—") \
  #text(style: "italic", fill: gray.darken(45%))[#g("ausstellung.unterzeichner_position")]
]
