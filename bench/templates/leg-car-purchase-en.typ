// Used Car Purchase Agreement
// @description: Private vehicle sale: car data, price, warranty exclusion
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, sym: "$") = {
  // Remove commas from the string so float() can parse it (e.g., "13,750.00" -> "13750.00")
  let clean_x = if type(x) == str {
    x.replace(",", "")
  } else {
    str(x)
  }
  
  let v = calc.round(float(clean_x), digits: 2)
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

#let cur = g("sale.currency", default: "GBP")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Tinos", size: 11pt, lang: "en")

// Header
#align(center)[
  #text(size: 20pt, weight: "bold", tracking: 1pt)[VEHICLE PURCHASE AGREEMENT] \
  #v(2pt)
  #line(length: 100%, stroke: 1pt)
]

#v(12pt)

// Parties Section
#text(weight: "bold", size: 12pt)[1. THE PARTIES]
#v(4pt)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 30pt,
  [
    *Seller:* \
    #g("seller.name") \
    #g("seller.address") \
    #g("seller.city") \
    ID No: #g("seller.id_no")
  ],
  [
    *Buyer:* \
    #g("buyer.name") \
    #g("buyer.address") \
    #g("buyer.city") \
    ID No: #g("buyer.id_no")
  ]
)

#v(12pt)

// Vehicle Section
#text(weight: "bold", size: 12pt)[2. VEHICLE DESCRIPTION]
#v(4pt)

#rect(width: 100%, stroke: 0.5pt + gray, inset: 10pt)[
  #set text(size: 10pt)
  #grid(
    columns: (1fr, 1fr),
    row-gutter: 8pt,
    column-gutter: 20pt,
    [*Make:* #g("vehicle.make")],
    [*Model:* #g("vehicle.model")],
    [*Year:* #g("vehicle.year")],
    [*Registration/Plate:* #g("vehicle.plate")],
    [*VIN:* #g("vehicle.vin")],
    [*Mileage:* #g("vehicle.mileage_km") km],
    [*First Reg:* #g("vehicle.first_registration")],
    [*Inspection:* #g("vehicle.inspections_until")]
  )
]

#v(12pt)

// Sale Terms
#text(weight: "bold", size: 12pt)[3. SALE TERMS & PRICE]
#v(4pt)

#let price_val = g("sale.price", default: "0")
#let total_price = money(price_val, sym: sym)

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: 5pt,
  [*Purchase Price:*], [#text(size: 13pt, weight: "bold")[#total_price]],
  [*Payment Method:*], [#g("sale.payment_method")],
  [*Handover Date:*], [#g("sale.handover_date")],
)

#v(12pt)

// Condition & Warranty
#text(weight: "bold", size: 12pt)[4. CONDITION & WARRANTY]
#v(4pt)

#text(size: 10pt)[
  The Seller declares that the vehicle is sold with the following known defects: \
  #if g("sale.defects_known") != "" [
    #block(inset: (left: 10pt), text(style: "italic", g("sale.defects_known")))
  ] else [
    None disclosed.
  ]
]

#v(6pt)

#let warranty_excl = g("sale.warranty_excluded", default: "false")
#if warranty_excl == "true" or warranty_excl == true [
  #rect(width: 100%, fill: rgb("#fdf2f2"), stroke: 0.5pt + red.darken(50%), inset: 8pt)[
    #set text(size: 10pt)
    *WARRANTY EXCLUSION:* This vehicle is sold "as is". The Seller provides no warranty, express or implied, regarding the condition, fitness for a particular purpose, or merchantability of the vehicle. The Buyer acknowledges they have had the opportunity to inspect the vehicle.
  ]
] else [
  The vehicle is sold with standard manufacturer warranties where applicable.
]

#v(20pt)

// Signatures
#text(weight: "bold", size: 12pt)[5. EXECUTION]
#v(4pt)

#text(size: 10pt)[
  Signed at *#g("signatures.place")* on this date: *#g("signatures.date")*.
]

#v(30pt)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 40pt,
  [
    #line(length: 100%, stroke: 0.5pt) \
    *Seller Signature* \
    #text(size: 9pt, fill: gray.darken(50%))[#g("seller.name")]
  ],
  [
    #line(length: 100%, stroke: 0.5pt) \
    *Buyer Signature* \
    #text(size: 9pt, fill: gray.darken(50%))[#g("buyer.name")]
  ]
)
