// Claim Settlement Letter
// @description: Claim decision: covered amount, deductions, payment details
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

#let accent = rgb("#2e5a47") // Deep forest green for insurance trust
#let text-main = rgb("#333333")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Libertinus Serif", size: 11pt, fill: text-main)
#set par(justify: true, leading: 0.65em)

// Header: Logo and Insurer Info
#grid(columns: (1fr, auto),
  [
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[
        #let ins-name = g("insurer.name", default: "MS")
        #upper(ins-name.clusters().slice(0, calc.min(3, ins-name.clusters().len())).join(""))
      ]
    ]
  ],
  align(right)[
    #text(weight: "bold", size: 11pt)[#g("insurer.name")] \
    #text(size: 10pt)[#g("insurer.address")] \
    #text(size: 10pt)[#g("insurer.claims_contact")]
  ]
)

#v(1.5em)

// Date and Recipient
#grid(columns: (1fr, 1fr),
  [],
  align(right)[
    #text(weight: "bold")[Claim Settlement Decision] \
    #v(2pt)
    #g("settlement.claim_no", default: "—") \
    #g("settlement.payment_date", default: "—")
  ]
)

#v(1em)

#text(weight: "bold")[#g("claimant.name")] \
#g("claimant.address") \
Policy Number: #g("claimant.policy_no", default: "—")

#v(1.5em)

// Salutation
[Dear #g("claimant.name", default: "Customer"),]

#v(1em)

[We are writing to formally advise you of the outcome of your recent insurance claim regarding the incident reported on #g("settlement.incident_date", default: "—"). Our claims assessment team has completed their review of the documentation and evidence provided.]

#v(1em)

// Summary Table
#set text(font: "Adwaita Sans", size: 10pt)
#block(fill: rgb("#f9f9f9"), inset: 12pt, radius: 4pt, width: 100%)[
  #set text(font: "Adwaita Sans")
  #grid(columns: (1fr, auto), column-gutter: 20pt,
    [Claim Reference:], [#g("settlement.claim_no", default: "—")],
    [Incident Date:], [#g("settlement.incident_date", default: "—")],
    [Total Amount Claimed:], [#money(g("settlement.claimed", default: 0))],
    [Less Deductible:], [#money(g("settlement.deductible", default: 0))],
    [#text(weight: "bold")[Total Settlement Amount:]], [#text(weight: "bold", fill: accent)[#money(g("settlement.payout", default: 0))]]
  )
]

#v(1em)

// Rationale
#set text(font: "Libertinus Serif", size: 11pt)
#text(weight: "bold")[Assessment Rationale] \
#v(4pt)
#g("settlement.rationale", default: "No rationale provided.")

#v(1em)

// Payment Details
#text(weight: "bold")[Payment Information] \
#v(4pt)
[The total settlement amount of *#money(g("settlement.payout", default: 0))* has been processed for electronic transfer. The funds will be deposited into your nominated account ending in *#g("settlement.iban_last4", default: "—")*. Please allow 2-3 business days for the transaction to reflect in your balance.]

#v(2em)

// Closing
[If you have any questions regarding this decision or require further clarification on the assessment, please contact our claims department directly using the contact details provided in the header of this letter.]

#v(2em)

[Yours sincerely,]

#v(1em)

#text(weight: "bold")[Claims Operations Team] \
#g("insurer.name")

#v(4em)

// Footer
#align(center)[
  #set text(size: 8pt, fill: gray)
  #line(length: 80%, stroke: 0.5pt + gray)
  #v(2pt)
  Meridian Shield Insurance Group is authorized and regulated by the relevant financial services authority.
]
