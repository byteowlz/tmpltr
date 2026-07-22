// Abmahnung mit Unterlassungserklärung
// @description: Wettbewerbsrechtliche Abmahnung mit Frist und Vertragsstrafe
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Money helper for German formatting
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
  (if neg { "-" } else { "" }) + out + "." + (if c < 10 { "0" } else { "" }) + str(c) + " €"
}

// Layout Settings
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)
#set text(font: "Tinos", size: 11pt, lang: "de")
#set par(justify: true, leading: 0.65em)

// Header: Law Firm Info
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(weight: "bold", size: 13pt)[#g("kanzlei.name")] \
    #text(size: 10pt)[
      #g("kanzlei.strasse") \
      #g("kanzlei.plz_ort") \
      Tel: #g("kanzlei.telefon")
    ]
  ],
  [
    #text(size: 9pt, fill: gray.darken(50%))[Aktenzeichen: \ #g("kanzlei.az")]
  ]
)

#v(1cm)

// Recipient Block
#block(width: 100%, inset: 0pt)[
  #text(size: 10pt)[
    #g("gegner.firma") \
    #g("gegner.strasse") \
    #g("gegner.plz_ort")
  ]
]

#v(0.5cm)

// Date and Subject
#align(right)[
  #text(size: 10pt)[#datetime.today().display("[day].[month].[year]")]
]

#v(0.8cm)

#text(weight: "bold", size: 12pt)[
  ABMAHNUNG WEGEN WETTBEWERBSRECHTLICHER VERSTÖSSE
]
#v(0.2cm)
#line(length: 100%, stroke: 0.5pt)
#v(0.4cm)

// Content
#text(weight: "bold")[Sehr geehrte Damen und Herren,]{}

#v(0.4cm)

#text(weight: "bold")[I. Sachverhalt]{} \
#v(0.2cm)
#g("abmahnung.verstoss")

#v(0.4cm)

#text(weight: "bold")[II. Rechtslage]{} \
#v(0.2cm)
#g("abmahnung.rechtsgrundlage")

#v(0.4cm)

#text(weight: "bold")[III. Aufforderung]{} \
#v(0.2cm)
#text(weight: "bold")[
  Namens und im Auftrag unserer Mandantin, der #g("mandant.firma"), fordern wir Sie hiermit auf, die oben beschriebenen rechtswidrigen geschäftlichen Handlungen unverzüglich einzustellen.
]

#v(0.4cm)

#text(weight: "bold")[IV. Fristsetzung]{} \
#v(0.2cm)
Wir erwarten die Abgabe einer rechtsverbindlichen, modifizierten Unterlassungserklärung bis spätestens zum: \
#text(weight: "bold", size: 11pt)[#g("abmahnung.frist")]

#v(0.4cm)

#text(weight: "bold")[V. Rechtsfolgen]{} \
#v(0.2cm)
Sollte diese Frist fruchtlos verstreichen, sind wir angewiesen, gerichtliche Hilfe in Anspruch zu nehmen. Im Falle einer Zuwiderhandlung gegen die Unterlassungsverpflichtung wird eine #text(weight: "bold")[Vertragsstrafe in Höhe von #g("abmahnung.vertragsstrafe")] fällig.

Der Streitwert wird vorläufig auf #g("abmahnung.streitwert") festgesetzt.

#v(0.4cm)

#text(weight: "bold")[VI. Kosten]{} \
#v(0.2cm)
Die Kosten dieser Abmahnung belaufen sich auf: \
#g("abmahnung.gebuehren")

#v(1cm)

#text(weight: "bold")[Mit freundlichen Grüßen]{} \
#v(0.4cm)

#text(weight: "bold")[Rechtsanwälte Dr. Severin & Kollegen PartG mbB]

#v(1cm)

// Footer
#set page(footer: [
  #set text(size: 8pt, fill: gray)
  #line(length: 100%, stroke: 0.2pt + gray)
  #v(2pt)
  #align(center)[#g("kanzlei.name") · #g("kanzlei.strasse") · #g("kanzlei.plz_ort")]
])
