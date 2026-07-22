// Payslip
// @description: Monthly payslip: gross, deductions, net, YTD figures
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

#let teal = rgb("#0e6f6b")
#let paper = rgb("#fbfdfd")
#let gbp(x) = money(x, sym: "£")

#let deds = data.at("deductions", default: ())
#let ded-total = deds.fold(0.0, (acc, d) => acc + float(d.at("amount", default: 0)))

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 1.8cm, x: 2cm), fill: paper,
  footer: [
    #set text(size: 7pt, fill: gray.darken(30%))
    #align(center)[This payslip is generated electronically and is valid without signature. Queries: payroll\@harborview-group.example · Ref #g("employer.payroll_ref")]
  ])
#set text(font: "Arimo", size: 8.5pt)

// Header band
#block(fill: teal, inset: (x: 12pt, y: 9pt), radius: 2pt, width: 100%)[
  #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    [
      #text(fill: white, weight: "bold", size: 13pt)[#g("employer.company", default: "—")] \
      #text(fill: white.transparentize(20%), size: 7.5pt)[#g("employer.address") · #g("employer.payroll_ref")]
    ],
    text(fill: white, weight: "bold", size: 11pt)[PAYSLIP — #g("period.month", default: "—")])
]
#v(8pt)

// Employee strip
#let cell(label, value) = [
  #text(size: 6.5pt, fill: gray.darken(45%))[#upper(label)] \
  #text(size: 8.5pt, weight: "semibold")[#value]
]
#block(stroke: 0.5pt + teal.lighten(40%), inset: 8pt, radius: 2pt, width: 100%)[
  #grid(columns: (1.4fr, 1fr, 1fr, 1.2fr, 1fr, 1fr), row-gutter: 6pt, column-gutter: 8pt,
    cell("Employee", g("employee.name", default: "—")),
    cell("Employee ID", g("employee.id", default: "—")),
    cell("Department", g("employee.department", default: "—")),
    cell("NI Number", g("employee.ni_number", default: "—")),
    cell("Tax Code", g("employee.tax_code", default: "—")),
    cell("Pay Date", g("period.pay_date", default: "—")))
]
#v(10pt)

// Pay / deductions two columns
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  [
    #text(weight: "bold", size: 9pt, fill: teal)[PAYMENTS]
    #v(3pt)
    #table(columns: (1fr, auto), stroke: (x, y) => (bottom: 0.4pt + gray.lighten(40%)),
      inset: 5pt, align: (left, right),
      [Basic salary], [#gbp(g("pay.base_salary", default: 0))],
      [Overtime], [#gbp(g("pay.overtime", default: 0))],
      [Bonus], [#gbp(g("pay.bonus", default: 0))],
      table.cell(fill: teal.lighten(88%))[*Total gross pay*], table.cell(fill: teal.lighten(88%))[*#gbp(g("pay.gross", default: 0))*])
  ],
  [
    #text(weight: "bold", size: 9pt, fill: teal)[DEDUCTIONS]
    #v(3pt)
    #if deds.len() > 0 {
      table(columns: (1fr, auto), stroke: (x, y) => (bottom: 0.4pt + gray.lighten(40%)),
        inset: 5pt, align: (left, right),
        ..deds.map(d => ([#d.at("label", default: "")], [#gbp(d.at("amount", default: 0))])).flatten(),
        table.cell(fill: teal.lighten(88%))[*Total deductions*], table.cell(fill: teal.lighten(88%))[*#gbp(ded-total)*])
    } else {
      text(fill: gray, size: 8pt)[No deductions this period.]
    }
  ])
#v(10pt)

// Net pay banner
#block(fill: teal, inset: (x: 12pt, y: 10pt), radius: 2pt, width: 100%)[
  #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    text(fill: white, size: 9pt)[NET PAY — paid to account ending *#g("employee.bank_last4", default: "····")*],
    text(fill: white, weight: "bold", size: 15pt)[#gbp(g("totals.net", default: 0))])
]
#v(10pt)

// YTD strip
#text(weight: "bold", size: 9pt, fill: teal)[YEAR TO DATE (tax year 2026/27)]
#v(3pt)
#table(columns: (1fr, 1fr, 1fr), inset: 6pt, align: center,
  stroke: 0.5pt + gray.lighten(40%),
  fill: (x, y) => if y == 0 { teal.lighten(88%) } else { white },
  [*Gross YTD*], [*Tax YTD*], [*Net YTD*],
  [#gbp(g("totals.ytd_gross", default: 0))], [#gbp(g("totals.ytd_tax", default: 0))], [#gbp(g("totals.ytd_net", default: 0))])
#v(8pt)
#text(size: 7pt, fill: gray.darken(20%))[Please check this payslip carefully and report any discrepancy to Payroll within 30 days. Pension contributions are made under a net pay arrangement.]
