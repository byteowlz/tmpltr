// Freight Invoice
// @description: Carrier invoice with route legs, surcharges, fuel
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

#let accent = rgb("#2d3436")
#let secondary = rgb("#636e72")
#let highlight = rgb("#0984e3")
#let cur = g("invoice.currency", default: "EUR")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 1.5cm, bottom: 2cm, left: 1.5cm, right: 1.5cm),
  footer: [
    #set text(size: 8pt, fill: secondary)
    #line(length: 100%, stroke: 0.5pt + gray)
    #grid(columns: (1fr, 1fr),
      [#g("carrier.company") · #g("carrier.email")],
      align(right)[#g("carrier.iban") · #g("carrier.bic")]
    )
  ]
)

#set text(font: "Tinos", size: 10pt)

// Header
#grid(columns: (1fr, auto),
  [
    #text(size: 28pt, weight: "bold", tracking: -1pt)[FREIGHT\ INVOICE] \
    #text(size: 10pt, fill: highlight, weight: "bold")[LOGISTICS & TRANSPORT SERVICES]
  ],
  align(right)[
    #text(size: 12pt, weight: "bold")[#g("invoice.number")] \
    #text(size: 10pt, fill: secondary)[Date: #g("invoice.date")] \
    #text(size: 10pt, fill: secondary)[Due: #g("invoice.due_date")]
  ]
)

#v(1cm)

// Parties
#grid(columns: (1fr, 1fr), column-gutter: 1cm,
  [
    #text(size: 8pt, weight: "bold", fill: secondary)[CARRIER (FROM)]
    #v(2pt)
    #text(weight: "bold", size: 11pt)[#g("carrier.company")] \
    #g("carrier.address") \
    #text(size: 9pt, fill: secondary)[VAT: #g("carrier.vat_id")] \
    #text(size: 9pt, fill: secondary)[Ph: #g("carrier.phone")]
  ],
  [
    #text(size: 8pt, weight: "bold", fill: secondary)[CUSTOMER (BILL TO)]
    #v(2pt)
    #text(weight: "bold", size: 11pt)[#g("customer.company")] \
    #g("customer.address") \
    #text(size: 9pt, fill: secondary)[VAT: #g("customer.vat_id")]
  ]
)

#v(0.8cm)

// Shipment References
#if g("invoice.shipment_refs") != "" [
  #box(fill: gray.lighten(90%), inset: 8pt, radius: 2pt, width: 100%)[
    #set text(size: 9pt)
    #text(weight: "bold", fill: secondary)[SHIPMENT REFERENCES:] \
    #g("invoice.shipment_refs").join(" | ")
  ]
]

#v(0.5cm)

// Main Charges Table
#text(weight: "bold", size: 11pt)[Transport Legs & Services]
#v(4pt)
#let charges = data.at("charges", default: ())
#table(
  columns: (1fr, 2fr, auto, auto),
  stroke: none,
  inset: 6pt,
  fill: (x, y) => if y == 0 { accent } else { white },
  table.header(
    [#text(fill: white, size: 9pt)[Description]],
    [#text(fill: white, size: 9pt)[Route / Details]],
    [#text(fill: white, size: 9pt)[Weight]],
    [#text(fill: white, size: 9pt)[Amount]],
  ),
  ..charges.map(it => (
    [#it.at("description", default: "")],
    [#it.at("route", default: "")],
    [#if it.at("weight_kg", default: 0) > 0 [#it.at("weight_kg", default: 0) kg] else []],
    [#money(it.at("amount", default: 0), sym: sym)],
  )).flatten()
)

#v(0.5cm)

// Surcharges
#text(weight: "bold", size: 11pt)[Surcharges & Additional Fees]
#v(4pt)
#let surcharges = data.at("surcharges", default: ())
#if surcharges.len() > 0 {
  table(
    columns: (1fr, auto),
    stroke: none,
    inset: 4pt,
    ..surcharges.map(it => (
      [#it.at("label", default: "")],
      [#money(it.at("amount", default: 0), sym: sym)],
    )).flatten()
  )
}

#v(1cm)

// Totals Calculation
#let charge-total = charges.fold(0.0, (acc, it) => acc + float(it.at("amount", default: 0)))
#let surcharge-total = surcharges.fold(0.0, (acc, it) => acc + float(it.at("amount", default: 0)))
#let grand-total = charge-total + surcharge-total

#align(right)[
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 4pt,
    [#text(fill: secondary)[Subtotal (Freight):]], [#money(charge-total, sym: sym)],
    [#text(fill: secondary)[Total Surcharges:]], [#money(surcharge-total, sym: sym)],
    table.hline(stroke: 0.5pt + gray),
    [#text(weight: "bold", size: 13pt)[Total Amount:]], 
    [#text(weight: "bold", size: 13pt, fill: highlight)[#money(grand-total, sym: sym)]]
  )
]

#v(2cm)

// Payment Instructions
#set text(size: 9pt)
#grid(columns: (1fr, 1fr),
  [
    #text(weight: "bold")[Payment Details] \
    #v(2pt)
    Bank: #g("carrier.company") \
    IBAN: #g("carrier.iban") \
    BIC: #g("carrier.bic") \
    Currency: #cur
  ],
  align(right)[
    #text(style: "italic", fill: secondary)[
      Please include invoice number #g("invoice.number") in your payment reference.
    ]
  ]
)
