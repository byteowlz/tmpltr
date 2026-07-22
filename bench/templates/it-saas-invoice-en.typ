// SaaS Invoice
// @description: Subscription invoice with usage-based items and VAT reverse charge
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)
#let garr(path) = { let v = get(data, path, default: none); if type(v) == array { v } else { () } }

#let money(x, sym: "€") = {
  let v = calc.round(float(x), digits: 2)
  let i = int(calc.abs(v))
  let c = int(calc.round((calc.abs(v) - i) * 100))
  let s = str(i)
  let out = ""
  let n = s.clusters().len()
  for (k, ch) in s.clusters().enumerate() {
    out = out + ch
    let rem = n - k - 1
    if rem > 0 and calc.rem(rem, 3) == 0 { out = out + "," }
  }
  sym + (if v < 0 { "-" } else { "" }) + out + "." + (if c < 10 { "0" } else { "" }) + str(c)
}

#let accent = rgb("#6d28d9")
#let cur = g("invoice.currency", default: "EUR")
#let sym = if cur == "USD" { "$" } else if cur == "GBP" { "£" } else { "€" }
#let items = data.at("items", default: ())
#let subtotal = items.fold(0.0, (a, it) => a + float(it.at("amount", default: 0)))
#let rc = get(data, "invoice.reverse_charge", default: none) == true
#let tax = if rc { 0.0 } else { subtotal * 0.19 }

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.2cm, x: 2cm),
  footer: [#set text(size: 7.5pt, fill: gray)
    #g("vendor.company") · #g("vendor.address") · VAT #g("vendor.vat_id") #h(1fr)
    IBAN #g("vendor.iban") · BIC #g("vendor.bic")])
#set text(font: "Adwaita Sans", size: 10pt)

#grid(columns: (auto, 1fr),
  box(fill: accent, inset: (x: 12pt, y: 8pt), radius: 6pt)[
    #text(fill: white, weight: "bold", size: 15pt)[#g("vendor.company", default: "·")]
  ],
  align(right)[
    #text(size: 22pt, weight: "bold", fill: accent)[Invoice] \
    #text(size: 9pt, fill: gray.darken(30%))[#g("invoice.number")]
  ])
#v(12pt)

#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(size: 8pt, fill: gray.darken(40%))[BILLED TO] \
    #v(2pt)
    #text(weight: "bold")[#g("customer.company")] \
    #g("customer.address") \
    #g("customer.country") \
    VAT: #g("customer.vat_id")
  ],
  align(right)[
    #table(columns: 2, stroke: none, align: (left, right), inset: 2.5pt,
      [Invoice date], [*#g("invoice.date")*],
      [Due date], [#g("invoice.due_date")],
      [Billing period], [#g("invoice.period")])
  ])
#v(12pt)

#if items.len() > 0 {
  table(columns: (1fr, auto, auto, auto), stroke: none, inset: 7pt,
    fill: (_, row) => if row == 0 { accent } else if calc.odd(row) { rgb("#f5f3ff") } else { white },
    table.header(
      [#text(fill: white, weight: "bold")[Plan / Item]],
      [#text(fill: white, weight: "bold")[Usage]],
      [#text(fill: white, weight: "bold")[Unit price]],
      [#text(fill: white, weight: "bold")[Amount]]),
    ..items.map(it => (
      [#it.at("plan", default: "")],
      [#it.at("usage_qty", default: "") #it.at("usage_unit", default: "")],
      align(right)[#money(it.at("unit_price", default: 0), sym: sym)],
      align(right)[#money(it.at("amount", default: 0), sym: sym)],
    )).flatten())
} else [
  #text(fill: gray)[No line items.]
]
#v(6pt)

#align(right)[
  #table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3.5pt,
    [Subtotal], [#money(subtotal, sym: sym)],
    [VAT #if rc [(reverse charge)] else [(19%)]], [#money(tax, sym: sym)],
    table.hline(stroke: 1pt + accent),
    [#text(weight: "bold", size: 11.5pt)[Total due]],
    [#text(weight: "bold", size: 11.5pt, fill: accent)[#money(subtotal + tax, sym: sym)]])
]
#v(10pt)

#if rc [
  #box(fill: rgb("#f5f3ff"), inset: 8pt, radius: 4pt, width: 100%)[
    #text(size: 8.5pt)[VAT reverse charge: pursuant to Art. 196 of Council Directive
    2006/112/EC, VAT is to be accounted for by the recipient.]
  ]
]
#v(6pt)
#text(size: 9pt)[Please pay by *#g("invoice.due_date")* referencing
*#g("invoice.number")* to IBAN #g("vendor.iban").]
