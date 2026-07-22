// Brokerage Account Statement
// @description: Portfolio positions, market values, period performance
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

#let accent = rgb("#2c3e50")
#let secondary = rgb("#7f8c8d")
#let positive = rgb("#27ae60")
#let negative = rgb("#c0392b")
#let cur = g("account.base_currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 2cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  footer: context {
    set text(size: 8pt, fill: secondary)
    grid(columns: (1fr, 1fr),
      [#g("broker.name", default: "Meridian Securities LLC")],
      align(right)[Page #counter(page).display()]
    )
  }
)

#set text(font: "Libertinus Serif", size: 10pt)

// Header: Professional Statement Layout
#grid(columns: (1fr, auto),
  [
    #text(size: 22pt, weight: "bold", fill: accent)[Account Statement] \
    #text(size: 10pt, fill: secondary)[Reporting Period: #g("account.period", default: "N/A")]
  ],
  align(right)[
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 12pt)[
        #let bname = g("broker.name", default: "MS")
        #let b_clusters = bname.clusters()
        #upper(b_clusters.slice(0, calc.min(3, b_clusters.len())).join(""))
      ]
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 0.5pt + accent)
#v(10pt)

// Client & Account Info
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #text(size: 8pt, weight: "bold", fill: secondary, tracking: 1pt)[ACCOUNT HOLDER] \
    #text(size: 11pt, weight: "bold")[#g("account.holder", default: "Valued Client")] \
    #g("account.number", default: "—")
  ],
  [
    #text(size: 8pt, weight: "bold", fill: secondary, tracking: 1pt)[BROKER INFORMATION] \
    #g("broker.name", default: "") \
    #text(size: 9pt)[#g("broker.address", default: "") \ #g("broker.contact", default: "")]
  ]
)

#v(20pt)

// Summary Dashboard
#rect(width: 100%, stroke: 0.5pt + gray.lighten(50%), radius: 4pt, fill: gray.lighten(96%))[
  #set text(font: "Adwaita Sans", size: 9pt)
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt, inset: 15pt,
    [
      #text(fill: secondary, weight: "bold")[TOTAL MARKET VALUE] \
      #text(size: 16pt, weight: "bold", fill: accent)[#money(float(g("summary.total_value", default: 0)), sym: sym)]
    ],
    [
      #text(fill: secondary, weight: "bold")[CASH BALANCE] \
      #text(size: 16pt, weight: "bold")[#money(float(g("summary.cash_balance", default: 0)), sym: sym)]
    ],
    [
      #text(fill: secondary, weight: "bold")[PERIOD CHANGE] \
      #let pct = float(g("summary.period_change_pct", default: 0))
      #text(size: 16pt, weight: "bold", fill: if pct >= 0 { positive } else { negative })[
        #if pct > 0 { "+" + str(pct) + "%" } else { str(pct) + "%" }
      ]
    ]
  )
]

#v(20pt)

// Positions Table
#text(font: "Adwaita Sans", size: 10pt, weight: "bold", fill: accent)[Holdings & Positions]
#v(5pt)

#let positions = data.at("positions", default: ())

#if positions.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto, auto),
    align: (left, left, right, right, right, right),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      [#set text(size: 8pt, fill: secondary); SYMBOL],
      [#set text(size: 8pt, fill: secondary); DESCRIPTION],
      [#set text(size: 8pt, fill: secondary); QTY],
      [#set text(size: 8pt, fill: secondary); PRICE],
      [#set text(size: 8pt, fill: secondary); MARKET VALUE],
      [#set text(size: 8pt, fill: secondary); GAIN/LOSS %],
    ),
    ..positions.map(((it)) => (
      [#text(weight: "bold")[#it.at("symbol", default: "—")]],
      [#it.at("name", default: "")],
      [#it.at("quantity", default: 0)],
      [#money(float(it.at("price", default: 0)), sym: sym)],
      [#money(float(it.at("market_value", default: 0)), sym: sym)],
      [
        #let g_pct = float(it.at("gain_pct", default: 0))
        #text(fill: if g_pct >= 0 { positive } else { negative }, weight: "bold")[
          #if g_pct > 0 { "+" + str(g_pct) + "%" } else { str(g_pct) + "%" }
        ]
      ]
    )).flatten()
  )
} else {
  align(center, text(fill: secondary, style: "italic")[No positions held during this period.])
}

#v(30pt)

// Footer Disclaimer
#set text(size: 7pt, fill: secondary)
#line(length: 100%, stroke: 0.25pt + gray)
#v(5pt)
[
  *Disclaimer:* This statement is for informational purposes only and does not constitute an offer to sell or a solicitation of an offer to buy any security. Market values are based on closing prices as of the end of the reporting period. Past performance is not indicative of future results. Meridian Securities LLC is a member of SIPC.
]
