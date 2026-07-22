// Prüfprotokoll
// @description: Abnahmeprüfung mit Messwerten, Sollwerten, Toleranzen, Prüfmittel
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)
#let garr(path) = { let v = get(data, path, default: none); if type(v) == array { v } else { () } }

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 1.8cm, x: 1.8cm))
#set text(font: "Arimo", size: 9pt)

#table(columns: (1fr, 1fr, 1fr), stroke: 0.8pt, inset: 6pt,
  [
    #text(weight: "bold", size: 11pt)[#g("firma.name")] \
    #text(size: 8pt)[#g("firma.strasse") · #g("firma.plz_ort") \ #g("firma.bereich")]
  ],
  align(center + horizon)[#text(weight: "bold", size: 13pt, tracking: 1pt)[PRÜFPROTOKOLL]],
  [
    #text(size: 8pt)[
      *Protokoll-Nr.:* #g("protokoll.nummer") \
      *Datum:* #g("protokoll.datum") \
      *Prüfer:* #g("protokoll.pruefer")
    ]
  ])
#v(6pt)

#table(columns: (auto, 1fr, auto, 1fr), stroke: 0.5pt, inset: 5pt,
  [*Prüfling*], [#g("pruefling.bezeichnung")],
  [*Zeichnungs-Nr.*], [#g("pruefling.zeichnungsnr")],
  [*Auftrags-Nr.*], [#g("pruefling.auftragsnr")],
  [*Charge*], [#g("pruefling.charge")],
  [*Werkstoff*], [#g("pruefling.werkstoff")],
  [*Bereich*], [#g("firma.bereich")])
#v(8pt)

#text(weight: "bold", size: 9.5pt)[Verwendete Prüfmittel]
#v(2pt)
#let pm = garr("protokoll.pruefmittel")
#if pm.len() > 0 [
  #list(..pm.map(p => [#p]))
] else [—]
#v(8pt)

#text(weight: "bold", size: 9.5pt)[Messergebnisse]
#v(3pt)
#let ms = data.at("messungen", default: ())
#if ms.len() > 0 {
  table(columns: (auto, 1fr, auto, auto, auto, auto), stroke: 0.5pt, inset: 5pt,
    align: (center, left, right, center, right, center),
    fill: (_, row) => if row == 0 { rgb("#e8e8e8") } else { white },
    table.header([*Nr.*], [*Merkmal*], [*Sollwert*], [*Toleranz*], [*Istwert*], [*Bewertung*]),
    ..ms.enumerate().map(((i, m)) => {
      let bew = str(m.at("bewertung", default: ""))
      (
        [#(i + 1)],
        [#m.at("merkmal", default: "")],
        [#m.at("sollwert", default: "")],
        [#m.at("toleranz", default: "")],
        [#m.at("istwert", default: "")],
        [#text(weight: "bold",
          fill: if bew == "OK" { rgb("#1a7a1a") } else if bew == "" { black } else { rgb("#b91c1c") })[#bew]],
      )
    }).flatten())
} else [—]
#v(10pt)

#let entscheid = g("ergebnis.entscheid", default: "")
#box(stroke: 1pt, inset: 8pt, width: 100%, fill: rgb("#f5f5f5"))[
  #grid(columns: (auto, 1fr), column-gutter: 12pt,
    [#text(weight: "bold", size: 10.5pt)[Prüfentscheid: #text(
      fill: if entscheid == "Angenommen" or entscheid == "i.O." { rgb("#1a7a1a") } else { black }
    )[#entscheid]]],
    [#text(size: 8.5pt)[Bemerkung: #g("ergebnis.bemerkung", default: "—")]])
]
#v(14pt)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 20pt,
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8pt)[Datum: #g("ergebnis.unterschrift_datum")]],
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8pt)[Prüfer: #g("protokoll.pruefer")]],
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8pt)[QS-Leitung]])
