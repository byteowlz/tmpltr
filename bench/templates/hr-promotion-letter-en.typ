// Promotion Letter
// @description: Promotion notice with new title, salary, effective date
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

#let burgundy = rgb("#6e1f2e")
#let cur = g("promotion.currency", default: "GBP")
#let sym = if cur == "USD" { "$" } else if cur == "EUR" { "€" } else { "£" }

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.4cm, x: 2.6cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(25%))
    #align(center)[#g("company.name") · #g("company.address") · Strictly private & confidential]
  ])
#set text(font: "Libertinus Serif", size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.68em, spacing: 0.95em)

// Letterhead: name left, rule in accent
#grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
  [
    #text(size: 16pt, weight: "bold", fill: burgundy, tracking: 0.4pt)[#g("company.name", default: "—")]
  ],
  text(size: 8.5pt, fill: gray.darken(40%))[#g("company.address")])
#v(3pt)
#line(length: 100%, stroke: 1.6pt + burgundy)
#v(0.5pt)
#line(length: 100%, stroke: 0.5pt + burgundy.lighten(40%))
#v(20pt)

#text(size: 9pt, fill: gray.darken(35%))[PRIVATE & CONFIDENTIAL]
#v(4pt)
#g("employee.name", default: "—") \
#if g("employee.id") != "" [Employee ID: #g("employee.id") \ ]
#if g("employee.current_title") != "" [#g("employee.current_title")]
#v(10pt)
#align(right)[#g("promotion.effective_date", default: "—")]
#v(10pt)

#text(weight: "bold", size: 11.5pt)[Re: Promotion to #g("promotion.new_title", default: "—")]
#v(8pt)

Dear #g("employee.name", default: "colleague"),

I am delighted to confirm your promotion to *#g("promotion.new_title", default: "—")*#if g("promotion.new_department") != "" [ within #g("promotion.new_department")], effective *#g("promotion.effective_date", default: "—")*.

#if g("promotion.rationale") != "" [
  This promotion recognises #g("promotion.rationale"). Your contribution has
  been noted at the most senior levels of the firm, and we are confident you
  will continue to excel in your expanded role.
]

// Terms summary box
#block(stroke: (left: 2.5pt + burgundy), fill: burgundy.lighten(94%), inset: 12pt, width: 100%)[
  #text(size: 8pt, fill: burgundy, tracking: 1pt, weight: "bold")[REVISED TERMS OF EMPLOYMENT]
  #v(6pt)
  #set text(size: 9.5pt)
  #grid(columns: (auto, 1fr), column-gutter: 16pt, row-gutter: 6pt,
    text(fill: gray.darken(45%))[New title], text(weight: "semibold")[#g("promotion.new_title", default: "—")],
    text(fill: gray.darken(45%))[Department], text(weight: "semibold")[#g("promotion.new_department", default: "—")],
    text(fill: gray.darken(45%))[Annual salary], text(weight: "semibold")[#money(g("promotion.new_salary", default: 0), sym: sym) per annum (#cur)],
    text(fill: gray.darken(45%))[Reporting to], text(weight: "semibold")[#g("promotion.new_manager", default: "—")],
    text(fill: gray.darken(45%))[Effective date], text(weight: "semibold")[#g("promotion.effective_date", default: "—")])
]
#v(4pt)

All other terms and conditions of your employment remain unchanged. This
letter should be read alongside your existing contract of employment and
kept with your personnel records.

Please sign and return the enclosed copy of this letter to Human Resources
within ten working days. If you have any questions, please contact
#g("company.hr_contact", default: "your HR Business Partner").

Congratulations on this well-deserved achievement.

#v(14pt)
Yours sincerely,
#v(26pt)
#line(length: 5.6cm, stroke: 0.5pt + black)
#v(-3pt)
#g("company.hr_contact", default: "Human Resources") \
#text(size: 9pt, fill: gray.darken(40%))[#g("company.name")]

#v(20pt)
#line(length: 100%, stroke: (dash: "dashed", paint: gray, thickness: 0.5pt))
#v(6pt)
#text(size: 9pt)[I acknowledge and accept the revised terms set out above.]
#v(18pt)
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [#line(length: 100%, stroke: 0.5pt + black) #text(size: 8pt, fill: gray.darken(35%))[Signature — #g("employee.name", default: "Employee")]],
  [#line(length: 100%, stroke: 0.5pt + black) #text(size: 8pt, fill: gray.darken(35%))[Date]])
