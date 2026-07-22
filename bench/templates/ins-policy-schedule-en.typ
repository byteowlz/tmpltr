// Insurance Policy Schedule
// @description: Policy summary: coverages, limits, premiums, period
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

#let accent = rgb("#1f5c45")
#let cur = g("currency", default: "GBP")
#let sym = if cur == "EUR" { "€" } else if cur == "USD" { "$" } else if cur == "GBP" { "£" } else { cur + " " }

#let coverages = data.at("coverages", default: ())

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, x: 2.1cm),
  footer: [
    #set text(size: 7pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + accent)
    #v(2pt)
    #grid(columns: (1fr, auto), column-gutter: 10pt,
      [#g("insurer.name") · #g("insurer.address") · #g("insurer.phone") · #g("insurer.email")],
      [Page 1 of 1])
  ])
#set text(font: "Libertinus Serif", size: 10pt)

// Centered letterhead
#align(center)[
  #text(size: 17pt, weight: "bold", fill: accent)[#smallcaps(g("insurer.name", default: "Insurer"))]\
  #text(size: 8.5pt, fill: gray.darken(50%))[#g("insurer.address") · Tel. #g("insurer.phone") · #g("insurer.email")]
]
#v(4pt)
#line(length: 100%, stroke: 1.2pt + accent)
#line(length: 100%, stroke: 0.4pt + accent)
#v(10pt)

#grid(columns: (1fr, auto), column-gutter: 16pt,
  [
    #text(size: 20pt, weight: "bold")[Policy Schedule]\
    #v(2pt)
    #text(size: 9.5pt, style: "italic", fill: gray.darken(40%))[#g("policy.product", default: "—")]
  ],
  align(right)[
    #box(stroke: 0.8pt + accent, inset: 8pt, radius: 2pt)[
      #text(size: 8pt, fill: gray.darken(40%))[POLICY NUMBER]\
      #text(size: 12pt, weight: "bold", fill: accent)[#g("policy.number", default: "—")]
    ]
  ])
#v(12pt)

// Policyholder + policy details
#let lbl(t) = text(size: 7.5pt, fill: gray.darken(40%), tracking: 0.5pt)[#upper(t)]
#grid(columns: (1fr, 1.2fr), column-gutter: 22pt,
  [
    #lbl("The Insured")
    #v(3pt)
    #text(weight: "bold", size: 10.5pt)[#g("policyholder.name")]\
    #g("policyholder.address")\
    #g("policyholder.city")
    #v(3pt)
    #text(size: 9pt)[Date of birth: #g("policyholder.dob", default: "—")]
  ],
  [
    #lbl("Period of Insurance and Payment")
    #v(3pt)
    #table(columns: (auto, 1fr), stroke: none, inset: (x: 4pt, y: 3pt),
      [#text(size: 9pt, fill: gray.darken(30%))[Effective from]], [*#g("policy.start", default: "—")*],
      [#text(size: 9pt, fill: gray.darken(30%))[Expires on]], [*#g("policy.end", default: "—")*],
      [#text(size: 9pt, fill: gray.darken(30%))[Payment]], [#g("policy.payment_frequency", default: "—")])
  ])
#v(14pt)

// Coverage table
#lbl("Schedule of Coverages")
#v(4pt)
#if coverages.len() > 0 {
  table(
    columns: (1fr, auto, auto, auto),
    align: (left, right, right, right),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + accent) } else { (bottom: 0.4pt + gray.lighten(30%)) },
    inset: (x: 8pt, y: 6pt),
    table.header(
      [#text(size: 8.5pt, weight: "bold", fill: accent)[COVERAGE]],
      [#text(size: 8.5pt, weight: "bold", fill: accent)[LIMIT (#sym)]],
      [#text(size: 8.5pt, weight: "bold", fill: accent)[EXCESS (#sym)]],
      [#text(size: 8.5pt, weight: "bold", fill: accent)[PREMIUM]]),
    ..coverages.map(cv => (
      [#cv.at("coverage", default: "")],
      [#cv.at("limit", default: "—")],
      [#cv.at("deductible", default: "—")],
      [#money(cv.at("premium", default: 0), sym: sym)],
    )).flatten()
  )
} else {
  text(fill: gray, size: 9pt)[No coverages listed.]
}
#v(4pt)
#align(right)[
  #box(fill: accent.lighten(92%), inset: (x: 10pt, y: 7pt), radius: 2pt)[
    #text(size: 9pt)[Total premium (#g("policy.payment_frequency", default: "per period")):]
    #h(8pt)
    #text(size: 12.5pt, weight: "bold", fill: accent)[#money(g("total_premium", default: 0), sym: sym)]
  ]
]
#v(16pt)

// Small print
#text(size: 8pt, fill: gray.darken(45%))[
  This schedule forms part of your policy together with the policy wording and any
  endorsements. Limits and excesses are shown per claim unless stated otherwise.
  Please check the details above and contact us within 14 days if anything is
  incorrect. Insurance Premium Tax is included where applicable.
]
#v(18pt)
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 8pt, fill: gray.darken(40%))[Authorised signatory, #g("insurer.name")]
  ],
  [
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 8pt, fill: gray.darken(40%))[Date of issue]
  ])
