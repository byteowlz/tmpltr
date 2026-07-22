// Policy Renewal Notice
// @description: Renewal terms with premium change and action deadline
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

#let amber = rgb("#b45309")
#let ink = rgb("#292524")
#let changes = get(data, "renewal.changes", default: ())

#set page(paper: "a4", margin: (top: 1.7cm, bottom: 2.2cm, x: 2.1cm),
  footer: [
    #set text(size: 6.8pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + amber)
    #v(2pt)
    #g("insurer.name") is authorised by the Prudential Regulation Authority and
    regulated by the Financial Conduct Authority and the Prudential Regulation
    Authority (FRN 480223). Registered office: #g("insurer.address").
  ])
#set text(font: "Adwaita Sans", size: 10pt, fill: ink)

// Header band: logo-left
#let iname = g("insurer.name", default: "··")
#let ini = upper(iname.clusters().slice(0, calc.min(2, iname.clusters().len())).join(""))
#grid(columns: (auto, 1fr, auto), column-gutter: 10pt, align: (horizon, horizon, top),
  box(fill: gradient.linear(amber, amber.darken(25%)), inset: 9pt, radius: 4pt)[
    #text(fill: white, weight: "bold", size: 15pt)[#ini]
  ],
  [
    #text(weight: "bold", size: 13pt)[#g("insurer.name", default: "Insurer")]\
    #text(size: 8pt, fill: gray.darken(35%))[#g("insurer.address") · #g("insurer.phone")]
  ],
  align(right)[
    #text(size: 8pt, fill: gray.darken(35%))[Policy no.]\
    #text(size: 10.5pt, weight: "bold", fill: amber)[#g("renewal.policy_no", default: "—")]
  ])
#v(6pt)
#line(length: 100%, stroke: 2.5pt + amber)
#v(14pt)

// Address + date
#grid(columns: (1fr, auto), column-gutter: 20pt,
  [
    #g("policyholder.name")\
    #g("policyholder.address")\
    #g("policyholder.city")
  ],
  align(right + top)[
    #text(size: 9pt, fill: gray.darken(30%))[Issued 21 days before renewal]
  ])
#v(16pt)

#text(size: 14.5pt, weight: "bold")[Your insurance is due for renewal on #text(fill: amber)[#g("renewal.renewal_date", default: "—")]]
#v(2pt)
#text(size: 10pt, fill: gray.darken(30%))[#g("renewal.product", default: "—")]
#v(12pt)

Dear #g("policyholder.name", default: "Customer"),

Thank you for insuring with us. Your current policy ends soon, and this notice
sets out your renewal terms. *If you are happy with them, you don't need to do
anything* — your cover will renew automatically and your usual payment method
will be charged.

#v(8pt)
// Premium comparison panel
#block(stroke: 1pt + amber.lighten(40%), radius: 4pt, inset: 0pt, width: 100%)[
  #grid(columns: (1fr, auto, 1fr, 1.2fr), align: (center + horizon,) * 4,
    inset: (x: 10pt, y: 10pt),
    [
      #text(size: 8pt, fill: gray.darken(35%))[CURRENT ANNUAL PREMIUM]\
      #v(2pt)
      #text(size: 15pt, weight: "bold", fill: gray.darken(20%))[#money(g("renewal.current_premium", default: 0), sym: "£")]
    ],
    text(size: 16pt, fill: amber)[→],
    [
      #text(size: 8pt, fill: gray.darken(35%))[RENEWAL PREMIUM]\
      #v(2pt)
      #text(size: 15pt, weight: "bold", fill: amber)[#money(g("renewal.new_premium", default: 0), sym: "£")]
    ],
    block(fill: amber.lighten(88%), radius: 3pt, inset: (x: 8pt, y: 6pt))[
      #text(size: 8pt, fill: amber.darken(15%))[Change vs last year]\
      #text(size: 11pt, weight: "bold", fill: amber.darken(15%))[+#g("renewal.change_pct", default: "—")%]
      #text(size: 8pt, fill: amber.darken(15%))[ incl. IPT]
    ])
]
#v(12pt)

#text(weight: "bold", size: 11pt)[What's changing at renewal]
#v(4pt)
#if changes.len() > 0 [
  #for ch in changes [
    #grid(columns: (auto, 1fr), column-gutter: 7pt,
      text(fill: amber, weight: "bold")[•], [#ch])
    #v(2.5pt)
  ]
] else [
  #text(fill: gray, size: 9.5pt)[There are no changes to your cover this year.]
]
#v(10pt)

#block(fill: gray.lighten(88%), radius: 3pt, inset: (x: 10pt, y: 8pt), width: 100%)[
  #text(weight: "bold", size: 10pt)[Want to make changes, or not renew?]
  #v(3pt)
  #text(size: 9.5pt)[
    Call us on #text(weight: "bold")[#g("insurer.phone", default: "—")] or manage your
    policy online *before #g("renewal.action_deadline", default: "the renewal date")*.
    After this date your renewal will be processed. You can still cancel within
    14 days of renewal; a charge for time on cover may apply.
  ]
]
#v(12pt)

Shopping around? You can compare cover and prices from other providers — just
make sure any new policy starts on your renewal date so you stay covered.

#v(14pt)
Yours sincerely,
#v(10pt)
#text(weight: "bold")[Renewals Team]\
#text(size: 9pt, fill: gray.darken(30%))[#g("insurer.name")]
