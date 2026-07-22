// Utility Bill (Electricity)
// @description: Electricity bill with meter readings, tariff breakdown, totals
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

#let green = rgb("#1e7d4f")
#let paleg = rgb("#e9f5ee")
#let cur = g("bill.currency", default: "GBP")
#let sym = if cur == "GBP" { "£" } else if cur == "EUR" { "€" } else { "$" }

#let charges = data.at("charges", default: ())

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, x: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #g("utility.name") · #g("utility.address") · VAT #g("utility.vat_id")
    #h(1fr) Customer helpline: #g("utility.hotline") · Page 1 of 1
  ])
#set text(font: "Adwaita Sans", size: 10pt)

// Header
#grid(columns: (auto, 1fr), align: (left, right), column-gutter: 12pt,
  [
    #box(fill: green, radius: 50%, inset: 9pt)[#text(fill: white, weight: "bold", size: 14pt)[BG]]
    #h(6pt)
    #box(baseline: -8pt)[#text(size: 15pt, weight: "bold", fill: green)[#g("utility.name", default: "Electricity supplier")]]
  ],
  [
    #text(size: 8.5pt, fill: gray.darken(40%))[
      #g("utility.address") \
      Helpline #g("utility.hotline")
    ]
  ])
#v(4pt)
#line(length: 100%, stroke: 2pt + green)
#v(10pt)

#grid(columns: (1fr, auto), column-gutter: 20pt,
  [
    #text(size: 8pt, fill: gray.darken(40%))[ACCOUNT HOLDER]
    #v(2pt)
    #text(weight: "bold", size: 11pt)[#g("customer.name")] \
    #g("customer.address")
    #v(6pt)
    #text(size: 9pt)[Account no. *#g("customer.account_no")* · Meter no. #g("customer.meter_no")]
  ],
  box(fill: paleg, radius: 4pt, inset: 10pt)[
    #set text(size: 9pt)
    #table(columns: 2, stroke: none, inset: 2.5pt, align: (left, right),
      [Bill number], [*#g("bill.number")*],
      [Bill date], [#g("bill.date")],
      [Billing period], [#g("bill.period")],
      [Payment due], [*#g("bill.due_date")*])
  ])
#v(14pt)

#text(size: 17pt, weight: "bold")[Your electricity bill]
#v(2pt)
#text(size: 9.5pt, fill: gray.darken(30%))[For the period #g("bill.period", default: "—")]
#v(10pt)

// Consumption box
#box(width: 100%, stroke: 1pt + green.lighten(40%), radius: 5pt, inset: 0pt, clip: true)[
  #box(width: 100%, fill: green, inset: (x: 10pt, y: 6pt))[#text(fill: white, weight: "bold", size: 9.5pt)[YOUR METER READINGS AND USAGE]]
  #grid(columns: (1fr, 1fr, 1fr, 1fr), inset: 10pt, align: center,
    [
      #text(size: 8pt, fill: gray.darken(40%))[Previous reading] \
      #text(size: 14pt, weight: "bold")[#g("consumption.previous_reading", default: "—")]
    ],
    [
      #text(size: 8pt, fill: gray.darken(40%))[Current reading] \
      #text(size: 14pt, weight: "bold")[#g("consumption.current_reading", default: "—")]
    ],
    [
      #text(size: 8pt, fill: gray.darken(40%))[Electricity used] \
      #text(size: 14pt, weight: "bold", fill: green)[#g("consumption.kwh", default: "—") kWh]
    ],
    [
      #text(size: 8pt, fill: gray.darken(40%))[Unit rate] \
      #text(size: 14pt, weight: "bold")[#money(g("consumption.tariff_per_kwh", default: 0), sym: sym)]
      #text(size: 8pt)[/kWh]
    ])
]
#v(14pt)

// Charges table
#text(weight: "bold", size: 11pt)[Charges in detail]
#v(4pt)
#if charges.len() > 0 {
  table(columns: (1fr, auto), stroke: (_, y) => (bottom: 0.5pt + gray.lighten(40%)),
    inset: (x: 8pt, y: 7pt), align: (left, right),
    ..charges.map(c => (
      [#c.at("label", default: "")],
      [#money(c.at("amount", default: 0), sym: sym)],
    )).flatten())
} else {
  text(fill: gray)[No charges listed.]
}
#v(4pt)
#align(right)[
  #table(columns: (auto, auto), stroke: none, inset: 3.5pt, align: (left, right),
    [Total before VAT], [#money(g("totals.net", default: 0), sym: sym)],
    [VAT at 5%], [#money(g("totals.tax", default: 0), sym: sym)])
]
#v(4pt)

// Total box
#align(right)[
  #box(fill: green, radius: 4pt, inset: (x: 14pt, y: 10pt))[
    #text(fill: white, size: 10pt)[Total amount due]
    #h(14pt)
    #text(fill: white, size: 17pt, weight: "bold")[#money(g("totals.total", default: 0), sym: sym)]
  ]
]
#v(14pt)

#box(fill: paleg, radius: 4pt, inset: 10pt, width: 100%)[
  #text(size: 9pt)[
    *How you pay:* #g("totals.payment_method", default: "See reverse for payment options.") \
    Struggling to pay? Call us on #g("utility.hotline") — we can spread payments or check
    if you qualify for the Warm Home Discount.
  ]
]
