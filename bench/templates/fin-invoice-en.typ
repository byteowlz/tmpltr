// Commercial Invoice
// @description: B2B invoice with line items, VAT, payment terms
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

#let accent = rgb("#1a4f8b")
#let cur = g("invoice.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#let items = data.at("items", default: ())
#let subtotal = items.fold(0.0, (acc, it) => acc + float(it.at("qty", default: 0)) * float(it.at("price", default: 0)))
#let tax-rate = float(g("invoice.tax_rate", default: 0))
#let tax = subtotal * tax-rate / 100
#let total = subtotal + tax

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.4cm, left: 2.2cm, right: 1.8cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr, 1fr), column-gutter: 8pt,
      [#g("seller.name") · #g("seller.address"), #g("seller.postal") #g("seller.city")],
      align(center)[VAT #g("seller.vat_id") · #g("seller.email")],
      align(right)[#g("seller.bank") · IBAN #g("seller.iban") · BIC #g("seller.bic")])
  ])
#set text(font: "Arimo", size: 10pt)

// Header: logo box left, seller block right
#let seller-name = g("seller.name", default: "··")
#let initials = upper(seller-name.clusters().slice(0, calc.min(2, seller-name.clusters().len())).join(""))
#grid(columns: (1fr, auto),
  box(fill: accent, inset: 10pt, radius: 3pt)[
    #text(fill: white, weight: "bold", size: 16pt)[#initials]
  ],
  align(right)[
    #text(weight: "bold", size: 11pt)[#g("seller.name")] \
    #text(size: 9pt)[#g("seller.address") \ #g("seller.postal") #g("seller.city"), #g("seller.country") \ #g("seller.phone") · #g("seller.email")]
  ])
#v(12pt)

// Address + meta
#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(size: 8pt, fill: gray.darken(40%))[BILL TO] \
    #v(2pt)
    #text(weight: "bold")[#g("buyer.name")] \
    #g("buyer.address") \
    #g("buyer.postal") #g("buyer.city"), #g("buyer.country") \
    #if g("buyer.vat_id") != "" [VAT: #g("buyer.vat_id")]
  ],
  align(right)[
    #text(size: 24pt, weight: "bold", fill: accent)[INVOICE] \
    #v(6pt)
    #table(columns: 2, stroke: none, align: (left, right), inset: 2.5pt,
      [Invoice no.], [*#g("invoice.number")*],
      [Invoice date], [#g("invoice.date")],
      [Due date], [#g("invoice.due_date")],
      [PO reference], [#g("invoice.po_number", default: "—")])
  ])
#v(14pt)

// Items
#if items.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto, auto),
    align: (center, left, right, center, right, right),
    stroke: none,
    inset: 6pt,
    fill: (_, row) => if row == 0 { accent } else if calc.odd(row) { rgb("#f2f6fb") } else { white },
    table.header(
      [#text(fill: white, weight: "bold")[\#]],
      [#text(fill: white, weight: "bold")[Description]],
      [#text(fill: white, weight: "bold")[Qty]],
      [#text(fill: white, weight: "bold")[Unit]],
      [#text(fill: white, weight: "bold")[Unit price]],
      [#text(fill: white, weight: "bold")[Amount]]),
    ..items.enumerate().map(((i, it)) => (
      [#(i + 1)],
      [#it.at("description", default: "")],
      [#it.at("qty", default: 0)],
      [#it.at("unit", default: "pcs")],
      [#money(it.at("price", default: 0), sym: sym)],
      [#money(float(it.at("qty", default: 0)) * float(it.at("price", default: 0)), sym: sym)],
    )).flatten()
  )
} else {
  text(fill: gray)[No line items.]
}
#v(6pt)

// Totals
#align(right)[
  #table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3.5pt,
    [Subtotal], [#money(subtotal, sym: sym)],
    [VAT (#{tax-rate}%)], [#money(tax, sym: sym)],
    table.hline(stroke: 1pt + accent),
    [#text(weight: "bold", size: 11pt)[Total due]], [#text(weight: "bold", size: 11pt, fill: accent)[#money(total, sym: sym)]])
]
#v(14pt)

// Terms
#text(size: 9pt)[
  Payment within the terms stated above to #g("seller.bank"), IBAN
  *#g("seller.iban")*, BIC #g("seller.bic"), referencing invoice
  *#g("invoice.number")*.
]
#if g("notes") != "" [
  #v(6pt)
  #text(size: 9pt, style: "italic")[#g("notes")]
]
