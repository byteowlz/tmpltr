// Tuition Invoice
// @description: Semester fees breakdown with due date and payment info
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

#let accent = rgb("#1e5c37")
#let cur = g("invoice.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }
#let items = data.at("items", default: ())
#let total = items.fold(0.0, (acc, it) => acc + float(it.at("amount", default: 0)))

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.4cm, left: 2.2cm, right: 2.2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #align(center)[#g("institution.name") · #g("institution.address") · Bursar: #g("institution.bursar_email")]
  ])
#set text(font: "Tinos", size: 10pt)

// Centered collegiate header
#align(center)[
  #text(size: 18pt, weight: "bold", fill: accent)[#g("institution.name")] \
  #text(size: 9pt)[#g("institution.address")] \
  #v(3pt)
  #text(size: 10.5pt, tracking: 3pt, fill: accent.darken(10%))[OFFICE OF THE BURSAR]
]
#v(3pt)
#line(length: 100%, stroke: 1.2pt + accent)
#line(length: 100%, stroke: 0.4pt + accent)
#v(12pt)

#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  [
    #text(size: 8pt, fill: gray.darken(40%), tracking: 1pt)[BILLED TO] \
    #v(2pt)
    #text(weight: "bold", size: 11pt)[#g("student.name")] \
    Student ID: #g("student.id") \
    #g("student.program")
  ],
  align(right)[
    #text(size: 15pt, weight: "bold", fill: accent)[Statement of Account] \
    #v(4pt)
    #table(columns: 2, stroke: none, align: (left, right), inset: 2.5pt,
      [Invoice no.], [*#g("invoice.number")*],
      [Statement date], [#g("invoice.date")],
      [Term], [*#g("invoice.term")*],
      [Payment due], [#text(fill: rgb("#8b1a1a"), weight: "bold")[#g("invoice.due_date")]])
  ])
#v(14pt)

#if items.len() > 0 {
  table(
    columns: (1fr, auto),
    align: (left, right),
    stroke: (x, y) => (bottom: 0.4pt + gray.lighten(40%)),
    inset: (x: 8pt, y: 6pt),
    table.header(
      table.cell(fill: accent, text(fill: white, weight: "bold", size: 9pt)[CHARGES AND CREDITS — #upper(g("invoice.term", default: "CURRENT TERM"))]),
      table.cell(fill: accent, align(right, text(fill: white, weight: "bold", size: 9pt)[AMOUNT]))),
    ..items.map(it => {
      let amt = float(it.at("amount", default: 0))
      (
        [#it.at("description", default: "")],
        [#text(fill: if amt < 0 { accent } else { black })[#money(amt, sym: sym)]],
      )
    }).flatten()
  )
} else {
  text(fill: gray, style: "italic")[No charges posted for this term.]
}
#v(4pt)
#align(right)[
  #box(fill: accent.lighten(90%), inset: (x: 12pt, y: 8pt))[
    #text(size: 11pt)[Balance due by #text(weight: "bold")[#g("invoice.due_date", default: "the due date")]:]
    #h(10pt)
    #text(size: 13pt, weight: "bold", fill: accent)[#money(total, sym: sym)]
  ]
]
#v(16pt)

#text(size: 10.5pt, weight: "bold", fill: accent)[Payment instructions]
#v(4pt)
#table(columns: (auto, 1fr), stroke: none, inset: (x: 6pt, y: 3pt),
  [#text(size: 9pt, weight: "bold")[Method]], [#text(size: 9pt)[#g("payment.method")]],
  [#text(size: 9pt, weight: "bold")[Bank]], [#text(size: 9pt)[#g("payment.account")]],
  [#text(size: 9pt, weight: "bold")[Reference]], [#text(size: 9pt)[#g("payment.reference")]])
#v(10pt)
#text(size: 8.5pt, fill: gray.darken(30%))[
  A late fee of 1.5% per month applies to balances outstanding after the due date.
  Registration for the following term is blocked while a balance remains unpaid.
  Questions: #g("institution.bursar_email", default: "the Bursar's Office").
]
