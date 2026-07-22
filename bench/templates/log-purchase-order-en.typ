// Purchase Order
// @description: PO with supplier, ship-to, line items, delivery terms
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

#let accent = rgb("#0e6b52")
#let cur = g("po.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#let items = data.at("items", default: ())
#let total = items.fold(0.0, (acc, it) => acc + float(it.at("qty", default: 0)) * float(it.at("unit_price", default: 0)))

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, left: 2cm, right: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #grid(columns: (1fr, auto), column-gutter: 8pt,
      [#g("buyer.company") · #g("buyer.address") · #g("buyer.city") · #g("buyer.email")],
      [Page 1 of 1])
  ])
#set text(font: "Adwaita Sans", size: 10pt)

// Top band: buyer name left, doc title right
#block(width: 100%, inset: (bottom: 8pt), stroke: (bottom: 2.5pt + accent))[
  #grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    [
      #text(weight: "bold", size: 15pt, fill: accent)[#g("buyer.company")]
      #linebreak()
      #text(size: 8.5pt, fill: gray.darken(40%))[#g("buyer.address") · #g("buyer.city")]
    ],
    text(weight: "bold", size: 20pt, tracking: 1.5pt, fill: gray.darken(60%))[PURCHASE ORDER])
]
#v(10pt)

// Meta strip
#grid(columns: (1fr, 1fr, 1fr, 1fr), column-gutter: 8pt,
  ..(("PO NUMBER", g("po.number")),
     ("PO DATE", g("po.date")),
     ("DELIVERY DATE", g("po.delivery_date")),
     ("CURRENCY", cur)).map(((lbl, val)) => box(fill: rgb("#eef5f2"), inset: 6pt, radius: 2pt, width: 100%)[
    #text(size: 7pt, fill: accent, weight: "bold")[#lbl] \
    #text(weight: "bold")[#val]
  ]))
#v(12pt)

// Supplier / ship-to
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(size: 8pt, fill: gray.darken(40%), weight: "bold")[SUPPLIER] \
    #v(2pt)
    #text(weight: "bold")[#g("supplier.company")] \
    #g("supplier.address") \
    #g("supplier.city") \
    #if g("supplier.contact") != "" [Attn: #g("supplier.contact")]
  ],
  [
    #text(size: 8pt, fill: gray.darken(40%), weight: "bold")[SHIP TO] \
    #v(2pt)
    #g("po.ship_to", default: "—") \
    #v(4pt)
    #text(size: 8.5pt)[Buyer contact: #g("buyer.contact") · #g("buyer.email")]
  ])
#v(14pt)

// Line items — ruled table, no zebra
#if items.len() > 0 {
  table(
    columns: (auto, auto, 1fr, auto, auto, auto, auto),
    align: (center, left, left, right, center, right, right),
    inset: (x: 6pt, y: 5pt),
    stroke: (x, y) => (bottom: 0.5pt + gray.lighten(30%)),
    table.header(
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[POS]],
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[SKU]],
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[DESCRIPTION]],
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[QTY]],
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[UNIT]],
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[UNIT PRICE]],
      table.cell(stroke: (bottom: 1.2pt + accent))[#text(size: 8pt, weight: "bold")[AMOUNT]]),
    ..items.enumerate().map(((i, it)) => (
      [#(i + 1)],
      [#text(font: "Cousine", size: 8.5pt)[#it.at("sku", default: "")]],
      [#it.at("description", default: "")],
      [#it.at("qty", default: 0)],
      [#it.at("unit", default: "pcs")],
      [#money(it.at("unit_price", default: 0), sym: sym)],
      [#money(float(it.at("qty", default: 0)) * float(it.at("unit_price", default: 0)), sym: sym)],
    )).flatten()
  )
} else {
  text(fill: gray)[No line items.]
}
#v(4pt)

#align(right)[
  #box(fill: accent, inset: (x: 12pt, y: 7pt), radius: 2pt)[
    #text(fill: white, weight: "bold")[ORDER TOTAL  #h(10pt) #money(total, sym: sym)]
  ]
]
#v(14pt)

// Terms block
#grid(columns: (auto, 1fr), column-gutter: 10pt, row-gutter: 5pt,
  text(size: 8.5pt, weight: "bold")[Incoterms], text(size: 8.5pt)[#g("po.incoterms", default: "—")],
  text(size: 8.5pt, weight: "bold")[Payment], text(size: 8.5pt)[#g("po.payment_terms", default: "—")])
#if g("notes") != "" [
  #v(8pt)
  #block(fill: rgb("#f6f6f4"), inset: 8pt, radius: 2pt, width: 100%)[
    #text(size: 8.5pt)[#g("notes")]
  ]
]
#v(20pt)
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [#line(length: 100%, stroke: 0.6pt) #text(size: 8pt, fill: gray.darken(30%))[Authorized by (buyer)]],
  [#line(length: 100%, stroke: 0.6pt) #text(size: 8pt, fill: gray.darken(30%))[Order confirmation (supplier)]])
