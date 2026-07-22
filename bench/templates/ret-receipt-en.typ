// Store Receipt
// @description: POS thermal receipt with items, tax split, payment, loyalty
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

#let items = data.at("items", default: ())

#set page(width: 80mm, height: auto, margin: (x: 5mm, top: 7mm, bottom: 9mm))
#set text(font: "Cousine", size: 8pt)
#set par(leading: 0.45em)

#let sep = block(above: 5pt, below: 5pt, width: 100%, height: 1em, clip: true)[#("-" * 80)]

// Centered store header
#align(center)[
  #text(size: 12.5pt, weight: "bold")[#upper(str(g("store.name", default: "STORE")))]
  #v(1pt)
  #text(size: 7.5pt)[
    #g("store.address") \
    #g("store.city") \
    Tel: #g("store.phone") \
    Tax ID: #g("store.vat_id") #h(5pt) Store \##g("store.store_no")
  ]
]

#sep

#grid(columns: (1fr, auto), column-gutter: 3pt,
  [#g("receipt.date") #h(4pt) #g("receipt.time")],
  align(right)[REG #g("receipt.register") #h(3pt) CASHIER: #g("receipt.cashier")])
RECEIPT \##g("receipt.number")

#sep

// Line items
#if items.len() > 0 {
  for it in items {
    let qty = float(it.at("qty", default: 1))
    let up = float(it.at("unit_price", default: 0))
    let tc = str(it.at("tax_class", default: ""))
    grid(columns: (1fr, auto), column-gutter: 3pt,
      [#upper(str(it.at("name", default: "")))],
      align(right)[#money(qty * up, sym: "") #tc])
    if qty > 1 {
      text(size: 7pt)[#h(8pt)#str(int(qty)) \@ #money(up, sym: "")]
      linebreak()
    }
  }
} else [
  #text(size: 7.5pt)[\*\* NO ITEMS \*\*]
]

#sep

#grid(columns: (1fr, auto), row-gutter: 3.5pt, column-gutter: 3pt,
  [SUBTOTAL], align(right)[#money(g("totals.subtotal", default: 0), sym: "")],
  [TAX], align(right)[#money(g("totals.tax", default: 0), sym: "")],
  [#text(size: 10.5pt, weight: "bold")[TOTAL]],
  align(right)[#text(size: 10.5pt, weight: "bold")[#money(g("totals.total", default: 0))]])

#v(3pt)
#grid(columns: (1fr, auto), row-gutter: 3.5pt, column-gutter: 3pt,
  [#g("totals.payment_method", default: "CASH") #if g("totals.card_last4") != "" [\*\*\*\*#g("totals.card_last4")]],
  align(right)[#money(g("totals.total", default: 0), sym: "")],
  [CHANGE], align(right)[#money(g("totals.change", default: 0), sym: "")])

#text(size: 7pt)[F = Food (exempt) #h(6pt) T = Taxable 7.25%]

#sep

// Loyalty
#align(center)[
  #text(size: 7.5pt)[
    MEMBER: #g("loyalty.member_no", default: "-") \
    POINTS EARNED TODAY: #g("loyalty.points_earned", default: 0) \
    POINTS BALANCE: #g("loyalty.points_balance", default: 0)
  ]
]

#sep

#align(center)[
  #text(size: 11pt)[#("|" + "||" + " | | " + "|||" + " || | " + "||" + " ||| | " + "||" + " | " + "|||" + " || | " + "||" + " |")]
  #v(1pt)
  #text(size: 7pt)[#g("receipt.number")]
  #v(3pt)
  #text(size: 8.5pt, weight: "bold")[THANK YOU FOR SHOPPING WITH US!] \
  #text(size: 7pt)[Returns within 30 days with receipt.]
]
