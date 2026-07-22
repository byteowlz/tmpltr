// Goods Receipt Note
// @description: Incoming goods inspection with discrepancies
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4", 
  margin: (top: 1.5cm, bottom: 2cm, left: 1.5cm, right: 1.5cm),
  footer: [
    #set text(size: 8pt, fill: gray)
    #line(length: 100%, stroke: 0.5pt + gray)
    #grid(columns: (1fr, 1fr),
      [#g("warehouse.name", default: "Warehouse System")],
      align(right)[Document ID: #g("receipt.grn_number", default: "—")]
    )
  ]
)

#set text(font: "Tinos", size: 10pt)

// Colors and Styling
#let accent = rgb("#2d5a27") // Deep forest green for logistics/warehouse feel
#let bg-light = rgb("#f8f9f8")

// Header
#grid(columns: (1fr, auto),
  [
    #text(size: 22pt, weight: "bold", fill: accent)[GOODS RECEIPT] \
    #text(size: 10pt, fill: gray.darken(50%))[Inspection & Receiving Report]
  ],
  align(right)[
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#g("receipt.grn_number", default: "N/A")]
    ]
  ]
)

#v(10pt)

// Info Grid
#grid(
  columns: (1fr, 1fr),
  column-gutter: 20pt,
  stroke: none,
  // Left Column: Supplier & PO
  [
    #text(weight: "bold", size: 9pt, fill: accent)[SUPPLIER] \
    #v(2pt)
    #text(size: 11pt)[#g("supplier.company", default: "—")] \
    #v(8pt)
    #text(weight: "bold", size: 9pt, fill: accent)[PURCHASE ORDER] \
    #v(2pt)
    #g("receipt.po_number", default: "—")
  ],
  // Right Column: Warehouse & Logistics
  [
    #text(weight: "bold", size: 9pt, fill: accent)[RECEIVING LOCATION] \
    #v(2pt)
    #g("warehouse.name", default: "—") \
    #g("warehouse.location", default: "—") \
    #v(8pt)
    #text(weight: "bold", size: 9pt, fill: accent)[LOGISTICS INFO] \
    #v(2pt)
    #text(size: 9pt)[
      *Date:* #g("receipt.date", default: "—") \
      *Carrier:* #g("receipt.carrier", default: "—") \
      *Delivery Note:* #g("receipt.delivery_note_no", default: "—")
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent)
#v(10pt)

// Items Table
#let items = if data.at("items", default: none) != none { data.at("items") } else { () }

#if items.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, 1fr),
    align: (center, left, center, center, left),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { bg-light } else { white },
    table.header(
      [#text(weight: "bold")[SKU]],
      [#text(weight: "bold")[Description]],
      [#text(weight: "bold")[Ord.]],
      [#text(weight: "bold")[Rec.]],
      [#text(weight: "bold")[Notes/Discrepancy]]
    ),
    ..items.map(((it)) => (
      [#text(font: "Cousine", size: 9pt)[#it.at("sku", default: "—")]],
      [#it.at("description", default: "—")],
      [#it.at("ordered", default: 0)],
      [#it.at("received", default: 0)],
      [
        #if it.at("condition", default: "OK") != "OK" [
          #text(fill: red.darken(50%), weight: "bold")[#it.at("condition", default: "")] \
        ]
        #text(size: 8.5pt, fill: gray.darken(30%))[#it.at("discrepancy", default: "")]
      ]
    )).flatten()
  )
} else {
  align(center, text(fill: gray, style: "italic")[No items recorded in this receipt.])
}

#v(15pt)

// Remarks Section
#rect(
  width: 100%,
  stroke: 0.5pt + gray,
  fill: bg-light,
  inset: 10pt,
  radius: 2pt
)[
  #text(weight: "bold", size: 9pt, fill: accent)[REMARKS & INSPECTION NOTES] \
  #v(4pt)
  #text(size: 9pt, style: "italic")[#g("remarks", default: "No additional remarks.")]
]

#v(20pt)

// Signatures
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #v(10pt)
    #line(length: 100%, stroke: 0.5pt + black) \
    #text(size: 8pt, weight: "bold")[Warehouse Supervisor Signature] \
    #text(size: 7pt, fill: gray)[Date: #g("receipt.date", default: "—")]
  ],
  [
    #v(10pt)
    #line(length: 100%, stroke: 0.5pt + black) \
    #text(size: 8pt, weight: "bold")[Received By: #g("warehouse.received_by", default: "—")] \
    #text(size: 7pt, fill: gray)[Date: #g("receipt.date", default: "—")]
  ]
)
