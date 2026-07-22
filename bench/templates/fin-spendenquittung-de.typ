// Spendenbescheinigung
// @description: Zuwendungsbestätigung eines gemeinnützigen Vereins
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, sym: "$") = {
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
  sym + (if neg { "-" } else { "" }) + out + "." + (if c < 10 { "0" } else { "" }) + str(c)
}

#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

#let accent = rgb("#2d5a27") // Deep forest green for non-profit look
#let border-color = rgb("#e0e0e0")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)

#set text(font: "Libertinus Serif", size: 11pt, lang: "de")

// Decorative Border
#rect(
  width: 100%,
  height: 100%,
  stroke: 1pt + border-color,
  inset: 0pt,
  radius: 2pt
)[
  #set text(font: "Libertinus Serif")
  
  // Header: Logo and Title
  #grid(columns: (1fr, auto),
    align(left)[
      #let vname = g("verein.name", default: "Verein")
      #let initials = upper(vname.clusters().slice(0, calc.min(2, vname.clusters().len())).join(""))
      #box(fill: accent, inset: 8pt, radius: 2pt)[
        #text(fill: white, weight: "bold", size: 18pt)[#initials]
      ]
    ],
    align(right)[
      #text(size: 10pt, weight: "bold", fill: accent)[Zuwendungsbestätigung] \
      #text(size: 9pt, style: "italic")[gemäß § 52 Abs. 2 AO]
    ]
  )

  #v(10pt)
  #line(length: 100%, stroke: 0.5pt + accent)
  #v(10pt)

  // Organization Details
  #grid(columns: (1fr, 1fr),
    [
      #text(weight: "bold", size: 10pt)[Absender / Verein:]{ \ }
      #g("verein.name") \
      #g("verein.strasse") \
      #g("verein.plz_ort") \
      Steuernr.: #g("verein.steuernr") \
      Finanzamt: #g("verein.finanzamt") \
      (Freistellungsbescheid vom: #g("verein.freistellungsbescheid_datum"))
    ],
    align(right)[
      #text(weight: "bold", size: 10pt)[Empfänger (Spender):]{ \ }
      #g("spender.name") \
      #g("spender.strasse") \
      #g("spender.plz_ort")
    ]
  )

  #v(20pt)

  // Main Content
  #set align(center)
  #text(size: 16pt, weight: "bold", fill: accent)[Bescheinigung über eine Spende]
  #v(10pt)

  #set align(left)
  #text(size: 12pt)[
    Der oben genannte Verein bestätigt hiermit den Erhalt einer Zuwendung in folgender Form:
  ]

  #v(10pt)

  #rect(width: 100%, stroke: 0.5pt + border-color, inset: 15pt, radius: 4pt)[
    #set align(left)
    #grid(columns: (1fr, 1fr), row-gutter: 12pt, column-gutter: 20pt,
      [
        *Art der Zuwendung:* \
        #g("spende.art", default: "Geldzuwendung")
      ],
      [
        *Spendenbetrag:* \
        #text(size: 13pt, weight: "bold")[#geld(g("spende.betrag", default: 0))]
      ],
      [
        *In Worten:* \
        #text(style: "italic")[#g("spende.betrag_in_worten", default: "")]
      ],
      [
        *Spendenzeitpunkt:* \
        #g("spende.datum", default: "")
      ]
    )
  ]

  #v(10pt)
  #if g("spende.verzicht_auf_erstattung", default: "false") == "true" [
    #text(size: 9pt, fill: gray.darken(50%))[Hinweis: Es wurde kein Verzicht auf die Erstattung der Spende erklärt.]
  ]

  #v(30pt)

  // Footer/Signature Area
  #grid(columns: (1fr, 1fr),
    align(left)[
      #text(size: 10pt)[
        #g("ausstellung.ort", default: ""), #g("ausstellung.datum", default: "")
      ]
    ],
    align(right)[
      #v(20pt)
      #line(length: 150pt, stroke: 0.5pt + black)
      #text(size: 10pt)[Unterschrift des Vorstands / Zeichnungsberechtigten]
    ]
  )

  #v(40pt)
  #line(length: 100%, stroke: 0.2pt + gray)
  #set align(center)
  #text(size: 8pt, fill: gray.darken(50%))[
    Diese Bescheinigung dient zur Vorlage beim Finanzamt zur steuerlichen Berücksichtigung als Sonderausgabe.
  ]
]
