// Job Offer Letter
// @description: Formal offer with role, compensation package, start date, acceptance deadline
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

#let coral = rgb("#e8552f")
#let slate = rgb("#2f3542")
#let cur = g("offer.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.2cm, x: 2.4cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #grid(columns: (1fr, auto),
      [#g("company.name") · #g("company.address") · #g("company.city")],
      [Confidential])
  ])
#set text(font: "Adwaita Sans", size: 10pt, fill: slate)
#set par(justify: true)

// Modern header: wordmark + coral bar
#grid(columns: (auto, 1fr), align: (left + horizon, right + horizon),
  [
    #text(size: 20pt, weight: "bold", fill: slate)[lumen#text(fill: coral)[grid]]
  ],
  align(right)[
    #text(size: 8.5pt, fill: gray.darken(30%))[#g("company.address") \ #g("company.city")]
  ])
#v(4pt)
#rect(width: 100%, height: 3pt, fill: gradient.linear(coral, coral.lighten(55%)))
#v(16pt)

#g("candidate.name", default: "—") \
#g("candidate.address") \
#g("candidate.city")
#v(10pt)
#text(fill: gray.darken(30%), size: 9pt)[July 18, 2026]
#v(12pt)

#text(size: 14pt, weight: "bold")[Your offer from #g("company.name", default: "us")]
#v(8pt)

Dear #g("candidate.name", default: "candidate"),

We are delighted to offer you the position of *#g("offer.position", default: "—")* on
our #g("offer.department", default: "—") team, reporting to
#g("offer.manager", default: "your hiring manager"). We were impressed by your
portfolio and your systems-thinking during the interview loop, and we think you will
have an outsized impact here. The key terms of our offer are summarized below.

#v(8pt)
#block(fill: coral.lighten(93%), stroke: (left: 3pt + coral), inset: 12pt, radius: 2pt, width: 100%)[
  #grid(columns: (auto, 1fr), row-gutter: 7pt, column-gutter: 16pt,
    text(weight: "bold", size: 9pt)[Start date], [#g("offer.start_date", default: "—")],
    text(weight: "bold", size: 9pt)[Base salary], [*#money(g("offer.salary_annual", default: 0), sym: sym)* per year (#cur)],
    text(weight: "bold", size: 9pt)[Target bonus], [#g("offer.bonus_pct", default: "—")% of annual base salary],
    text(weight: "bold", size: 9pt)[Equity], [#g("offer.equity", default: "—")],
    text(weight: "bold", size: 9pt)[Time off], [#g("offer.vacation_days", default: "—") days PTO plus company holidays],
  )
]
#v(8pt)

You will also be eligible for our standard benefits package, including medical, dental
and vision coverage, a 401(k) with 4% match, and a \$1,500 annual learning budget.
This offer is contingent on proof of your eligibility to work in the United States
and successful completion of a standard background check. Your employment will be
at-will, as described in the enclosed employment agreement.

#v(6pt)
Please indicate your acceptance by signing below and returning this letter no later
than *#g("offer.acceptance_deadline", default: "—")*. If you have any questions,
reach out to #g("company.hr_contact", default: "our People team") at
#g("company.email", default: "—") at any time — we are happy to help.

#v(10pt)
We can't wait to build with you.

#v(14pt)
#grid(columns: (1fr, 1fr), column-gutter: 2cm,
  [
    Warm regards,
    #v(24pt)
    #line(length: 85%, stroke: 0.7pt + slate)
    #text(size: 9pt)[#g("company.hr_contact", default: "—") \ #g("company.name")]
  ],
  [
    Accepted and agreed:
    #v(24pt)
    #line(length: 85%, stroke: 0.7pt + slate)
    #text(size: 9pt)[#g("candidate.name", default: "—") #h(1fr) Date: #box(width: 60pt, repeat[.])]
  ])
