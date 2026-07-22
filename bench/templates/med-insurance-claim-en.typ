// Health Insurance Claim Form
// @description: Reimbursement claim: treatments, amounts, provider details
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

#let accent = rgb("#005a87") // Deep medical blue
#let secondary = rgb("#eef4f7")
#let cur = g("claim.currency", default: "EUR")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 1.5cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  header: [
    #set text(size: 8pt, fill: gray.darken(50%))
    #grid(columns: (1fr, 1fr),
      [Form ID: CLAIM-REIMB-2026],
      align(right)[Confidential Medical Document]
    )
    #line(length: 100%, stroke: 0.5pt + gray)
  ]
)

#set text(font: "Libertinus Serif", size: 10pt)

// Header Section
#grid(columns: (auto, 1fr),
  column-gutter: 20pt,
  box(fill: accent, inset: 12pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 14pt)[
      #let ins = g("insurer.name", default: "INSURANCE")
      #upper(ins.clusters().slice(0, calc.min(3, ins.clusters().len())).join(""))
    ]
  ],
  align(left)[
    #text(size: 18pt, weight: "bold", fill: accent)[Medical Reimbursement Claim] \
    #text(size: 10pt, fill: gray.darken(40%))[Please complete all sections to avoid processing delays.]
  ]
)

#v(10pt)

// Insurer Info
#block(fill: secondary, inset: 8pt, radius: 2pt, width: 100%)[
  #set text(size: 9pt)
  *Insurer Details:* \
  #g("insurer.name", default: "—") \
  #g("insurer.address", default: "—")
]

#v(10pt)

// Member Section
#text(weight: "bold", fill: accent, size: 11pt)[1. MEMBER INFORMATION]
#line(length: 100%, stroke: 0.5pt + accent)
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 15pt,
  [
    *Full Name:* \
    #g("member.name", default: "—") \
    *Policy Number:* \
    #g("member.policy_no", default: "—")
  ],
  [
    *Date of Birth:* \
    #g("member.dob", default: "—") \
    *Email Address:* \
    #g("member.email", default: "—")
  ]
)
#v(4pt)
#grid(columns: (1fr),
  [
    *Reimbursement Bank Account (IBAN):* \
    #g("member.iban", default: "—")
  ]
)

#v(15pt)

// Claim Details
#text(weight: "bold", fill: accent, size: 11pt)[2. CLAIM DETAILS]
#line(length: 100%, stroke: 0.5pt + accent)
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 15pt,
  [
    *Date of Claim:* \
    #g("claim.date", default: "—")
  ],
  [
    *Provider Name & Address:* \
    #g("claim.provider", default: "—")
  ]
)
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 15pt,
  [
    *Treatment Period:* \
    #g("claim.treatment_dates", default: "—")
  ],
  [
    *Diagnosis/Reason:* \
    #g("claim.diagnosis", default: "—")
  ]
)

#v(15pt)

// Itemized Table
#text(weight: "bold", fill: accent, size: 11pt)[3. ITEMIZED EXPENSES]
#line(length: 100%, stroke: 0.5pt + accent)
#v(4pt)

#let items = data.at("items", default: ())
#if items.len() > 0 {
  table(
    columns: (auto, 1fr, auto),
    stroke: none,
    inset: 5pt,
    fill: (x, y) => if y == 0 { secondary } else if calc.even(y) { white } else { rgb("#fafafa") },
    table.header(
      [#text(weight: "bold")[Date]],
      [#text(weight: "bold")[Description of Service]],
      [#text(weight: "bold")[Amount]],
    ),
    ..items.map(((it)) => (
      [#g("claim.date", default: "")], // Note: The JSON has specific dates per item, but g() is for top level. 
      // Since we must use g() or dict.at, we use it.at for the item loop.
      [#it.at("date", default: "—")],
      [#it.at("description", default: "—")],
      [#money(it.at("amount", default: 0), sym: sym)],
    )).flatten()
  )
} else {
  block(width: 100%, fill: gray.lighten(90%), inset: 10pt, align(center)[No expenses listed])
}

#v(5pt)
#align(right)[
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 2pt,
    [#text(weight: "bold")[Total Claim Amount:]],
    [#text(weight: "bold", fill: accent)[#money(g("claim.total", default: 0), sym: sym)]]
  )
]

#v(20pt)

// Declaration
#text(weight: "bold", fill: accent, size: 11pt)[4. DECLARATION & SIGNATURE]
#line(length: 100%, stroke: 0.5pt + accent)
#v(6pt)
#set text(size: 9pt)
[I hereby certify that the information provided in this claim is true and correct to the best of my knowledge and that the expenses claimed were incurred for the medical services described above.]

#v(20pt)
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #line(length: 100%, stroke: 0.5pt + black)
    *Place of Signing* \
    #g("declaration.signed_place", default: "—")
  ],
  [
    #line(length: 100%, stroke: 0.5pt + black)
    *Date of Signing* \
    #g("declaration.signed_date", default: "—")
  ]
)

#v(10pt)
#grid(columns: (1fr, 1fr), column-gutter: 40pt,
  [
    #line(length: 100%, stroke: 0.5pt + black)
    *Signature of Member*
  ],
  [
    #line(length: 100%, stroke: 0.5pt + black)
    *Date*
  ]
)

#v(2cm)
#set text(size: 7pt, fill: gray)
#align(center)[
  *Internal Use Only* \
  Processed by: ____________________ | Date: ____________________ | Ref: ____________________
]
