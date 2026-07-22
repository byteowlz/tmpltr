// Kündigungsschreiben
// @description: Ordentliche Kündigung durch Arbeitgeber mit Frist und Freistellung
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.2cm, left: 2.5cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #g("arbeitgeber.firma") · #g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort") · Amtsgericht Düsseldorf HRB 44120 · Geschäftsführung: #g("arbeitgeber.vertreten_durch")
  ])
#set text(font: "Tinos", size: 11pt)
#set par(justify: true)

// DIN 5008 Falzmarken
#place(top + left, dx: -2cm, dy: 8.7cm)[#line(length: 4mm, stroke: 0.5pt + gray)]
#place(top + left, dx: -2cm, dy: 19.2cm)[#line(length: 4mm, stroke: 0.5pt + gray)]

// Briefkopf
#align(right)[
  #text(size: 13pt, weight: "bold")[#g("arbeitgeber.firma", default: "—")] \
  #text(size: 9pt, fill: gray.darken(40%))[#g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort")]
]
#v(6pt)
#line(length: 100%, stroke: 0.8pt)
#v(10pt)

// Anschriftfeld
#text(size: 7pt, fill: gray.darken(40%))[#g("arbeitgeber.firma") · #g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort")]
#v(4pt)
#g("arbeitnehmer.name", default: "—") \
#g("arbeitnehmer.strasse") \
#g("arbeitnehmer.plz_ort")

#let ort-teile = str(g("arbeitgeber.plz_ort", default: "")).split(" ")
#let ort = if ort-teile.len() > 1 { ort-teile.slice(1).join(" ") } else { "" }
#let name-teile = str(g("arbeitnehmer.name", default: "")).split(" ")
#let nachname = if name-teile.len() > 0 { name-teile.last() } else { "" }

#v(14pt)
#align(right)[#ort, den #g("kuendigung.datum", default: "18.07.2026")]
#v(10pt)

*Ordentliche Kündigung Ihres Arbeitsverhältnisses* \
*-- Einschreiben mit Rückschein --*
#v(8pt)

Sehr geehrter Herr #nachname,

#v(4pt)
hiermit kündigen wir das mit Ihnen seit dem *#g("kuendigung.eintrittsdatum", default: "—")*
bestehende Arbeitsverhältnis als #g("kuendigung.art", default: "ordentliche Kündigung")
fristgerecht zum

#align(center)[#text(size: 12pt, weight: "bold")[#g("kuendigung.beendigungsdatum", default: "—")]]

Die maßgebliche Kündigungsfrist beträgt #g("kuendigung.frist", default: "die gesetzliche Frist").
Vorsorglich kündigen wir hilfsweise zum nächstzulässigen Termin.

#v(6pt)
Bis zur Beendigung des Arbeitsverhältnisses stellen wir Sie
#g("kuendigung.freistellung", default: "unwiderruflich von der Arbeitsleistung frei").
Ihr Resturlaub von *#g("kuendigung.resturlaub_tage", default: "—") Arbeitstagen* wird
im Freistellungszeitraum gewährt und gilt damit als genommen.

#v(6pt)
#g("kuendigung.zeugnis_zusage", default: "Ein Arbeitszeugnis erhalten Sie mit den Austrittspapieren.")
Ihre Arbeitspapiere sowie die Meldebescheinigung zur Sozialversicherung senden wir
Ihnen nach dem Beendigungstermin zu.

#v(6pt)
*Hinweis nach § 38 SGB III:* Sie sind verpflichtet, sich unverzüglich, spätestens
jedoch drei Monate vor Beendigung des Arbeitsverhältnisses, persönlich bei der
Agentur für Arbeit arbeitsuchend zu melden. Eine verspätete Meldung kann zu
Nachteilen beim Arbeitslosengeld führen.

#v(6pt)
Wir danken Ihnen für die geleistete Arbeit und wünschen Ihnen für Ihren weiteren
Berufsweg alles Gute.

#v(14pt)
Mit freundlichen Grüßen

#v(26pt)
#line(length: 45%, stroke: 0.6pt)
#text(size: 9.5pt)[#g("arbeitgeber.vertreten_durch", default: "—") \ #g("arbeitgeber.firma")]

#v(18pt)
#line(length: 100%, stroke: (paint: gray, thickness: 0.5pt, dash: "dashed"))
#v(4pt)
#text(size: 9pt, fill: gray.darken(30%))[
  Erhalten am: #box(width: 80pt, line(length: 100%, stroke: 0.5pt + gray)) #h(16pt)
  Unterschrift Arbeitnehmer: #box(width: 130pt, line(length: 100%, stroke: 0.5pt + gray))
]
