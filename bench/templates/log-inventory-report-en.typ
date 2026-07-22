// Inventory Count Report
// @description: Stock count vs system with variances
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, sym: "$") = {
  let val_float = float(x)
  let v = calc.round(val_float, digits: 2)
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

#let accent = rgb("#2e7d32") // Logistics green
#let warning = rgb("#c62828") // Variance red
#let neutral = rgb("#455a64")

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm),
  header: [
    #set text(size: 8pt, fill: gray)
    #grid(columns: (1fr, 1fr),
      [Inventory Report: #g("warehouse.name", default: "N/A")],
      align(right)[Generated: #g("count.date", default: "N/A")]
    )
    #line(length: 100%, stroke: 0.5pt + gray)
  ]
)

#set text(font: "Adwaita Sans", size: 10pt)

// --- Header Section ---
#grid(columns: (1fr, 1fr),
  [
    #text(size: 20pt, weight: "bold", fill: accent)[INVENTORY COUNT] \
    #text(size: 12pt, fill: neutral)[#g("warehouse.name", default: "N/A")] \
    #text(size: 9pt, fill: gray)[#g("warehouse.location", default: "N/A")]
  ],
  align(right)[
    #box(fill: accent.lighten(80%), inset: 8pt, radius: 2pt)[
      #text(fill: accent, weight: "bold", size: 14pt)[Accuracy: #g("totals.accuracy_pct", default: "0")%]
    ]
  ]
)

#v(10pt)

// --- Metadata Cards ---
#grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt,
  rect(width: 100%, stroke: 0.5pt + gray, inset: 8pt)[
    #text(size: 8pt, weight: "bold", fill: neutral)[ZONE / AREA] \
    #text(size: 9pt)[#g("count.zone", default: "-")]
  ],
  rect(width: 100%, stroke: 0.5pt + gray, inset: 8pt)[
    #text(size: 8pt, weight: "bold", fill: neutral)[METHOD] \
    #text(size: 9pt)[#g("count.method", default: "-")]
  ],
  rect(width: 100%, stroke: 0.5pt + gray, inset: 8pt)[
    #text(size: 8pt, weight: "bold", fill: neutral)[DATE] \
    #text(size: 9pt)[#g("count.date", default: "-")]
  ]
)

#v(10pt)

// --- Personnel Section ---
#grid(columns: (1fr, 1fr),
  [
    #text(size: 8pt, weight: "bold", fill: neutral)[COUNTED BY] \
    #text(size: 9pt)[#g("warehouse.counted_by", default: "-")]
  ],
  align(right)[
    #text(size: 8pt, weight: "bold", fill: neutral)[SUPERVISOR] \
    #text(size: 9pt)[#g("warehouse.supervisor", default: "-")]
  ]
)

#v(15pt)

// --- Items Table ---
#let items = data.at("items", default: ())

#if items.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto, auto),
    align: (left, left, right, right, right, right),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      [#text(weight: "bold")[SKU]],
      [#text(weight: "bold")[Description]],
      [#text(weight: "bold")[System]],
      [#text(weight: "bold")[Counted]],
      [#text(weight: "bold")[Var.]],
      [#text(weight: "bold")[Var. Val]]
    ),
    ..items.map(((it)) => {
      let sku = it.at("sku", default: "")
      let desc = it.at("description", default: "")
      let sys = it.at("system_qty", default: 0)
      let cnt = it.at("counted_qty", default: 0)
      let var_qty = it.at("variance", default: 0)
      let var_val = it.at("variance_value", default: 0.0)
      
      // Color logic for variance
      let var_color = if var_qty < 0 { warning } else if var_qty > 0 { accent } else { black }
      let val_color = if var_val < 0 { warning } else if var_val > 0 { accent } else { black }

      (
        [#text(size: 8pt, font: "Cousine")[#sku]],
        [#desc],
        [#sys],
        [#cnt],
        [#text(fill: var_color, weight: "bold")[#var_qty]],
        [#text(fill: val_color, weight: "bold")[#money(var_val)]]
      )
    }).flatten()
  )
} else {
  align(center, text(fill: gray, style: "italic")[No inventory items recorded for this session.])
}

#v(10pt)

// --- Summary Footer ---
#grid(columns: (1fr, 1fr),
  [
    #set text(size: 8pt, fill: neutral)
    #text(weight: "bold", size: 10pt, fill: black)[Report Summary] \
    #v(2pt)
    #grid(columns: (auto, 1fr), column-gutter: 10pt,
      [Status:], [#if float(g("totals.accuracy_pct", default: 0)) > 99.0 [Verified] else [Discrepancy Found]],
      [Zone:], [#g("count.zone", default: "-")],
      [Warehouse:], [#g("warehouse.name", default: "-")]
    )
  ],
  align(right)[
    #rect(fill: neutral.lighten(90%), stroke: none, inset: 12pt, radius: 4pt)[
      #grid(columns: (auto, auto), column-gutter: 15pt,
        [#text(size: 10pt)[Total Variance Value:]],
        [#text(size: 14pt, weight: "bold", fill: warning)[#money(g("totals.total_variance_value", default: 0))]]
      )
    ]
  ]
)

#v(20pt)
#line(length: 100%, stroke: 0.5pt + gray)
#set align(center)
#text(size: 7pt, fill: gray)[
  End of Inventory Count Report · Confidential · #g("warehouse.name", default: "N/A")
]
