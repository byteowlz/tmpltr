// Beitragsanpassung PKV
// @description: Mitteilung über Beitragserhöhung mit Gründen und Optionen
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

#let accent = rgb("#003366") // Deep Navy Blue for insurance look

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)

#set text(font: "Libertinus Serif", size: 11pt, lang: "de")

// Header: Logo and Insurer Info
#let insurer-name = g("versicherer.name", default: "Versicherung AG")
// Use upper() as a function
#let initials = upper(insurer-name.clusters().slice(0, calc.min(2, insurer-name.clusters().len())).join(""))

#grid(columns: (1fr, auto),
  align(left)[
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 18pt)[#initials]
    ]
    #v(4pt)
    #text(weight: "bold", size: 10pt)[#g("versicherer.name")] \
    #text(size: 9pt)[#g("versicherer.strasse") \ #g("versicherer.plz_ort")]
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(50%))[
      #g("versicherer.plz_ort") \
      #g("versicherer.strasse")
    ]
  ]
)

#v(1.5cm)

// Recipient Block
#align(left)[
  #text(size: 10pt, weight: "bold")[#g("versicherungsnehmer.name")] \
  #g("versicherungsnehmer.strasse") \
  #g("versicherungsnehmer.plz_ort") \
  #v(2pt)
  #text(size: 9pt, fill: gray.darken(40%))[Versicherungsnummer: #g("versicherungsnehmer.versicherungsnr", default: "—")]
]

#v(1cm)

// Subject Line
#block(width: 100%, inset: (top: 10pt, bottom: 10pt), stroke: (bottom: 1pt + gray.lighten(50%))){
  #text(size: 13pt, weight: "bold", fill: accent)[
    Mitteilung über die Anpassung Ihres Beitrags zum Tarif: #g("anpassung.tarif")
  ]
}

#v(0.5cm)

// Salutation
Sehr geehrte(r) #g("versicherungsnehmer.name"),

#v(0.4cm)

// Fixed: justify is a property of text via #set, not an argument to #text()
{
  set text(justify: true)
  [
    im Rahmen der gesetzlich vorgeschriebenen Überprüfung Ihrer Versicherungsleistungen haben wir eine Anpassung Ihres monatlichen Beitrags für den oben genannten Tarif festgestellt. 
    
    Diese Anpassung wird zum #g("anpassung.gueltig_ab", default: "—") wirksam.
  ]
}

#v(0.8cm)

// Summary Table
#set text(font: "Adwaita Sans", size: 10pt)
#table(
  columns: (1fr, 1fr),
  stroke: none,
  fill: (x, y) => if y == 0 { gray.lighten(90%) } else { white },
  inset: 8pt,
  table.header(
    [*Aktueller Beitrag*], [*Neuer Beitrag*],
  ),
  [#geld(g("anpassung.alter_beitrag", default: 0))],
  [#text(weight: "bold", fill: accent)[#geld(g("anpassung.neuer_beitrag", default: 0))]],
)

#v(1cm)

// Reasons
#text(font: "Libertinus Serif", size: 11pt, weight: "bold")[Gründe der Anpassung]
#v(4pt)
// Fixed: justify is a property of text via #set
{
  set text(font: "Libertinus Serif", size: 10pt, style: "italic", justify: true)
  [#g("anpassung.gruende", default: "Keine Gründe angegeben.")]
}

#v(1cm)

// Options
#text(font: "Libertinus Serif", size: 11pt, weight: "bold")[Ihre Möglichkeiten]
#v(4pt)
#let options = g("anpassung.optionen", default: ())
#if options.len() > 0 {
  list(..options.map(it => [ #it ]))
} else {
  [Es liegen keine weiteren Optionen vor.]
}

#v(1.5cm)

// Deadline/Footer Note
#block(fill: gray.lighten(95%), inset: 12pt, radius: 4pt, width: 100%)[
  #set text(font: "Adwaita Sans", size: 9pt)
  #text(weight: "bold")[Wichtiger Hinweis zur Widerspruchsfrist:]{ \
  Sollten Sie mit dieser Anpassung nicht einverstanden sein, können Sie innerhalb der Frist bis zum *#g("anpassung.widerspruchsfrist", default: "—")* schriftlich Widerspruch einlegen.
  }
]

#v(2cm)

// Signature Placeholder
#align(right)[
  #text(size: 10pt)[Mit freundlichen Grüßen] \
  #v(10pt)
  #text(weight: "bold")[#g("versicherer.name")]
]
