// Warranty Certificate
// @description: Product warranty terms with serial and coverage period
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let gold = rgb("#8a6d1d")
#let ink = rgb("#2b2416")

#let warranty = data.at("warranty", default: (:))
#let coverage = warranty.at("coverage", default: ())
#let exclusions = warranty.at("exclusions", default: ())

#set page(paper: "a4", margin: (x: 2.4cm, y: 2.2cm))
#set text(font: "Libertinus Serif", size: 10pt, fill: ink)

// Double certificate frame
#place(top + left, dx: -0.9cm, dy: -0.9cm,
  rect(width: 100% + 1.8cm, height: 100% + 1.8cm, stroke: 2.5pt + gold))
#place(top + left, dx: -0.7cm, dy: -0.7cm,
  rect(width: 100% + 1.4cm, height: 100% + 1.4cm, stroke: 0.75pt + gold))

#align(center)[
  #let mname = str(g("manufacturer.name", default: "Manufacturer"))
  #text(size: 10pt, tracking: 2.5pt)[#upper(mname)]
  #v(2pt)
  #line(length: 34%, stroke: 0.5pt + gold)
  #v(10pt)
  #text(size: 26pt, weight: "bold", fill: gold)[Certificate of Warranty]
  #v(4pt)
  #text(size: 10.5pt, style: "italic")[
    This certifies that the product identified below is covered by a
    #text(weight: "bold")[#g("warranty.months", default: "12")-month limited warranty]
    from the date of purchase.
  ]
  #v(4pt)
  #text(size: 9pt)[Certificate No. #text(weight: "bold")[#g("registration.certificate_no", default: "—")] · Registered #g("registration.date", default: "—")]
]

#v(14pt)

// Product panel
#block(width: 100%, stroke: 0.75pt + gold, inset: 12pt, radius: 2pt)[
  #text(size: 8pt, tracking: 1.5pt, fill: gold)[PRODUCT DETAILS]
  #v(5pt)
  #grid(columns: (auto, 1fr, auto, 1fr), column-gutter: 10pt, row-gutter: 6pt,
    text(size: 9pt, fill: gray.darken(30%))[Product], text(weight: "bold")[#g("product.name")],
    text(size: 9pt, fill: gray.darken(30%))[Model], text(weight: "bold")[#g("product.model")],
    text(size: 9pt, fill: gray.darken(30%))[Serial no.], text(weight: "bold")[#g("product.serial")],
    text(size: 9pt, fill: gray.darken(30%))[Purchased], [#g("product.purchase_date")],
    text(size: 9pt, fill: gray.darken(30%))[Dealer], grid.cell(colspan: 3)[#g("product.dealer")])
]

#v(12pt)

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #text(size: 9.5pt, weight: "bold", fill: gold)[What is covered]
    #v(3pt)
    #if coverage.len() > 0 [
      #set text(size: 9pt)
      #list(tight: false, spacing: 5pt, marker: text(fill: gold)[▸], ..coverage.map(c => [#c]))
    ] else [
      #text(size: 9pt, fill: gray)[See enclosed warranty terms.]
    ]
  ],
  [
    #text(size: 9.5pt, weight: "bold", fill: gold)[What is not covered]
    #v(3pt)
    #if exclusions.len() > 0 [
      #set text(size: 9pt)
      #list(tight: false, spacing: 5pt, marker: text(fill: gray.darken(20%))[▹], ..exclusions.map(c => [#c]))
    ] else [
      #text(size: 9pt, fill: gray)[See enclosed warranty terms.]
    ]
  ])

#v(12pt)

#text(size: 9.5pt, weight: "bold", fill: gold)[How to make a claim]
#v(3pt)
#text(size: 9pt)[#g("warranty.claim_procedure", default: "Contact our customer support with your certificate number and proof of purchase.")]

#v(1fr)

// Signature strip
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #v(18pt)
    #line(length: 100%, stroke: 0.5pt + ink)
    #text(size: 8pt)[Authorized signature, #g("manufacturer.name")]
  ],
  [
    #v(18pt)
    #line(length: 100%, stroke: 0.5pt + ink)
    #text(size: 8pt)[Date of issue]
  ])

#v(14pt)
#align(center)[
  #line(length: 60%, stroke: 0.5pt + gold)
  #v(3pt)
  #text(size: 8pt, fill: gray.darken(30%))[
    #g("manufacturer.name") · #g("manufacturer.address") \
    Warranty hotline #g("manufacturer.hotline") · #g("manufacturer.support_email")
  ]
]
