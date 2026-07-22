// Bill of Materials (BOM)
// @description: Engineering assembly BOM with part numbers, quantities, suppliers, and costs
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, default_val: 0, sym: "$") = {
  let val_to_convert = if type(x) == float or type(x) == int { x } else { 0.0 }
  let v = calc.round(float(val_to_convert), digits: 2)
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

#let accent = rgb("#2e3440")
#let secondary = rgb("#4c566a")
#let cur = g("totals.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm),
  footer: [
    #set text(size: 8pt, fill: gray)
    #line(length: 100%, stroke: 0.5pt + gray)
    #grid(columns: (1fr, 1fr),
      [#g("company.name", default: "—")],
      align(right)[#g("assembly.number", default: "—") · Rev #g("assembly.revision", default: "-")]
    )
  ]
)

#set text(font: "Tinos", size: 10pt)

// Header Section
#grid(columns: (1fr, auto),
  stack(spacing: 4pt)[
    #text(size: 22pt, weight: "bold", fill: accent)[BILL OF MATERIALS] \
    #text(size: 12pt, fill: secondary)[Project: #g("company.project", default: "—")]
  ],
  align(right)[
    #box(fill: accent, inset: 6pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 10pt)[#g("assembly.status", default: "—")]
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(10pt)

// Assembly Metadata Block
#grid(columns: (1fr, 1fr, 1fr), column-gutter: 15pt,
  stack(spacing: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[ASSEMBLY NAME] \
    #text(size: 11pt)[#g("assembly.name", default: "—")]
  ],
  stack(spacing: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[PART NUMBER] \
    #text(size: 11pt, weight: "bold")[#g("assembly.number", default: "—")]
  ],
  stack(spacing: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[REVISION] \
    #text(size: 11pt)[#g("assembly.revision", default: "—")]
  ]
)

#v(6pt)
#grid(columns: (1fr, 1fr, 1fr), column-gutter: 15pt,
  stack(spacing: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[DATE] \
    #text(size: 10pt)[#g("assembly.date", default: "—")]
  ],
  stack(spacing: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[AUTHOR] \
    #text(size: 10pt)[#g("assembly.author", default: "—")]
  ],
  stack(spacing: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[COMPANY] \
    #text(size: 10pt)[#g("company.name", default: "—")]
  ]
)

#v(15pt)

// Items Table
#let raw_items = data.at("items", default: ())
#let items = if type(raw_items) == array { raw_items } else { () }

#if items.len() > 0 {
  table(
    columns: (auto, 1.2fr, 1.5fr, auto, auto, auto, 1.2fr),
    align: (center, left, left, center, right, right, left),
    stroke: none,
    inset: 6pt,
    fill: (_, row) => if row == 0 { accent } else if calc.even(row) { rgb("#eceff4") } else { white },
    table.header(
      [#text(fill: white, weight: "bold")[POS]],
      [#text(fill: white, weight: "bold")[PART NUMBER]],
      [#text(fill: white, weight: "bold")[DESCRIPTION]],
      [#text(fill: white, weight: "bold")[QTY]],
      [#text(fill: white, weight: "bold")[UNIT]],
      [#text(fill: white, weight: "bold")[UNIT COST]],
      [#text(fill: white, weight: "bold")[SUPPLIER]]
    ),
    ..items.enumerate().map(((i, it)) => {
      let it_dict = if type(it) == dictionary { it } else { dict() }
      (
        [#(it_dict.at("pos", default: i + 1))],
        [#text(weight: "bold")[#it_dict.at("part_number", default: "—")]],
        [#it_dict.at("description", default: "—") \ #text(size: 8pt, fill: gray)[#it_dict.at("material", default: "")]],
        [#it_dict.at("qty", default: 0)],
        [#it_dict.at("unit", default: "")],
        [#money(it_dict.at("unit_cost", default: 0), sym: sym)],
        [#text(size: 9pt)[#it_dict.at("supplier", default: "—")]],
      )
    }).flatten()
  )
} else {
  align(center, text(fill: gray, style: "italic")[No items listed in this assembly.])
}

#v(10pt)

// Summary Block
#align(right)[
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 4pt,
    [#text(size: 10pt)[Total Line Items:]], [#text(size: 10pt)[#g("totals.part_count", default: "0")]],
    [#text(size: 10pt)[Total Estimated Cost:]], [#text(size: 14pt, weight: "bold", fill: accent)[#money(g("totals.total_cost", default: 0), sym: sym)]]
  )
]

#v(20pt)
#set text(size: 8pt, fill: secondary)
#line(length: 100%, stroke: 0.5pt + gray)
#text(style: "italic")[
  This document is a generated Bill of Materials for engineering purposes. 
  All costs are estimates based on current supplier data and are subject to change.
]
