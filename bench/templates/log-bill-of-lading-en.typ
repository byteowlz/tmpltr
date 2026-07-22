// Bill of Lading
// @description: B/L with vessel, ports, container, cargo description
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm),
)

// Use Tinos for a formal, typewriter/document feel common in logistics
#set text(font: "Tinos", size: 10pt)

// Styling constants
#let line-color = rgb("#333333")
#let header-bg = rgb("#f0f0f0")

// Header Section
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 18pt, weight: "bold")[BILL OF LADING] \
    #text(size: 10pt, fill: gray.darken(50%))[Ocean Freight Document]
  ],
  align(right)[
    #text(weight: "bold", size: 12pt)[B/L NO: #g("transport.bl_number", default: "—")] \
    #text(size: 10pt)[Carrier: #g("carrier.name", default: "—")] \
    #text(size: 9pt, fill: gray.darken(50%))[SCAC: #g("carrier.scac", default: "—")]
  ]
)

#v(5pt)
#line(length: 100%, stroke: 1.5pt + line-color)
#v(10pt)

// Parties Section
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[SHIPPER / EXPORTER] \
    #text(weight: "bold")[#g("shipper.company", default: "—")] \
    #text(size: 9pt)[#g("shipper.address", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[CONSIGNEE] \
    #text(weight: "bold")[#g("consignee.company", default: "—")] \
    #text(size: 9pt)[#g("consignee.address", default: "—")]
  ],
  [
    #text(weight: "bold", size: 8pt, fill: gray.darken(50%))[NOTIFY PARTY] \
    #text(weight: "bold")[#g("notify.company", default: "—")] \
    #text(size: 9pt)[#g("notify.address", default: "—")]
  ]
)

#v(15pt)

// Transport Details Grid
#table(
  columns: (1fr, 1fr, 1fr, 1fr),
  stroke: 0.5pt + line-color,
  inset: 6pt,
  fill: (x, y) => if y == 0 { header-bg },
  // Row 1
  [#text(size: 8pt, fill: gray.darken(50%))[VESSEL / VOYAGE]], [#text(size: 8pt, fill: gray.darken(50%))[PORT OF LOADING]], [#text(size: 8pt, fill: gray.darken(50%))[PORT OF DISCHARGE]], [#text(size: 8pt, fill: gray.darken(50%))[FREIGHT TERMS]],
  [#g("transport.vessel", default: "—") / #g("transport.voyage", default: "—")], [#g("transport.port_of_loading", default: "—")], [#g("transport.port_of_discharge", default: "—")], [#g("cargo.freight_terms", default: "—")],
  
  // Row 2
  [#text(size: 8pt, fill: gray.darken(50%))[CONTAINER NO.]], [#text(size: 8pt, fill: gray.darken(50%))[SEAL NO.]], [#text(size: 8pt, fill: gray.darken(50%))[B/L DATE]], [#text(size: 8pt, fill: gray.darken(50%))[PLACE OF ISSUE]],
  [#g("transport.container_no", default: "—")], [#g("transport.seal_no", default: "—")], [#g("issue.date", default: "—")], [#g("issue.place", default: "—")]
)

#v(15pt)

// Cargo Description Section
#text(weight: "bold", size: 10pt)[PARTICULARS FURNISHED BY SHIPPER]
#v(5pt)
#table(
  columns: (1fr, 1fr, 1fr),
  stroke: 0.5pt + line-color,
  inset: 8pt,
  fill: (x, y) => if y == 0 { header-bg },
  [#text(size: 8pt, fill: gray.darken(50%))[DESCRIPTION OF GOODS / PACKAGES]], 
  [#text(size: 8pt, fill: gray.darken(50%))[GROSS WEIGHT]], 
  [#text(size: 8pt, fill: gray.darken(50%))[MEASUREMENT]],
  
  // Content
  [#g("cargo.packages", default: "—") \ #v(5pt) #g("cargo.description", default: "—")],
  [#g("cargo.weight_kg", default: "0") kg],
  [#g("cargo.volume_m3", default: "0") m³],
)

#v(20pt)

// Footer / Signature Area
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 8pt, fill: gray.darken(50%))[RECEIVED by the Carrier from the said Shipper in apparent good order and condition...] \
    #v(10pt)
    #text(size: 9pt, style: "italic")[Subject to all terms and conditions of the Bill of Lading.]
  ],
  align(right)[
    #v(10pt)
    #line(length: 60%, stroke: 0.5pt + black) \
    #text(size: 9pt, weight: "bold")[Signature of Carrier or Agent] \
    #text(size: 8pt, fill: gray.darken(50%))[#g("carrier.name", default: "Carrier")]
  ]
)

#v(1fr)

// Bottom Branding/Legal
#line(length: 100%, stroke: 0.5pt + gray)
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 7pt, fill: gray.darken(50%))[Generated via Meridian Star Container Line Digital Systems]
  ],
  align(right)[
    #text(size: 7pt, fill: gray.darken(50%))[Document ID: #g("transport.bl_number", default: "—")]
  ]
)
