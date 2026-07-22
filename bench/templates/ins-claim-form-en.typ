// Insurance Claim Form
// @description: Incident claim: what/when/where, damages, bank details
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

#let accent = rgb("#8f1d21")
#let damages = data.at("damages", default: ())

// form field box with tiny caption
#let fbox(label, value) = box(width: 100%, stroke: 0.6pt + gray.darken(35%), inset: (x: 6pt, top: 4pt, bottom: 5pt))[
  #text(size: 6.3pt, fill: gray.darken(35%), tracking: 0.5pt)[#upper(label)]
  #linebreak()
  #text(size: 9.5pt)[#value #h(1fr)]
]
// checkbox
#let cb(checked) = box(width: 8.5pt, height: 8.5pt, stroke: 0.8pt + black, baseline: 1pt)[
  #if checked { align(center + horizon, text(size: 7.5pt, weight: "bold")[X]) }
]
#let sec(no, title) = {
  v(9pt)
  block(fill: accent, inset: (x: 8pt, y: 4.5pt), width: 100%)[
    #text(fill: white, weight: "bold", size: 9.5pt)[#no #h(6pt) #upper(title)]
  ]
  v(4pt)
}

#set page(paper: "a4", margin: (top: 1.6cm, bottom: 1.8cm, x: 1.9cm),
  footer: [
    #set text(size: 6.8pt, fill: gray.darken(35%))
    #grid(columns: (1fr, auto),
      [#g("insurer.name") · #g("insurer.address")],
      [Form CL-101 (rev. 03/2026) · Page 1 of 1])
  ])
#set text(font: "Adwaita Sans", size: 9.5pt)

// Header
#grid(columns: (auto, 1fr, auto), column-gutter: 12pt, align: (top, top, top),
  box(fill: accent, inset: 8pt)[#text(fill: white, weight: "bold", size: 13pt)[BP]],
  [
    #text(weight: "bold", size: 12.5pt)[#g("insurer.name", default: "Insurance Company")]\
    #text(size: 8pt, fill: gray.darken(35%))[#g("insurer.address")]
    #v(3pt)
    #text(size: 15pt, weight: "bold", fill: accent)[PROPERTY & CASUALTY CLAIM FORM]
  ],
  box(stroke: (thickness: 0.7pt, dash: "dashed"), inset: 6pt, width: 96pt)[
    #text(size: 6.5pt, fill: gray.darken(35%))[FOR OFFICE USE ONLY]\
    #v(2pt)
    #text(size: 7.5pt, fill: gray.darken(20%))[Claim no. \_\_\_\_\_\_\_\_\_\_\_\_]\
    #v(2pt)
    #text(size: 7.5pt, fill: gray.darken(20%))[Received \_\_\_\_\_\_\_\_\_\_\_\_\_]
  ])
#v(2pt)
#text(size: 8pt, fill: gray.darken(30%))[Please complete all sections in block capitals. Attach photographs, invoices and repair estimates where available.]

#sec("1", "Policyholder / Claimant")
#grid(columns: (1.4fr, 1fr), column-gutter: 6pt, row-gutter: 6pt,
  fbox("Full name", g("claimant.name")),
  fbox("Policy number", g("claimant.policy_no")))
#v(6pt)
#grid(columns: (1fr, 1.4fr), column-gutter: 6pt,
  fbox("Daytime phone", g("claimant.phone")),
  fbox("Email address", g("claimant.email")))

#sec("2", "Incident Details")
#grid(columns: (1fr, 1fr, 2fr), column-gutter: 6pt,
  fbox("Date of incident", g("incident.date")),
  fbox("Time", g("incident.time")),
  fbox("Police report no. (if any)", g("incident.police_report_no", default: "—")))
