// Water & Sewer Bill
// @description: Water consumption bill with meter readings and sewer charges
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

#let accent = rgb("#005a8d")
#let bg-light = rgb("#f0f7fa")
#let cur = g("bill.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm),
  header: [
    #set text(size: 8pt, fill: gray)
    #grid(columns: (1fr, 1fr),
      [#g("utility.name")],
      align(right)[#g("utility.address")]
    )
    #line(length: 100%, stroke: 0.5pt + gray)
  ]
)

#set text(font: "Tinos", size: 10pt)

// Header Section
#grid(columns: (1fr, auto),
  [
    #text(size: 22pt, weight: "bold", fill: accent)[UTILITY STATEMENT] \
    #text(size: 10pt, fill: accent.lighten(20%))[Water & Sewer Services]
  ],
  align(right)[
    #text(weight: "bold")[Account No: #g("customer.account_no")] \
    #text(size: 9pt)[Bill Date: #g("bill.date")] \
    #text(size: 9pt)[Due Date: #g("bill.due_date")]
  ]
)

#v(10pt)

// Customer Info Box
#rect(width: 100%, fill: bg-light, stroke: none, inset: 10pt)[
  #grid(columns: (1fr, 1fr),
    [
      #text(size: 8pt, weight: "bold", fill: accent)[SERVICE ADDRESS] \
      #text(size: 11pt)[#g("customer.name")] \
      #g("customer.service_address")
    ],
    align(right)[
      #text(size: 8pt, weight: "bold", fill: accent)[UTILITY CONTACT] \
      #g("utility.phone") \
      #g("utility.name")
    ]
  )
]

#v(15pt)

// Usage Summary Section
#text(size: 12pt, weight: "bold", fill: accent)[METER READING SUMMARY]
#v(5pt)
#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  stroke: (x, y) => if y == 0 { (bottom: 1pt + accent) } else { none },
  inset: 6pt,
  align: center,
  [#text(size: 8pt, fill: gray)[Previous Reading], #g("usage.previous_reading", default: "0")],
  [#text(size: 8pt, fill: gray)[Current Reading], #g("usage.current_reading", default: "0")],
  [#text(size: 8pt, fill: gray)[Usage], #g("usage.gallons_or_m3", default: "0")],
  [#text(size: 8pt, fill: gray)[Unit], #g("usage.unit", default: "units")]
)

#v(15pt)

// Charges Section
#text(size: 12pt, weight: "bold", fill: accent)[CURRENT CHARGES]
#v(5pt)

#let charges = data.at("charges", default: ())
#if charges.len() > 0 {
  table(
    columns: (1fr, auto),
    stroke: none,
    inset: 5pt,
    fill: (x, y) => if y == 0 { bg-light } else { white },
    table.header(
      [#text(weight: "bold")[Description]],
      [#text(weight: "bold")[Amount]]
    ),
    ..charges.map(c => (
      [#c.at("label", default: "")],
      [#money(c.at("amount", default: 0), sym: sym)]
    )).flatten()
  )
}

#v(10pt)

// Total Section
#align(right)[
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 4pt,
    [#text(size: 11pt)[Total Amount Due (#sym):]],
    [#text(size: 16pt, weight: "bold", fill: accent)[#money(g("total", default: 0), sym: sym)]]
  )
]

#v(20pt)

// Footer / Important Info
#line(length: 100%, stroke: 0.5pt + gray)
#grid(columns: (1fr, 1fr),
  [
    #text(size: 8pt, weight: "bold")[BILLING PERIOD] \
    #text(size: 8pt)[#g("bill.period")]
  ],
  align(right)[
    #text(size: 8pt, weight: "bold")[PAYMENT INFORMATION] \
    #text(size: 8pt)[Please include account #g("customer.account_no") with your payment.]
  ]
)

#v(10pt)
#set text(size: 7.5pt, fill: gray.darken(50%))
#align(center)[
  Thank you for being a valued customer. \
  A late fee may be applied to accounts not paid by the due date.
]
