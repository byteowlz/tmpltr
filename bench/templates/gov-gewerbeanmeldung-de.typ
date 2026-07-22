// Gewerbeanmeldung (GewA1-style Form)
// @description: GewA1-artiges Formular: Betrieb, Tätigkeit, Betriebsstätte
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let geld(x) = {
  let v = calc.round(float(x), digits: 2)
  let neg = v < 0
  let a = calc.abs(v)
  let i = int(a)
  let c = int(calc.round((a - i) * 100))
  if c == 100 { i = i + 1; c = 0 }
  let s = str(i)
  let out = ""
  let n = s.clusters().len()
  for (k, ch) in s.clusters().enumerate() {
    out = out + ch
    let rem = n - k - 1
    if rem > 0 and calc.rem(rem, 3) == 0 { out = out + "," }
  }
  let res = out + "." + (if c < 10 { "0" } else { "" }) + str(c)
  res.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm),
)
#set text(font: "Libertinus Serif", size: 10pt)

// Header: Authority Info
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(size: 14pt, weight: "bold")[#g("behoerde.name")] \
    #text(size: 10pt)[#g("behoerde.strasse")] \
    #g("behoerde.plz_ort")
  ],
  [
    #text(size: 16pt, weight: "bold")[Gewerbeanmeldung] \
    #text(size: 10pt, fill: gray.darken(50%))[Formular GewA1]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt)
#v(10pt)

// Section 1: Art der Anmeldung
#block(width: 100%, stroke: 0.5pt + black, inset: 8pt)[
  #text(weight: "bold")[Art der Anmeldung:] #g("anmeldung.art") \
  #text(size: 9pt, fill: gray.darken(50%))[Datum der Anmeldung: #g("anmeldung.datum")]
]

#v(12pt)

// Section 2: Angaben über den Anmelder
#text(weight: "bold", size: 12pt)[1. Angaben über den Anmelder]
#v(5pt)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 15pt,
  row-gutter: 8pt,
  [
    #text(size: 8pt, fill: gray.darken(50%))[Name, Vorname:] \
    #g("anmelder.name")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Geburtsdatum:] \
    #g("anmelder.geburtsdatum")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Geburtsort:] \
    #g("anmelder.geburtsort")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Staatsangehörigkeit:] \
    #g("anmelder.staatsangehoerigkeit")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Anschrift:] \
    #g("anmelder.strasse") \
    #g("anmelder.plz_ort")
  ],
  []
)

#v(12pt)

// Section 3: Angaben über den Betrieb
#text(weight: "bold", size: 12pt)[2. Angaben über den Betrieb]
#v(5pt)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 15pt,
  row-gutter: 8pt,
  [
    #text(size: 8pt, fill: gray.darken(50%))[Name des Betriebs:] \
    #g("betrieb.name")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Rechtsform:] \
    #g("betrieb.rechtsform")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Betriebsstätte (Anschrift):] \
    #g("betrieb.strasse") \
    #g("betrieb.plz_ort")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Beginn der Tätigkeit:] \
    #g("betrieb.beginn")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Gegenstand des Gewerbes / Tätigkeit:] \
    #g("betrieb.taetigkeit")
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[Anzahl der Mitarbeiter:] \
    #g("betrieb.mitarbeiter_anzahl", default: "0")
  ]
)

#v(12pt)

// Section 4: Zusatzinformationen (Dynamic List)
#text(weight: "bold", size: 12pt)[3. Zusätzliche Informationen]
#v(5pt)

#let zusatz = data.at("zusatzinformationen", default: ())
#if zusatz.len() > 0 {
  table(
    columns: (1fr, 2fr),
    stroke: (x, y) => if y == 0 { (bottom: 0.5pt + black) } else { (bottom: 0.25pt + gray.lighten(50%)) },
    inset: 6pt,
    fill: (x, y) => if y == 0 { gray.lighten(90%) } else { white },
    [*Feld*], [*Wert*],
    ..zusatz.map(it => (
      it.at("feld", default: ""),
      it.at("wert", default: "")
    )).flatten()
  )
} else {
  text(style: "italic", fill: gray)[Keine zusätzlichen Informationen angegeben.]
}

#v(20pt)

// Footer: Fees and Signature Area
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 9pt)[
      *Gebühren:* #geld(g("anmeldung.gebuehr", default: 0)) \
      #text(size: 8pt, fill: gray.darken(50%))[Die Gebühr ist bei Antragstellung fällig.]
    ]
  ],
  align(right)[
    #v(10pt)
    #box(width: 150pt, stroke: (bottom: 0.5pt + black))[
      #v(20pt)
    ]
    #text(size: 8pt)[Ort, Datum und Unterschrift]
  ]
)

#v(1fr)
#set text(size: 7pt, fill: gray.darken(50%))
#align(center)[
  Dokument generiert für amtliche Zwecke. Kopie der Gewerbeanmeldung gemäß § 14 GewO.
]
