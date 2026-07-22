// Electricity Supply Contract Confirmation
// @description: Tariff confirmation with prices, term, cancellation
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

#let teal = rgb("#0e6e6e")
#let pale = rgb("#e7f3f3")
#let ppk = float(g("contract.price_per_kwh", default: 0))

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.4cm, x: 2.2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray.lighten(30%))
    #v(2pt)
    #g("supplier.name") · #g("supplier.address")
    #h(1fr) Customer services #g("supplier.hotline") · Page 1 of 1
  ])
#set text(font: "Adwaita Sans", size: 10pt)

// Header: logo right
#grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
  [
    #text(size: 8.5pt, fill: gray.darken(40%))[
      #g("supplier.name", default: "Energy supplier") \
      #g("supplier.address")
    ]
  ],
  box(fill: teal, radius: 4pt, inset: (x: 12pt, y: 8pt))[
    #text(fill: white, weight: "bold", size: 15pt)[#upper({
      let nm = g("supplier.name", default: "EN")
      let cl = nm.clusters()
      cl.slice(0, calc.min(2, cl.len())).join("")
    })]
  ])
#v(4pt)
#line(length: 100%, stroke: 2.5pt + teal)
#v(14pt)

// Address + reference
#grid(columns: (1fr, auto), column-gutter: 20pt,
  [
    #g("customer.name", default: "—") \
    #g("customer.address")
  ],
  align(right)[
    #set text(size: 9pt)
    Customer number: *#g("customer.customer_no", default: "—")* \
    Date: #g("contract.start_date", default: "—")
  ])
#v(16pt)

#text(size: 15pt, weight: "bold", fill: teal)[Welcome — your electricity supply is confirmed]
#v(6pt)

Dear #g("customer.name", default: "customer"),

Thank you for choosing #g("supplier.name", default: "us"). This letter confirms your
new electricity supply contract. Your switch from
*#g("contract.previous_supplier", default: "your previous supplier")* has been
arranged for you — there is nothing further you need to do, and your supply will
not be interrupted.
#v(10pt)

// Tariff card
#box(width: 100%, stroke: 1pt + teal.lighten(30%), radius: 5pt, clip: true)[
  #box(width: 100%, fill: teal, inset: (x: 12pt, y: 7pt))[
    #text(fill: white, weight: "bold", size: 10pt)[YOUR TARIFF: #upper(g("contract.tariff", default: "—"))]
  ]
  #table(columns: (1fr, auto), stroke: (_, y) => (bottom: 0.5pt + gray.lighten(50%)),
    inset: (x: 12pt, y: 6.5pt), align: (left, right),
    [Supply start date], [*#g("contract.start_date", default: "—")*],
    [Contract term], [*#g("contract.term_months", default: "—") months*],
    [Unit rate], [*#money(ppk, sym: "£") per kWh*],
    [Standing charge], [*#money(g("contract.standing_charge_month", default: 0), sym: "£") per month*],
    [Estimated annual consumption], [#g("contract.est_annual_kwh", default: "—") kWh])
  #box(width: 100%, fill: pale, inset: (x: 12pt, y: 9pt))[
    #text(size: 10pt)[Estimated annual cost]
    #h(1fr)
    #text(size: 15pt, weight: "bold", fill: teal)[#money(g("contract.est_annual_cost", default: 0), sym: "£")]
  ]
]
#v(4pt)
#text(size: 8pt, fill: gray.darken(30%))[
  The estimate assumes your projected usage of #g("contract.est_annual_kwh", default: "—") kWh
  per year and includes VAT at 5%. Your actual bills will depend on the electricity you use.
]
#v(12pt)

#text(weight: "bold", size: 11pt)[Your right to cancel]
#v(3pt)
#text(size: 9.5pt)[
  You may cancel this contract without charge within 14 days of receiving this
  letter. After that, the contract runs for the agreed term; to switch or end
  your supply at the end of the term, give us at least
  *#g("contract.cancellation_notice_weeks", default: "—") weeks'* notice. No exit
  fee applies in the last 49 days of the fixed period.
]
#v(12pt)

#text(size: 9.5pt)[
  If anything in this letter is not right, or you have any questions, call our
  customer services team on *#g("supplier.hotline", default: "—")* (Mon–Fri, 8am–6pm).
]
#v(14pt)

Yours sincerely, \
#v(8pt)
#text(style: "italic", size: 12pt)[Customer Operations Team] \
#text(size: 9pt, fill: gray.darken(30%))[#g("supplier.name")]