#v(6pt)
#fbox("Location of incident", g("incident.location"))
#v(6pt)
#let ty = lower(g("incident.type", default: ""))
#box(width: 100%, stroke: 0.6pt + gray.darken(35%), inset: (x: 6pt, y: 5pt))[
  #text(size: 6.3pt, fill: gray.darken(35%), tracking: 0.5pt)[TYPE OF LOSS — TICK ALL THAT APPLY]
  #v(3pt)
  #grid(columns: (1fr, 1fr, 1fr), row-gutter: 5pt,
    [#cb(ty.contains("fire")) #h(4pt) Fire / smoke],
    [#cb(ty.contains("water")) #h(4pt) Water damage],
    [#cb(ty.contains("theft") or ty.contains("burglary")) #h(4pt) Theft / burglary],
    [#cb(ty.contains("storm") or ty.contains("weather")) #h(4pt) Storm / weather],
    [#cb(ty.contains("liab")) #h(4pt) Liability],
    [#cb(ty != "" and not (ty.contains("fire") or ty.contains("water") or ty.contains("theft") or ty.contains("burglary") or ty.contains("storm") or ty.contains("weather") or ty.contains("liab"))) #h(4pt) Other: #if ty != "" [#text(size: 8pt)[#g("incident.type")]]])
]
#v(6pt)
#box(width: 100%, stroke: 0.6pt + gray.darken(35%), inset: (x: 6pt, top: 4pt, bottom: 6pt))[
  #text(size: 6.3pt, fill: gray.darken(35%), tracking: 0.5pt)[DESCRIPTION OF EVENTS — WHAT HAPPENED, AND WHAT WAS DONE TO LIMIT THE DAMAGE?]
  #v(2pt)
  #text(size: 9pt)[#g("incident.description", default: "")]
  #v(2pt)
]

#sec("3", "Itemised Damages")
#if damages.len() > 0 {
  table(
    columns: (auto, 1fr, auto),
    align: (center, left, right),
    stroke: (x, y) => (bottom: (thickness: 0.4pt, dash: "dotted", paint: gray.darken(20%))),
    inset: (x: 6pt, y: 4.5pt),
    table.header(
      [#text(size: 7.5pt, weight: "bold", fill: accent)[No.]],
      [#text(size: 7.5pt, weight: "bold", fill: accent)[ITEM / REPAIR]],
      [#text(size: 7.5pt, weight: "bold", fill: accent)[AMOUNT (USD)]]),
    ..damages.enumerate().map(((i, d)) => (
      [#(i + 1)],
      [#d.at("item", default: "")],
      [#money(d.at("value", default: 0))],
    )).flatten()
  )
} else {
  text(fill: gray, size: 9pt)[No items listed — attach a separate schedule if required.]
}
#v(4pt)
#align(right)[
  #box(stroke: 1pt + accent, inset: (x: 10pt, y: 6pt))[
    #text(size: 8pt, fill: gray.darken(35%))[TOTAL AMOUNT CLAIMED]
    #h(10pt)
    #text(size: 12pt, weight: "bold", fill: accent)[#money(g("total_claimed", default: 0))]
  ]
]

#sec("4", "Payment Details")
#fbox("Account for settlement (IBAN / routing)", g("claimant.iban"))

#sec("5", "Declaration and Signature")
#text(size: 8pt)[
  I declare that the information given on this form is true and complete to the
  best of my knowledge and belief, and that I have not withheld any material
  information. I understand that submitting a false or exaggerated claim may
  result in the claim being refused and the policy voided, and may be reported
  to the relevant authorities.
]
#v(12pt)
#grid(columns: (1fr, 1fr, 1.4fr), column-gutter: 18pt,
  [
    #text(size: 9pt)[#g("declaration.place", default: "")]
    #v(2pt)
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 7pt, fill: gray.darken(35%))[PLACE]
  ],
  [
    #text(size: 9pt)[#g("declaration.date", default: "")]
    #v(2pt)
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 7pt, fill: gray.darken(35%))[DATE]
  ],
  [
    #v(11pt)
    #line(length: 100%, stroke: 0.6pt)
    #text(size: 7pt, fill: gray.darken(35%))[SIGNATURE OF CLAIMANT]
  ])
