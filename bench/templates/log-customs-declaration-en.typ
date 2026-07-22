// Customs Declaration (CN23-style)
// @description: Export declaration with HS codes, values, origin
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let items = data.at("items", default: ())
#let cur = g("shipment.currency", default: "EUR")

#let lbl(t) = text(size: 6pt, weight: "bold", tracking: 0.3pt, fill: gray.darken(55%))[#upper(t)]
#let cell(label, value, h: auto) = box(width: 100%, height: h, inset: 4pt)[
  #lbl(label) \
  #v(1pt)
  #text(size: 9pt)[#value]
]

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 1.8cm, left: 1.8cm, right: 1.8cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #align(center)[CN23-style export declaration · #g("shipment.invoice_no") · May be opened officially]
  ])
#set text(font: "Arimo", size: 9pt)

// Form header
#grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
  [
    #text(weight: "bold", size: 16pt, tracking: 1pt)[CUSTOMS DECLARATION]
    #linebreak()
    #text(size: 8.5pt, fill: gray.darken(40%))[CN 23 — may be opened officially / peut être ouvert d'office]
  ],
  block(stroke: 1pt + black, inset: 7pt)[
    #lbl("Invoice / ref no.") \
    #text(weight: "bold", size: 11pt)[#g("shipment.invoice_no", default: "—")]
  ])
#v(6pt)

// Sender / recipient block
#table(columns: (1fr, 1fr), stroke: 0.6pt + black, inset: 0pt,
  cell("1. Sender (name, address, country)", [
    *#g("sender.name")* \
    #g("sender.address") \
    #g("sender.city"), #g("sender.country") \
    Tel. #g("sender.phone", default: "—")
  ], h: 22mm),
  cell("2. Recipient (name, address, country)", [
    *#g("recipient.name")* \
    #g("recipient.address") \
    #g("recipient.city"), #g("recipient.country")
  ], h: 22mm))

// Category + shipment meta row
#table(columns: (1.4fr, 1fr, 1fr, 1fr), stroke: 0.6pt + black, inset: 0pt,
  cell("3. Category of item", [*#g("shipment.category", default: "—")*], h: 11mm),
  cell("4. Date of posting", g("shipment.date", default: "—"), h: 11mm),
  cell("5. Currency", cur, h: 11mm),
  cell("6. Total gross weight (kg)", g("shipment.total_weight_kg", default: "—"), h: 11mm))
#v(6pt)

// Item grid
#lbl("7. Detailed description of contents")
#v(2pt)
#table(
  columns: (1fr, auto, auto, auto, auto, auto),
  align: (left, center, center, right, right, right),
  inset: (x: 5pt, y: 4pt),
  stroke: 0.6pt + black,
  fill: (x, y) => if y == 0 { gray.lighten(75%) },
  table.header(
    [#lbl("Description of goods")],
    [#lbl("HS tariff no.")],
    [#lbl("Origin")],
    [#lbl("Qty")],
    [#lbl("Net wt (kg)")],
    [#lbl([Value (#cur)])]),
  ..if items.len() > 0 {
    items.map(it => (
      [#it.at("description", default: "")],
      [#text(font: "Cousine", size: 8pt)[#it.at("hs_code", default: "")]],
      [#it.at("origin_country", default: "")],
      [#it.at("qty", default: "")],
      [#it.at("net_weight_kg", default: "")],
      [#it.at("value", default: "")],
    )).flatten()
  } else {
    ([#text(fill: gray, size: 8pt)[— no items declared —]], [], [], [], [], [])
  },
  table.cell(colspan: 4, align: right)[#text(size: 8pt, weight: "bold")[TOTALS]],
  [#text(weight: "bold", size: 8.5pt)[#g("shipment.total_weight_kg", default: "—")]],
  [#text(weight: "bold", size: 8.5pt)[#g("shipment.total_value", default: "—")]]
)
#v(6pt)

// Notes + declaration
#table(columns: (1fr, 1fr), stroke: 0.6pt + black, inset: 0pt,
  cell("8. Comments (e.g. licences, quarantine, restrictions)", [
    #text(size: 8pt)[Commercial sale. Goods not subject to export licence. EORI of sender available on request.]
  ], h: 20mm),
  cell("9. Office of origin / date of posting", [
    #g("declaration.place", default: "—"), #g("shipment.date", default: "—")
  ], h: 20mm))
#table(columns: (1fr,), stroke: 0.6pt + black, inset: 0pt,
  cell("10. Declaration", [
    #text(size: 8pt)[I, the undersigned, whose name and address are given on the item, certify that the particulars given in this declaration are correct and that this item does not contain any dangerous article prohibited by legislation or by postal or customs regulations.]
    #v(8pt)
    #grid(columns: (1fr, 1fr, 1.4fr), column-gutter: 14pt,
      [#v(10pt) #line(length: 100%, stroke: 0.5pt) #lbl("Place")#h(4pt)#text(size: 8pt)[#g("declaration.place")]],
      [#v(10pt) #line(length: 100%, stroke: 0.5pt) #lbl("Date")#h(4pt)#text(size: 8pt)[#g("declaration.date")]],
      [#v(10pt) #line(length: 100%, stroke: 0.5pt) #lbl("Signature")#h(4pt)#text(size: 8pt)[#g("declaration.signature_name")]])
  ], h: 34mm))
