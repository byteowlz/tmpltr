// Packing List
// @description: Carton-level packing detail with weights and dimensions
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let accent = rgb("#b45309")
#let cartons = data.at("cartons", default: ())

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #align(center)[Packing list #g("shipment.number") — issued by #g("shipper.company") — page 1 of 1]
  ])
#set text(font: "Tinos", size: 10pt)

// Centered header
#align(center)[
  #text(font: "Arimo", weight: "bold", size: 21pt, tracking: 3pt, fill: accent)[PACKING LIST]
  #v(2pt)
  #text(size: 9pt, fill: gray.darken(40%))[Shipment #g("shipment.number") · #g("shipment.date")]
]
#v(4pt)
#line(length: 100%, stroke: 1.4pt + accent)
#line(length: 100%, stroke: 0.4pt + accent)
#v(10pt)

// Shipper / consignee boxes
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  block(stroke: 0.6pt + gray.darken(40%), inset: 9pt, width: 100%)[
    #text(font: "Arimo", size: 7.5pt, weight: "bold", fill: accent)[SHIPPER / EXPORTER] \
    #v(2pt)
    #text(weight: "bold")[#g("shipper.company")] \
    #g("shipper.address") \
    #g("shipper.city"), #g("shipper.country")
  ],
  block(stroke: 0.6pt + gray.darken(40%), inset: 9pt, width: 100%)[
    #text(font: "Arimo", size: 7.5pt, weight: "bold", fill: accent)[CONSIGNEE] \
    #v(2pt)
    #text(weight: "bold")[#g("consignee.company")] \
    #g("consignee.address") \
    #g("consignee.city"), #g("consignee.country")
  ])
#v(8pt)

// Shipment meta
#grid(columns: (1fr, 1fr), column-gutter: 14pt, row-gutter: 4pt,
  [#text(font: "Arimo", size: 8pt, weight: "bold", fill: gray.darken(40%))[ORDER REFERENCE:] #g("shipment.order_ref", default: "—")],
  [#text(font: "Arimo", size: 8pt, weight: "bold", fill: gray.darken(40%))[CARRIER:] #g("shipment.carrier", default: "—")])
#v(10pt)

// Carton table
#if cartons.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto),
    align: (center, left, right, right, center),
    inset: (x: 7pt, y: 5.5pt),
    stroke: 0.5pt + gray.darken(50%),
    fill: (x, y) => if y == 0 { accent.lighten(88%) },
    table.header(
      [#text(font: "Arimo", size: 8pt, weight: "bold")[CARTON NO.]],
      [#text(font: "Arimo", size: 8pt, weight: "bold")[CONTENTS]],
      [#text(font: "Arimo", size: 8pt, weight: "bold")[QTY]],
      [#text(font: "Arimo", size: 8pt, weight: "bold")[GROSS WT (KG)]],
      [#text(font: "Arimo", size: 8pt, weight: "bold")[DIMS L×W×H (CM)]]),
    ..cartons.map(c => (
      [*#c.at("carton_no", default: "")*],
      [#c.at("contents", default: "")],
      [#c.at("qty", default: "")],
      [#c.at("weight_kg", default: "")],
      [#c.at("dimensions_cm", default: "")],
    )).flatten()
  )
} else {
  text(fill: gray)[No cartons listed.]
}
#v(8pt)

// Totals band
#block(fill: accent.lighten(90%), stroke: (top: 1.2pt + accent), inset: 8pt, width: 100%)[
  #grid(columns: (1fr, 1fr, 1fr), align: center,
    [#text(font: "Arimo", size: 8pt, fill: gray.darken(40%))[TOTAL CARTONS] \ #text(weight: "bold", size: 12pt)[#g("shipment.total_cartons", default: "—")]],
    [#text(font: "Arimo", size: 8pt, fill: gray.darken(40%))[TOTAL GROSS WEIGHT] \ #text(weight: "bold", size: 12pt)[#g("shipment.total_weight_kg", default: "—") kg]],
    [#text(font: "Arimo", size: 8pt, fill: gray.darken(40%))[TOTAL VOLUME] \ #text(weight: "bold", size: 12pt)[#g("shipment.total_volume_m3", default: "—") m³]])
]
#v(16pt)

#text(size: 9pt, style: "italic")[This packing list is issued for customs and receiving purposes only and does not constitute a commercial invoice. Weights are gross weights including packaging.]
#v(20pt)
#grid(columns: (1fr, 1fr), column-gutter: 60pt,
  [#line(length: 100%, stroke: 0.6pt) #text(size: 8pt, fill: gray.darken(30%))[Packed / checked by]],
  [#line(length: 100%, stroke: 0.6pt) #text(size: 8pt, fill: gray.darken(30%))[Date, signature]])
