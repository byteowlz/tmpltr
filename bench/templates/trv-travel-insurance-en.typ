// Travel Insurance Certificate
// @description: Coverage certificate for a trip with limits and emergency contacts
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

#let accent = rgb("#005b96")
#let secondary = rgb("#eef6fb")
#let cur = g("policy.currency", default: "EUR")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm),
  background: rect(fill: secondary.lighten(80%), width: 100%, height: 100%)
)

#set text(font: "Libertinus Serif", size: 10pt)

// Header: Certificate Title and Insurer Logo
#grid(columns: (1fr, auto),
  align(left)[
    #text(size: 24pt, weight: "bold", fill: accent)[Certificate of Insurance] \
    #text(size: 11pt, fill: gray.darken(50%))[Policy Number: #g("policy.number", default: "—")]
  ],
  align(right)[
    #let ins-name = g("insurer.name", default: "··")
    #let initials = upper(ins-name.clusters().slice(0, calc.min(2, ins-name.clusters().len())).join(""))
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#initials]
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(15pt)

// Main Content: Insured and Trip Details
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #text(weight: "bold", fill: accent, size: 11pt)[INSURED DETAILS] \
    #v(4pt)
    #text(size: 12pt, weight: "bold")[#g("insured.name", default: "—")] \
    #g("insured.address", default: "") \
    #v(4pt)
    #text(size: 9pt, fill: gray.darken(50%))[Date of Birth: #g("insured.dob", default: "—")]
  ],
  [
    #text(weight: "bold", fill: accent, size: 11pt)[TRIP INFORMATION] \
    #v(4pt)
    #grid(columns: (auto, 1fr), row-gutter: 4pt, column-gutter: 10pt,
      [Destination:], [#g("policy.destination", default: "—")],
      [Period:], [#g("policy.trip_start", default: "—") to #g("policy.trip_end", default: "—")],
      [Issue Date:], [#g("policy.issued_date", default: "—")]
    )
  ]
)

#v(20pt)

// Coverage Table
#text(weight: "bold", fill: accent, size: 11pt)[COVERAGE LIMITS]
#v(5pt)

#let coverages = data.at("policy.coverages", default: ())
#if coverages.len() > 0 {
  table(
    columns: (1fr, auto),
    stroke: none,
    fill: (x, y) => if y == 0 { accent } else if calc.even(y) { white } else { secondary },
    inset: 8pt,
    table.header(
      [#text(fill: white, weight: "bold")[Coverage Type]],
      [#text(fill: white, weight: "bold")[Limit]]
    ),
    ..coverages.map(c => (
      [#c.at("type", default: "")],
      [#c.at("limit", default: "")]
    )).flatten()
  )
} else {
  text(fill: gray)[No coverage details provided.]
}

#v(20pt)

// Summary and Emergency Contact
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #box(stroke: 0.5pt + gray, inset: 10pt, radius: 3pt, width: 100%)[
      #text(weight: "bold", size: 10pt)[EMERGENCY ASSISTANCE] \
      #v(4pt)
      #text(size: 11pt, weight: "bold", fill: accent)[#g("insurer.emergency_phone", default: "—")] \
      #text(size: 9pt, fill: gray.darken(50%))[Available 24/7 for medical emergencies and repatriation assistance.]
    ]
  ],
  [
    #align(right)[
      #text(size: 10pt)[Total Premium Paid:] \
      #text(size: 14pt, weight: "bold", fill: accent)[#money(g("policy.premium", default: 0), sym: sym)]
    ]
  ]
)

#v(30pt)

// Footer
#place(bottom, align(center)[
  #set text(size: 8pt, fill: gray.darken(50%))
  #line(length: 60%, stroke: 0.5pt + gray)
  #v(4pt)
  #g("insurer.name", default: "") \
  #g("insurer.address", default: "") \
  #text(style: "italic")[This document serves as proof of insurance. Please present it upon request by authorities or medical providers.]
])
