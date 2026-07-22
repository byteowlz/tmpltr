// Return Merchandise Authorization (RMA) Form
// @description: Professional RMA form for hardware returns with itemized serial numbers and shipping instructions
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm),
)

// Theme Colors
#let accent-color = rgb("#2c3e50")
#let secondary-color = rgb("#ecf0f1")
#let border-color = rgb("#bdc3c7")

#set text(font: "Tinos", size: 10pt, lang: "en")

// Header
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(size: 22pt, weight: "bold", fill: accent-color)[RMA FORM] \
    #text(size: 10pt, fill: gray.darken(50%))[Return Merchandise Authorization]
  ],
  [
    #text(weight: "bold", size: 12pt)[#g("vendor.company", default: "Vendor Name")] \
    #text(size: 9pt)[#g("vendor.address", default: "")] \
    #text(size: 9pt, fill: accent-color)[#g("vendor.rma_email", default: "")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent-color)
#v(10pt)

// RMA Meta Info
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 15pt,
  [
    #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[RMA NUMBER] \
    #text(size: 12pt, weight: "bold")[#g("rma.number", default: "—")]
  ],
  [
    #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[ISSUE DATE] \
    #text(size: 11pt)[#g("rma.issue_date", default: "—")]
  ],
  [
    #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[VALID UNTIL] \
    #text(size: 11pt, fill: if g("rma.valid_until") == "" { gray } else { black })[#g("rma.valid_until", default: "—")]
  ]
)

#v(15pt)

// Customer and Return Details
#grid(
  columns: (1fr, 1fr),
  column-gutter: 30pt,
  [
    #rect(width: 100%, fill: secondary-color, inset: 5pt, radius: 2pt)[
      #text(size: 9pt, weight: "bold")[CUSTOMER DETAILS]
    ]
    #v(4pt)
    #text(weight: "bold")[#g("customer.name", default: "—")] \
    #if g("customer.company") != "" [#g("customer.company", default: "") \ ]
    #g("customer.email", default: "—") \
    #text(size: 9pt, fill: gray.darken(40%))[Order: #g("customer.order_no", default: "—")]
  ],
  [
    #rect(width: 100%, fill: secondary-color, inset: 5pt, radius: 2pt)[
      #text(size: 9pt, weight: "bold")[RETURN INSTRUCTIONS]
    ]
    #v(4pt)
    #text(size: 9pt)[Ship to:] \
    #text(size: 9pt)[#g("rma.ship_to", default: "—")]
  ]
)

#v(20pt)

// RMA Reason and Resolution
#block(width: 100%, stroke: 0.5pt + border-color, inset: 10pt, radius: 2pt)[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 20pt,
    [
      #text(size: 8pt, weight: "bold", fill: accent-color)[REASON FOR RETURN] \
      #v(2pt)
      #text(size: 9pt)[#g("rma.return_reason", default: "No reason provided.")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: accent-color)[PROPOSED RESOLUTION] \
      #v(2pt)
      #text(size: 9pt)[#g("rma.resolution", default: "Pending review.")]
    ]
  )
]

#v(15pt)

// Items Table
#text(size: 9pt, weight: "bold", fill: accent-color)[RETURNED ITEMS]
#v(5pt)

#let items = if data.at("items", default: ()) != none { data.at("items", default: ()) } else { () }

#if items.len() > 0 {
  table(
    columns: (1fr, 2fr, 1fr, 2fr, 1fr),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { accent-color } else if calc.even(y) { secondary-color } else { white },
    table.header(
      [#text(fill: white, size: 8pt)[SKU / PART]],
      [#text(fill: white, size: 8pt)[DESCRIPTION]],
      [#text(fill: white, size: 8pt)[QTY]],
      [#text(fill: white, size: 8pt)[SERIAL NUMBER]],
      [#text(fill: white, size: 8pt)[CONDITION]],
    ),
    ..items.map(((it)) => (
      [#text(size: 9pt)[#it.at("sku", default: "—")]],
      [#text(size: 9pt)[#it.at("description", default: "—")]],
      [#text(size: 9pt)[#it.at("qty", default: 0)]],
      [#text(size: 9pt, style: "italic")[#it.at("serial", default: "—")]],
      [#text(size: 9pt)[#it.at("condition", default: "—")]],
    )).flatten()
  )
} else {
  block(width: 100%, fill: secondary-color, inset: 10pt, align(center, text(size: 9pt, style: "italic")[No items listed in this RMA]))
}

#v(20pt)

// Footer / Terms
#set text(size: 8pt, fill: gray.darken(50%))
#line(length: 100%, stroke: 0.5pt + border-color)
#v(5pt)

#grid(
  columns: (1fr, 1fr),
  [
    *Important Notes:* \
    - Please include a copy of this RMA form inside the package. \
    - Ensure all items are securely packed to prevent transit damage. \
    - RMA number must be clearly visible on the exterior of the box.
  ],
  align(right)[
    *Restocking Fee:* #g("rma.restocking_fee_pct", default: "0")% \
    *Status:* Authorized
  ]
)
