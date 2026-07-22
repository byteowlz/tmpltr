// Product Recall Notice
// @description: Safety recall letter with affected lots, hazard and remedy
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

#let alert = rgb("#b3111b")
#let recall = data.at("recall", default: (:))
#let models = recall.at("models", default: ())

#set page(paper: "a4", margin: (x: 2.2cm, top: 1.8cm, bottom: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #g("manufacturer.name") · #g("manufacturer.address")
    #h(1fr) Recall hotline: #g("manufacturer.hotline")
  ])
#set text(font: "Arimo", size: 10pt)

// Alert banner
#block(width: 100%, fill: alert, inset: (x: 14pt, y: 10pt))[
  #grid(columns: (auto, 1fr), column-gutter: 12pt, align: horizon,
    text(fill: white, size: 26pt, weight: "bold")[⚠],
    [
      #text(fill: white, size: 17pt, weight: "bold", tracking: 0.5pt)[IMPORTANT SAFETY RECALL] \
      #text(fill: white, size: 10pt)[Please read this notice immediately and act on the instructions below.]
    ])
]
#v(10pt)

#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 11pt)[#g("manufacturer.name")] \
    #text(size: 9pt)[#g("manufacturer.address")]
  ],
  align(right)[#text(size: 9.5pt)[#g("date")]])
#v(10pt)

#text(size: 13pt, weight: "bold")[Voluntary recall: #g("recall.product", default: "affected product")]
#v(8pt)

Dear valued customer,

#g("manufacturer.name", default: "We") #(" ")have identified a safety issue affecting the product named above and, in cooperation with the relevant consumer-safety authorities, are voluntarily recalling the units described below. Your safety is our highest priority, and we sincerely apologize for the inconvenience.

#v(6pt)

// Affected units panel
#block(width: 100%, stroke: (left: 3pt + alert), fill: rgb("#fdf0f0"), inset: 11pt)[
  #text(size: 9pt, weight: "bold", fill: alert)[AFFECTED UNITS]
  #v(4pt)
  #set text(size: 9.5pt)
  #if models.len() > 0 [
    #list(tight: true, spacing: 4pt, ..models.map(m => [#m]))
    #v(3pt)
  ]
  #grid(columns: (auto, 1fr), column-gutter: 10pt, row-gutter: 4pt,
    text(weight: "bold")[Lot range:], [#g("recall.lot_range", default: "—")],
    text(weight: "bold")[Sold:], [#g("recall.sold_period", default: "—")])
]
#v(8pt)

#text(size: 10.5pt, weight: "bold", fill: alert)[Hazard] \
#g("recall.hazard", default: "A potential safety hazard has been identified.")
#v(6pt)

#text(size: 10.5pt, weight: "bold", fill: alert)[Incidents reported] \
#g("recall.incidents", default: "—")
#v(6pt)

#text(size: 10.5pt, weight: "bold", fill: alert)[Remedy] \
#g("recall.remedy", default: "Contact us for a remedy.")
#if g("recall.refund_amount") != "" [
  Refunds are issued at the full purchase price of #text(weight: "bold")[#money(g("recall.refund_amount", default: 0))].
]
#v(6pt)

#text(size: 10.5pt, weight: "bold", fill: alert)[What you should do] \
#g("recall.instructions", default: "Stop using the product immediately and contact us.")
#v(10pt)

// Contact box
#block(width: 100%, stroke: 0.75pt + gray.darken(20%), inset: 10pt, radius: 2pt)[
  #text(size: 9pt, weight: "bold")[HOW TO REACH US]
  #v(3pt)
  #set text(size: 9.5pt)
  Hotline: #text(weight: "bold")[#g("manufacturer.hotline")] #h(14pt)
  Email: #text(weight: "bold")[#g("manufacturer.email")]
]
#v(10pt)

We thank you for your immediate attention to this notice.

#v(6pt)
Sincerely, \
#v(14pt)
#text(weight: "bold")[Consumer Safety Team] \
#g("manufacturer.name")
