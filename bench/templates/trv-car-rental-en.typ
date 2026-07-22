// Car Rental Agreement
// @description: Rental contract with vehicle, period, insurance, fuel policy
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

#let accent = rgb("#2e7d32") // Forest Green for travel/rental feel
#let cur = g("totals.currency", default: "EUR")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 2cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  header: [
    #set text(size: 8pt, fill: gray)
    Agreement No: #g("rental.agreement_no", default: "—")
  ]
)

#set text(font: "Tinos", size: 10pt)

// --- Header Section ---
#grid(columns: (1fr, auto),
  [
    #text(size: 22pt, weight: "bold", fill: accent)[RENTAL AGREEMENT] \
    #text(size: 10pt, fill: gray.darken(50%))[Vehicle Hire Contract]
  ],
  align(right)[
    #text(weight: "bold", size: 12pt)[#g("company.name")] \
    #text(size: 9pt)[#g("company.station")] \
    #text(size: 9pt)[#g("company.address")] \
    #text(size: 9pt)[#g("company.phone")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent)
#v(10pt)

// --- Parties Section ---
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #text(weight: "bold", fill: accent, size: 11pt)[RENTER DETAILS]
    #v(4pt)
    #table(
      columns: (auto, 1fr),
      stroke: none,
      inset: 2pt,
      [Name:], [#g("renter.name")],
      [License No:], [#g("renter.license_no")],
      [Date of Birth:], [#g("renter.dob")],
      [Address:], [#g("renter.address")],
    )
  ],
  [
    #text(weight: "bold", fill: accent, size: 11pt)[RENTAL SUMMARY]
    #v(4pt)
    #table(
      columns: (auto, 1fr),
      stroke: none,
      inset: 2pt,
      [Agreement:], [#g("rental.agreement_no")],
      [Vehicle:], [#g("rental.vehicle")],
      [Plate No:], [#g("rental.plate")],
      [Class:], [#g("rental.class")],
    )
  ]
)

#v(10pt)

// --- Rental Period & Location ---
#rect(fill: rgb("#f8f9fa"), inset: 10pt, radius: 2pt, stroke: 0.5pt + gray.lighten(50%))[
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 15pt,
    [
      #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[PICKUP] \
      #v(2pt)
      #g("rental.pickup") \
      #text(size: 9pt)[#g("rental.pickup_location")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[RETURN] \
      #v(2pt)
      #g("rental.return") \
      #text(size: 9pt)[#g("rental.return_location")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[TERMS] \
      #v(2pt)
      #g("rental.fuel_policy") \
      #text(size: 9pt)[#g("rental.mileage_limit")]
    ]
  )
]

#v(15pt)

// --- Insurance & Protection ---
#text(weight: "bold", fill: accent, size: 11pt)[PROTECTION & INSURANCE]
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #set text(size: 9pt)
    *Coverage:* #g("rental.insurance") \
    *Excess Amount:* #g("rental.excess")
  ],
  [
    #set text(size: 9pt)
    *Security Deposit:* #g("totals.deposit")
  ]
)

#v(15pt)

// --- Financial Breakdown ---
#text(weight: "bold", fill: accent, size: 11pt)[FINANCIAL SUMMARY]
#v(4pt)
#table(
  columns: (1fr, auto),
  stroke: none,
  inset: 5pt,
  fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
  table.header(
    [#text(weight: "bold")[Description]], [#text(weight: "bold")[Amount]]
  ),
  [Base Rental Rate (#g("rental.days") days)], [#money(g("totals.base", default: 0), sym: sym)],
  [Extras & Add-ons], [#money(g("totals.extras", default: 0), sym: sym)],
  [Taxes / VAT], [#money(g("totals.tax", default: 0), sym: sym)],
  table.hline(stroke: 0.5pt + gray),
  [#text(weight: "bold")[Total Amount Due]], [#text(weight: "bold", fill: accent)[#money(g("totals.total", default: 0), sym: sym)]]
)

#v(20pt)

// --- Signatures ---
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #v(10pt)
    #line(length: 100%, stroke: 0.5pt + black)
    #text(size: 8pt)[Signature of Renter] \
    #text(size: 8pt, fill: gray)[Date: #g("rental.pickup")]
  ],
  [
    #v(10pt)
    #line(length: 100%, stroke: 0.5pt + black)
    #text(size: 8pt)[Authorized Agent Signature] \
    #text(size: 8pt, fill: gray)[#g("company.name")]
  ]
)

#v(30pt)
#set text(size: 7pt, fill: gray)
#align(center)[
  This document serves as a legally binding rental agreement between #g("company.name") and the renter named above. 
  All terms and conditions are subject to the standard rental policy of the provider.
]
