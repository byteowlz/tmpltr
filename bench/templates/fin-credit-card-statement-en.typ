// Credit Card Statement
// @description: Monthly statement with transactions, interest, minimum payment
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

#let accent = rgb("#3b3f8f")
#let txs = data.at("transactions", default: ())

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 2.2cm, left: 1.8cm, right: 1.8cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [#g("bank.name") · #g("bank.address") · Customer service #g("bank.hotline") (24/7)],
      [Page 1 of 1])
  ])
#set text(font: "Arimo", size: 9pt)

// Header band
#block(fill: accent, inset: (x: 14pt, y: 10pt), radius: 2pt, width: 100%)[
  #grid(columns: (1fr, auto),
    [
      #text(fill: white, size: 15pt, weight: "bold")[#g("bank.name", default: "Credit Card Statement")]
      #linebreak()
      #text(fill: white.transparentize(20%), size: 8pt)[#g("bank.address")]
    ],
    align(right + horizon)[
      #text(fill: white, size: 11pt, weight: "bold")[Account Statement]
      #linebreak()
      #text(fill: white.transparentize(20%), size: 8pt)[Statement date #g("account.statement_date")]
    ])
]
#v(8pt)

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #text(weight: "bold", size: 10pt)[#g("account.holder")] \
    Card ending in *#g("account.card_last4")* \
    Billing period: #g("account.statement_period")
  ],
  align(right)[
    Credit limit: *#money(g("account.credit_limit", default: 0))* \
    Questions? Call #g("bank.hotline")
  ])
#v(8pt)

// Key figures boxes
#grid(columns: (1fr, 1fr, 1fr), column-gutter: 8pt,
  ..(([New Balance], money(g("summary.new_balance", default: 0))),
     ([Minimum Payment Due], money(g("summary.min_payment", default: 0))),
     ([Payment Due Date], g("summary.due_date", default: "—"))).map(((lab, val)) =>
    block(stroke: 0.8pt + accent, radius: 3pt, inset: 8pt, width: 100%)[
      #text(size: 7.5pt, fill: accent, weight: "bold")[#upper(lab)]
      #v(3pt)
      #text(size: 13pt, weight: "bold")[#val]
    ])
)
#v(10pt)

// Account summary
#text(size: 10.5pt, weight: "bold", fill: accent)[Account Summary]
#v(3pt)
#table(columns: (1fr, auto), stroke: (x, y) => (bottom: 0.4pt + gray.lighten(50%)), inset: 4.5pt,
  align: (left, right),
  [Previous balance], [#money(g("summary.previous_balance", default: 0))],
  [Payments and credits], [- #money(g("summary.payments", default: 0))],
  [Purchases and adjustments], [+ #money(g("summary.purchases", default: 0))],
  [Interest charged], [+ #money(g("summary.interest", default: 0))],
  [#text(weight: "bold")[New balance]], [#text(weight: "bold")[#money(g("summary.new_balance", default: 0))]])
#v(10pt)

// Transactions
#text(size: 10.5pt, weight: "bold", fill: accent)[Transaction Detail]
#v(3pt)
#if txs.len() > 0 {
  set text(size: 8.5pt)
  table(
    columns: (auto, 1fr, auto, auto),
    align: (left, left, left, right),
    stroke: none,
    inset: 4pt,
    fill: (_, row) => if row == 0 { accent.lighten(88%) } else { white },
    table.header([*Trans. date*], [*Merchant / description*], [*Location*], [*Amount*]),
    table.hline(stroke: 0.8pt + accent),
    ..txs.map(t => {
      let amt = float(t.at("amount", default: 0))
      ([#t.at("date", default: "")],
       [#t.at("merchant", default: "")],
       [#text(fill: gray.darken(20%))[#t.at("city", default: "")]],
       [#if amt < 0 { text(fill: rgb("#1a7a3c"))[#money(amt)] } else { money(amt) }])
    }).flatten(),
    table.hline(stroke: 0.8pt + accent),
  )
} else {
  text(fill: gray)[No transactions this period.]
}
#v(8pt)

#block(fill: gray.lighten(88%), inset: 8pt, radius: 3pt, width: 100%)[
  #text(size: 7.5pt, fill: gray.darken(40%))[
    *Late Payment Warning:* If we do not receive your minimum payment by the date listed above,
    you may have to pay a late fee of up to \$40.00 and your APRs may be increased up to the Penalty APR of 29.99%.
    *Minimum Payment Warning:* If you make only the minimum payment each period, you will pay more in
    interest and it will take you longer to pay off your balance.
  ]
]
