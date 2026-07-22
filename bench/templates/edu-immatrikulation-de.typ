// Immatrikulationsbescheinigung
// @description: Studienbescheinigung mit Studiengang, Fachsemester, Semesterzeitraum
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let accent = rgb("#00589c")

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.2cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #g("hochschule.name") · #g("hochschule.strasse") · #g("hochschule.plz_ort")
    #h(1fr) Studierendenverwaltung · Immatrikulationsamt
  ])
#set text(font: "Arimo", size: 10.5pt)

// Header: logo box left, university block right
#let hs = g("hochschule.name", default: "··")
#let initials = upper(hs.clusters().slice(0, calc.min(3, hs.clusters().len())).join(""))
#grid(columns: (auto, 1fr), column-gutter: 12pt,
  box(fill: accent, inset: 9pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 14pt)[#initials]
  ],
  align(right)[
    #text(weight: "bold", size: 11.5pt, fill: accent)[#g("hochschule.name")] \
    #text(size: 9pt)[#g("hochschule.strasse") · #g("hochschule.plz_ort")] \
    #text(size: 8.5pt, fill: gray.darken(20%))[Studierendenverwaltung — Immatrikulationsamt]
  ])
#v(6pt)
#line(length: 100%, stroke: 1.2pt + accent)
#v(22pt)

#text(size: 17pt, weight: "bold")[Immatrikulationsbescheinigung]
#v(2pt)
#text(size: 9.5pt, fill: gray.darken(20%))[gemäß § 9 der Einschreibordnung — zur Vorlage bei Behörden, Krankenkassen und Arbeitgebern]
#v(16pt)

Hiermit wird bescheinigt, dass

#v(8pt)
#align(center)[
  #text(size: 13pt, weight: "bold")[#g("student.name")] \
  #v(2pt)
  #text(size: 10pt)[geboren am #g("student.geburtsdatum") · Matrikelnummer #g("student.matrikelnr")]
]
#v(8pt)

im *#g("studium.semester", default: "laufenden Semester")* an der #g("hochschule.name") als ordentliche_r Studierende_r eingeschrieben ist.

#v(14pt)

#table(
  columns: (auto, 1fr),
  stroke: (x, y) => (bottom: 0.4pt + gray.lighten(40%)),
  inset: (x: 8pt, y: 6.5pt),
  fill: (x, y) => if x == 0 { rgb("#eef4fa") } else { white },
  [#text(weight: "bold", size: 9.5pt)[Studiengang]], [#g("studium.studiengang")],
  [#text(weight: "bold", size: 9.5pt)[Angestrebter Abschluss]], [#g("studium.abschluss")],
  [#text(weight: "bold", size: 9.5pt)[Fachsemester]], [#str(g("studium.fachsemester", default: "—"))],
  [#text(weight: "bold", size: 9.5pt)[Hochschulsemester]], [#str(g("studium.hochschulsemester", default: "—"))],
  [#text(weight: "bold", size: 9.5pt)[Semesterbeitrag entrichtet]], [#g("studium.semesterbeitrag_bezahlt")],
)
#v(18pt)

#text(size: 9pt)[
  Diese Bescheinigung gilt nur für das oben genannte Semester. Die Mitgliedschaft
  in der Studierendenschaft besteht für die Dauer der Einschreibung.
]
#v(20pt)

#g("hochschule.plz_ort"), den #g("ausstellung.datum")
#v(14pt)
#text(size: 9pt, style: "italic", fill: gray.darken(20%))[
  Diese Bescheinigung wurde maschinell erstellt und ist ohne Unterschrift gültig.
]
