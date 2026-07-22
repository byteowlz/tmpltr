// Schadenmeldung
// @description: KFZ-/Haftpflicht-Schadenmeldung mit Hergang und Beteiligten
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let petrol = rgb("#0d5c63")
#let beteiligte = data.at("beteiligte", default: ())

// underlined fill-in field with small label to the left
#let feld(label, value, w: 100%) = box(width: w)[
  #grid(columns: (auto, 1fr), column-gutter: 5pt, align: bottom,
    text(size: 8pt, fill: gray.darken(45%))[#label:],
    box(stroke: (bottom: (thickness: 0.6pt, dash: "dotted", paint: gray.darken(30%))), inset: (bottom: 2pt), width: 100%)[
      #text(size: 9.5pt, weight: "medium")[#value]
    ])
]
// checkbox square
#let kk(checked) = box(width: 9pt, height: 9pt, stroke: 0.9pt + petrol, baseline: 1.5pt, radius: 1pt)[
  #if checked { align(center + horizon, text(size: 8pt, weight: "bold", fill: petrol)[✕]) }
]
// section header: number in square + rule
#let abschnitt(no, title) = {
  v(10pt)
  grid(columns: (auto, auto, 1fr), column-gutter: 7pt, align: horizon,
    box(fill: petrol, width: 15pt, height: 15pt)[#align(center + horizon, text(fill: white, weight: "bold", size: 9.5pt)[#no])],
    text(weight: "bold", size: 10.5pt, fill: petrol)[#upper(title)],
    line(length: 100%, stroke: 0.7pt + petrol))
  v(5pt)
}

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 1.8cm, x: 1.9cm),
  footer: [
    #set text(size: 6.8pt, fill: gray.darken(40%))
    #grid(columns: (1fr, auto),
      [#g("versicherer.name") · #g("versicherer.strasse") · #g("versicherer.plz_ort")],
      [Vordruck S-24 (Stand 01/2026) · Seite 1 von 1])
  ])
#set text(font: "Arimo", size: 9.5pt, lang: "de")

// Header: title left, insurer block right
#grid(columns: (1fr, auto), column-gutter: 14pt, align: (top, top),
  [
    #text(size: 19pt, weight: "bold", fill: petrol)[Schadenmeldung]\
    #text(size: 9pt, fill: gray.darken(40%))[Bitte vollständig ausfüllen und innerhalb von 7 Tagen an Ihren Versicherer senden.]
  ],
  align(right)[
    #let vname = g("versicherer.name", default: "··")
    #let ini = upper(vname.clusters().slice(0, calc.min(2, vname.clusters().len())).join(""))
    #grid(columns: (auto, auto), column-gutter: 8pt, align: (right + top, top),
      [
        #text(weight: "bold", size: 10.5pt)[#g("versicherer.name", default: "Versicherer")]\
        #text(size: 8pt)[#g("versicherer.strasse")\ #g("versicherer.plz_ort")]
      ],
      box(fill: petrol, inset: 7pt, radius: 2pt)[#text(fill: white, weight: "bold", size: 12pt)[#ini]])
  ])
#v(3pt)
#block(fill: petrol.lighten(90%), stroke: (left: 2.5pt + petrol), inset: (x: 8pt, y: 5pt), width: 100%)[
  #grid(columns: (1fr, 1fr), column-gutter: 12pt,
    feld("Versicherungsschein-Nr.", text(weight: "bold")[#g("melder.versicherungsnr", default: "")]),
    feld("Schaden-Nr. (vom Versicherer)", ""))
]

#abschnitt("1", "Angaben zur meldenden Person")
#feld("Name, Vorname", g("melder.name"))
#v(7pt)
#grid(columns: (1fr, 1.4fr), column-gutter: 14pt,
  feld("Telefon", g("melder.telefon")),
  feld("E-Mail", g("melder.email")))
#v(7pt)
#feld("IBAN (für Erstattungen)", g("melder.iban"))

#abschnitt("2", "Angaben zum Schaden")
#grid(columns: (1fr, 1fr, 1.6fr), column-gutter: 14pt,
  feld("Schadentag", g("schaden.datum")),
  feld("Uhrzeit", g("schaden.uhrzeit")),
  feld("Polizei-Aktenzeichen", g("schaden.polizei_aktenzeichen", default: "—")))
