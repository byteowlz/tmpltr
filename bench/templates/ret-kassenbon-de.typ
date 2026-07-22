// Kassenbon
// @description: Deutscher Kassenbon mit MwSt-Sätzen A/B und TSE-Signatur
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
// 1.234,56 (ohne Euro-Zeichen, Bon-Stil)
#let eur(x) = money(x, sym: "").replace(",", "X").replace(".", ",").replace("X", ".")

// Lange Zeichenkette (TSE-Signatur) in Blöcke umbrechen
#let wrap-chunks(s, n) = {
  let cs = str(s).clusters()
  let out = ()
  let i = 0
  while i < cs.len() {
    out.push(cs.slice(i, calc.min(i + n, cs.len())).join(""))
    i = i + n
  }
  out.join(linebreak())
}

#let artikel = data.at("artikel", default: ())

#set page(width: 80mm, height: auto, margin: (x: 5mm, top: 6mm, bottom: 9mm))
#set text(font: "Cousine", size: 8pt)
#set par(leading: 0.45em)

#let strich = block(above: 4pt, below: 4pt, width: 100%, height: 1em, clip: true)[#("- " * 60)]
#let doppel = block(above: 4pt, below: 4pt, width: 100%, height: 1em, clip: true)[#("=" * 80)]

// Kopf: Marktname invers
#align(center)[
  #box(fill: black, inset: (x: 8pt, y: 4pt))[
    #text(fill: white, size: 12pt, weight: "bold")[#upper(str(g("markt.name", default: "MARKT")))]
  ]
  #v(2pt)
  #text(size: 7.5pt)[
    #g("markt.strasse") \
    #g("markt.plz_ort") \
    USt-IdNr.: #g("markt.ustid") #h(4pt) Filiale #g("markt.filiale")
  ]
]

#doppel

#grid(columns: (1fr, auto), column-gutter: 3pt,
  [#g("bon.datum") #h(3pt) #g("bon.uhrzeit") Uhr],
  align(right)[Kasse #g("bon.kasse")])
#grid(columns: (1fr, auto), column-gutter: 3pt,
  [Bon-Nr. #g("bon.nummer")],
  align(right)[Bed. #g("bon.bediener")])

#strich
#grid(columns: (1fr, auto), column-gutter: 3pt,
  [#text(size: 7pt)[ARTIKEL]], align(right)[#text(size: 7pt)[EUR]])

#if artikel.len() > 0 {
  for it in artikel {
    let menge = float(it.at("menge", default: 1))
    let preis = float(it.at("preis", default: 0))
    let kl = str(it.at("mwst_klasse", default: ""))
    grid(columns: (1fr, auto), column-gutter: 3pt,
      [#it.at("name", default: "")],
      align(right)[#eur(menge * preis) #kl])
    if menge > 1 {
      text(size: 7pt)[#h(8pt)#str(int(menge)) x #eur(preis)]
      linebreak()
    }
  }
} else [
  #text(size: 7.5pt)[\*\* KEINE POSITIONEN \*\*]
]

#doppel

#grid(columns: (1fr, auto), column-gutter: 3pt,
  [#text(size: 11pt, weight: "bold")[SUMME]],
  align(right)[#text(size: 11pt, weight: "bold")[#eur(g("summen.gesamt", default: 0)) EUR]])
#v(2pt)
#grid(columns: (1fr, auto), row-gutter: 3pt, column-gutter: 3pt,
  [#g("summen.zahlart", default: "BAR")], align(right)[#eur(g("summen.gegeben", default: 0))],
  [RÜCKGELD], align(right)[#eur(g("summen.rueckgeld", default: 0))])

#strich

// MwSt-Aufstellung
#let na = float(g("summen.netto_a", default: 0))
#let ma = float(g("summen.mwst_a", default: 0))
#let nb = float(g("summen.netto_b", default: 0))
#let mb = float(g("summen.mwst_b", default: 0))
#text(size: 7pt)[
  #grid(columns: (auto, 1fr, 1fr, 1fr), column-gutter: 4pt, row-gutter: 2.5pt,
    [MwSt], align(right)[Netto], align(right)[MwSt], align(right)[Brutto],
    [A = 19,0%], align(right)[#eur(na)], align(right)[#eur(ma)], align(right)[#eur(na + ma)],
    [B =  7,0%], align(right)[#eur(nb)], align(right)[#eur(mb)], align(right)[#eur(nb + mb)],
    [Gesamt], align(right)[#eur(na + nb)], align(right)[#eur(ma + mb)], align(right)[#eur(na + ma + nb + mb)])
]

#strich

// TSE-Block
#text(size: 6.5pt)[
  TSE-Transaktion: #g("tse.transaktionsnr") \
  TSE-Seriennummer: \
  #g("tse.seriennr") \
  TSE-Signatur: \
  #wrap-chunks(g("tse.signatur", default: ""), 32)
]

#strich

#align(center)[
  #text(size: 9pt, weight: "bold")[Vielen Dank für Ihren Einkauf!] \
  #text(size: 7pt)[Es bediente Sie Team #g("markt.filiale"). \ Bitte Bon für Umtausch aufbewahren.]
]
