// Bank Account Statement
// @description: Account statement with opening/closing balance and transactions
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

#let accent = rgb("#1f5c3d")
#let txs = data.at("transactions", default: ())
#let opening = float(g("balances.opening", default: 0))

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, left: 2cm, right: 2cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #grid(columns: (1fr, auto),
      [#g("bank.name") is authorised by the Prudential Regulation Authority. Registered office: #g("bank.address")],
      [Statement #g("account.statement_no") · Page 1 of 1])
  ])
#set text(font: "Tinos", size: 9.5pt)

// Header: classic bank serif, double rule
#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left, right),
  [
    #text(size: 17pt, weight: "bold", fill: accent)[#g("bank.name", default: "Bank Statement")]
    #linebreak()
    #text(size: 8pt, fill: gray.darken(40%))[#g("bank.address") · BIC #g("bank.bic")]
  ],
  align(right + horizon)[
    #text(size: 12pt, weight: "bold")[Statement of Account]
  ])
#v(2pt)
#line(length: 100%, stroke: 1.4pt + accent)
#v(1.5pt)
#line(length: 100%, stroke: 0.5pt + accent)
#v(10pt)

#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(weight: "bold")[#g("account.holder")] \
    Account number: #g("account.number") \
    IBAN: #g("account.iban")
  ],
  align(right)[
    #table(columns: 2, stroke: none, align: (left, right), inset: 2pt,
      [Statement no.], [*#g("account.statement_no")*],
      [Statement period], [#g("account.period")])
  ])
#v(10pt)

// Balance summary strip
#block(fill: accent.lighten(90%), stroke: (top: 1pt + accent, bottom: 1pt + accent), inset: 8pt, width: 100%)[
  #grid(columns: (1fr, 1fr), align: (left, right),
    [Opening balance as at start of period: *#money(opening)*],
    [Closing balance as at end of period: *#money(g("balances.closing", default: 0))*])
]
#v(10pt)

#if txs.len() > 0 {
  set text(size: 8.5pt)
  let running = opening
  let rows = ()
  for t in txs {
    let amt = float(t.at("amount", default: 0))
    running = running + amt
    rows.push((
      [#t.at("date", default: "")],
      [#t.at("value_date", default: "")],
      [#t.at("description", default: "") #linebreak() #text(size: 7.5pt, fill: gray.darken(25%))[#t.at("counterparty", default: "")]],
      [#if amt < 0 [#money(calc.abs(amt))] else []],
      [#if amt >= 0 [#money(amt)] else []],
      [#money(running)],
    ))
  }
  table(
    columns: (auto, auto, 1fr, auto, auto, auto),
    align: (left, left, left, right, right, right),
    stroke: (x, y) => (bottom: 0.3pt + gray.lighten(45%)),
    inset: 4.5pt,
    table.header([*Date*], [*Value*], [*Description*], [*Paid out*], [*Paid in*], [*Balance*]),
    table.hline(stroke: 1pt + accent),
    ..rows.flatten(),
    table.hline(stroke: 1pt + accent),
    [], [], [#text(weight: "bold")[Closing balance]], [], [], [#text(weight: "bold")[#money(running)]],
  )
} else {
  text(fill: gray)[No transactions in this period.]
}
#v(10pt)

#text(size: 8pt, fill: gray.darken(30%))[
  Please check your statement carefully and report any discrepancies within 60 days.
  Interest is calculated daily and applied on the last working day of the month.
  Deposits are protected up to £85,000 by the Financial Services Compensation Scheme.
]