#v(7pt)
#feld("Schadenort (Straße, PLZ, Ort)", g("schaden.ort"))
#v(8pt)
#let art = lower(g("schaden.art", default: ""))
#let ist-kfzh = art.contains("kfz") and art.contains("haftpflicht")
#let ist-kasko = art.contains("kasko")
#let ist-privath = art.contains("privathaftpflicht")
#let ist-hausrat = art.contains("hausrat")
#let ist-sonst = art != "" and not (ist-kfzh or ist-kasko or ist-privath or ist-hausrat)
#text(size: 8pt, fill: gray.darken(45%))[Schadenart (Zutreffendes bitte ankreuzen):]
#v(3pt)
#grid(columns: (auto, auto, auto, auto, 1fr), column-gutter: 16pt,
  [#kk(ist-kfzh) #h(4pt) KFZ-Haftpflicht],
  [#kk(ist-kasko) #h(4pt) Kasko],
  [#kk(ist-privath) #h(4pt) Privathaftpflicht],
  [#kk(ist-hausrat) #h(4pt) Hausrat],
  [#kk(ist-sonst) #h(4pt) Sonstiges: #text(size: 8.5pt)[#if ist-sonst [#g("schaden.art")]]])
#v(8pt)
#block(stroke: 0.6pt + gray.darken(25%), inset: (x: 7pt, y: 6pt), width: 100%, radius: 2pt)[
  #text(size: 8pt, fill: gray.darken(45%))[Schilderung des Schadenhergangs (Wer? Was? Wie? Bitte ggf. Skizze beilegen.)]
  #v(3pt)
  #text(size: 9pt)[#g("schaden.hergang", default: "")]
  #v(3pt)
]
#v(7pt)
#feld("Zeugen (Name, Anschrift, Telefon)", g("schaden.zeugen", default: "—"))

#abschnitt("3", "Beteiligte / Geschädigte")
#if beteiligte.len() > 0 {
  table(
    columns: (1.8fr, auto, 1.2fr),
    align: (left, center, left),
    stroke: 0.5pt + gray.darken(15%),
    inset: (x: 6pt, y: 5pt),
    fill: (_, row) => if row == 0 { petrol.lighten(88%) } else { white },
    table.header(
      [#text(size: 8pt, weight: "bold", fill: petrol)[Name und Anschrift]],
      [#text(size: 8pt, weight: "bold", fill: petrol)[Amtl. Kennzeichen]],
      [#text(size: 8pt, weight: "bold", fill: petrol)[Versicherer (falls bekannt)]]),
    ..beteiligte.map(b => (
      [#b.at("name", default: "")],
      [#b.at("kennzeichen", default: "—")],
      [#b.at("versicherer", default: "—")],
    )).flatten()
  )
} else {
  text(fill: gray, size: 9pt)[Keine weiteren Beteiligten.]
}
#v(7pt)
#grid(columns: (1.4fr, 1fr), column-gutter: 14pt,
  feld("Geschätzte Schadenhöhe", text(weight: "bold")[#g("schadenhoehe_geschaetzt", default: "")]),
  [#kk(false) #h(4pt) #text(size: 8.5pt)[Kostenvoranschlag liegt bei]])

#abschnitt("4", "Erklärung und Unterschrift")
#text(size: 8pt, fill: gray.darken(20%))[
  Ich versichere, die vorstehenden Angaben wahrheitsgemäß und vollständig gemacht
  zu haben. Mir ist bekannt, dass unrichtige oder unvollständige Angaben den
  Versicherungsschutz gefährden können (§§ 28, 31 VVG). Ich entbinde die
  behandelnden Stellen im erforderlichen Umfang von der Schweigepflicht.
]
#v(16pt)
#grid(columns: (1fr, 1.4fr), column-gutter: 26pt,
  [
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 7.5pt, fill: gray.darken(40%))[Ort, Datum]
  ],
  [
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 7.5pt, fill: gray.darken(40%))[Unterschrift der meldenden Person]
  ])
