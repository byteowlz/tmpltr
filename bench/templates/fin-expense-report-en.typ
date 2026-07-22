// Travel Expense Report
// @description: Employee expense claim with receipts, categories, approval
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

#let accent = rgb("#2e7d32") // Forest green for corporate expense feel
#let cur = g("currency", default: "GBP")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#let expenses = data.at("expenses", default: ())
#let total_amount = expenses.fold(0.0, (acc, it) => acc + float(it.at("amount", default: 0)))

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 1.5cm, right: 1.5cm),
  header: [
    #set text(size: 9pt, fill: gray.darken(50%))
    #grid(columns: (1fr, 1fr),
      [Expense Report: #g("trip.project_code", default: "—")],
      align(right)[#g("employee.id", default: "—")]
    )
    #line(length: 100%, stroke: 0.5pt + gray)
  ],
  footer: [
    #set text(size: 8pt, fill: gray)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [Generated for #g("employee.name")],
      align(right)[Confidential - Internal Use Only]
    )
  ]
)

#set text(font: "Tinos", size: 10pt)

// Title Section
#align(center)[
  #text(size: 22pt, weight: "bold", fill: accent)[TRAVEL EXPENSE REPORT]
  #v(4pt)
  #text(size: 11pt, style: "italic", fill: gray.darken(40%))[Official Reimbursement Claim]
]

#v(15pt)

// Employee & Trip Info Grid
#grid(
  columns: (1fr, 1fr),
  column-gutter: 30pt,
  stroke: none,
  // Employee Block
  rect(width: 100%, stroke: 0.5pt + gray.lighten(50%), inset: 10pt)[
    #text(weight: "bold", size: 11pt, fill: accent)[EMPLOYEE DETAILS]
    #v(4pt)
    #set text(size: 9pt)
    *Name:* #g("employee.name") \
    *Dept:* #g("employee.department") \
    *Cost Center:* #g("employee.cost_center") \
    *Bank IBAN:* #g("employee.iban")
  ],
  // Trip Block
  rect(width: 100%, stroke: 0.5pt + gray.lighten(50%), inset: 10pt)[
    #text(weight: "bold", size: 11pt, fill: accent)[TRIP DETAILS]
    #v(4pt)
    #set text(size: 9pt)
    *Purpose:* #g("trip.purpose") \
    *Destination:* #g("trip.destination") \
    *Period:* #g("trip.start_date") to #g("trip.end_date") \
    *Project:* #g("trip.project_code")
  ]
)

#v(20pt)

// Expenses Table
#text(weight: "bold", size: 12pt)[Expense Itemization]
#v(5pt)

#table(
  columns: (auto, 1fr, 1fr, auto, auto),
  stroke: none,
  inset: 7pt,
  fill: (x, y) => if y == 0 { accent.lighten(90%) } else if calc.even(y) { white } else { gray.lighten(95%) },
  table.header(
    [#text(weight: "bold")[Date]],
    [#text(weight: "bold")[Category]],
    [#text(weight: "bold")[Description]],
    [#text(weight: "bold")[Ref]],
    [#text(weight: "bold")[Amount]],
  ),
  ..expenses.map(it => (
    [#it.at("date", default: "")],
    [#it.at("category", default: "")],
    [#it.at("description", default: "")],
    [#it.at("receipt_no", default: "—")],
    [#money(it.at("amount", default: 0), sym: sym)],
  )).flatten()
)

#v(10pt)

// Total
#align(right)[
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 4pt,
    [#text(size: 11pt)[Total Reimbursement Due:]],
    [#text(size: 14pt, weight: "bold", fill: accent)[#money(total_amount, sym: sym)]]
  )
]

#v(30pt)

// Approval Section
#grid(
  columns: (1fr, 1fr),
  stroke: none,
  [
    #text(weight: "bold", size: 10pt)[SUBMISSION] \
    #v(10pt)
    #line(length: 80%, stroke: 0.5pt + black) \
    #text(size: 8pt, fill: gray)[Employee Signature]
  ],
  [
    #text(weight: "bold", size: 10pt)[APPROVAL STATUS: #g("approval.status", default: "Pending")] \
    #v(4pt)
    #text(size: 9pt)[
      *Manager:* #g("approval.manager", default: "—") \
      *Date:* #g("approval.date", default: "—")
    ]
    #v(6pt)
    #line(length: 80%, stroke: 0.5pt + black) \
    #text(size: 8pt, fill: gray)[Authorized Signature]
  ]
)

#v(20pt)
#set text(size: 8pt, fill: gray.darken(50%))
#block(width: 100%, stroke: 0.5pt + gray, inset: 8pt, radius: 2pt)[
  *Note:* All claims must be accompanied by valid digital receipts. 
  Discrepancies in project codes or cost centers may result in processing delays.
]
