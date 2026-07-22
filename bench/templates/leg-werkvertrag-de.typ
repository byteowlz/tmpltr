// Werkvertrag
// @description: Werkvertrag: Leistung, Verguetung, Abnahme, Gewaehrleistung
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

#set page(paper: "a4", margin: (top: 2.4cm, bottom: 2.6cm, left: 2.5cm, right: 2.2cm),
  footer: [
    #set text(size: 8pt, fill: gray.darken(25%))
    #align(center)[Werkvertrag · Seite 1 von 1]
  ])
#set text(font: "Tinos", size: 10.5pt, lang: "de")
#set par(justify: true, leading: 0.7em)

#align(center)[
  #text(size: 16pt, weight: "bold", tracking: 2pt)[WERKVERTRAG]
  #v(2pt)
  #text(size: 9.5pt, fill: gray.darken(50%))[gemäß §§ 631 ff. BGB]
]
#v(12pt)

zwischen

#pad(left: 1.2cm)[
  *#g("auftraggeber.firma", default: "—")* \
  #g("auftraggeber.strasse", default: "—"), #g("auftraggeber.plz_ort", default: "—") \
  vertreten durch #g("auftraggeber.vertreten_durch", default: "—") \
  #text(size: 9.5pt)[– nachfolgend „*Auftraggeber*" –]
]
#v(4pt)
und
#v(4pt)
#pad(left: 1.2cm)[
  *#g("auftragnehmer.firma", default: "—")* \
  #g("auftragnehmer.strasse", default: "—"), #g("auftragnehmer.plz_ort", default: "—") \
  vertreten durch #g("auftragnehmer.vertreten_durch", default: "—") \
  #text(size: 9.5pt)[– nachfolgend „*Auftragnehmer*" –]
]

#let par-sec(n, title, body) = {
  v(10pt)
  align(center)[#text(weight: "bold")[§ #n #h(6pt) #title]]
  v(4pt)
  body
}

#par-sec(1, "Vertragsgegenstand")[
  Der Auftragnehmer verpflichtet sich zur Herstellung des folgenden Werkes:
  #v(3pt)
  #block(inset: (left: 0.8cm, right: 0.3cm), stroke: (left: 1.5pt + gray.darken(30%)))[
    #pad(left: 6pt)[#g("vertrag.leistungsbeschreibung", default: "Leistung gemäß gesonderter Leistungsbeschreibung.")]
  ]
]

#par-sec(2, "Vergütung")[
  Die Vergütung für das Werk beträgt pauschal
  *#geld(g("vertrag.verguetung", default: 0))* zuzüglich der gesetzlichen Umsatzsteuer.
  Zahlungsplan: #g("vertrag.zahlungsplan", default: "Zahlung nach Abnahme, 14 Tage netto.")
]

#par-sec(3, "Fertigstellung")[
  Der Auftragnehmer stellt das Werk bis zum *#g("vertrag.fertigstellung", default: "—")*
  fertig. Verzögerungen, die der Auftragnehmer nicht zu vertreten hat, verlängern die
  Frist angemessen; sie sind dem Auftraggeber unverzüglich schriftlich anzuzeigen.
]

#par-sec(4, "Abnahme")[
  #g("vertrag.abnahme", default: "Die Abnahme erfolgt förmlich nach Fertigstellungsanzeige des Auftragnehmers.")
  Wegen unwesentlicher Mängel darf die Abnahme nicht verweigert werden; diese sind im
  Abnahmeprotokoll festzuhalten und unverzüglich zu beseitigen.
]

#par-sec(5, "Gewährleistung")[
  Die Verjährungsfrist für Mängelansprüche beträgt
  *#g("vertrag.gewaehrleistung_monate", default: "—") Monate* ab Abnahme.
  Im Übrigen gelten die gesetzlichen Vorschriften der §§ 634 ff. BGB.
]

#par-sec(6, "Schlussbestimmungen")[
  Änderungen und Ergänzungen dieses Vertrages bedürfen der Schriftform; dies gilt auch
  für die Aufhebung dieses Schriftformerfordernisses. Sollte eine Bestimmung dieses
  Vertrages unwirksam sein oder werden, bleibt die Wirksamkeit der übrigen Bestimmungen
  unberührt. Gerichtsstand ist, soweit gesetzlich zulässig, der Sitz des Auftraggebers.
]

#v(30pt)
#grid(columns: (1fr, 1fr), column-gutter: 40pt, row-gutter: 4pt,
  [
    #g("unterschrift.ort", default: ""), den #g("unterschrift.datum", default: "")
    #v(22pt)
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[Ort, Datum — Unterschrift *Auftraggeber* \ #g("auftraggeber.firma", default: "")]
  ],
  [
    #g("unterschrift.ort", default: ""), den #g("unterschrift.datum", default: "")
    #v(22pt)
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[Ort, Datum — Unterschrift *Auftragnehmer* \ #g("auftragnehmer.firma", default: "")]
  ])
