// Service Agreement
// @description: Master service agreement summary: scope, fees, term, liability cap
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

#let accent = rgb("#274e36")
#let cur = g("agreement.currency", default: "GBP")
#let sym = if cur == "EUR" { "€" } else if cur == "USD" { "$" } else { "£" }

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.4cm, left: 2.6cm, right: 2.6cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + accent.lighten(40%))
    #v(2pt)
    #grid(columns: (1fr, auto),
      [Service Agreement — #g("provider.company", default: "Provider") / #g("client.company", default: "Client")],
      [Page 1 of 1])
  ])
#set text(font: "Libertinus Serif", size: 10pt)
#set par(justify: true)

// Letterhead band
#block(width: 100%, inset: (bottom: 8pt), stroke: (bottom: 2.5pt + accent))[
  #grid(columns: (1fr, auto),
    [
      #text(size: 17pt, weight: "bold", fill: accent)[SERVICE AGREEMENT]
      #v(1pt)
      #text(size: 9pt, fill: gray.darken(40%))[Managed services — commercial summary and terms]
    ],
    align(bottom + right)[
      #text(size: 9pt)[Effective date: *#g("agreement.effective_date", default: "—")*]
    ])
]
#v(10pt)

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  block(width: 100%, stroke: 0.6pt + accent.lighten(35%), inset: 9pt, radius: 2pt)[
    #text(size: 8pt, fill: accent, weight: "bold", tracking: 0.8pt)[THE PROVIDER] \
    #v(2pt)
    #text(weight: "bold")[#g("provider.company", default: "—")] \
    #text(size: 9pt)[#g("provider.address", default: "—") \ Represented by: #g("provider.represented_by", default: "—")]
  ],
  block(width: 100%, stroke: 0.6pt + accent.lighten(35%), inset: 9pt, radius: 2pt)[
    #text(size: 8pt, fill: accent, weight: "bold", tracking: 0.8pt)[THE CLIENT] \
    #v(2pt)
    #text(weight: "bold")[#g("client.company", default: "—")] \
    #text(size: 9pt)[#g("client.address", default: "—") \ Represented by: #g("client.represented_by", default: "—")]
  ])
#v(12pt)

#let clause(n, title, body) = {
  v(7pt)
  block[
    #text(fill: accent, weight: "bold", size: 10.5pt)[Clause #n — #title]
    #v(3pt)
    #body
  ]
}

#clause(1, "Scope of Services")[
  The Provider shall deliver the following services to the Client:
  #g("agreement.scope", default: "as specified in the applicable statement of work.")
]

#clause(2, "Fees and Payment")[
  #g("agreement.fee_model", default: "Fees are payable as agreed between the parties.")
  The monthly service fee is
  #text(weight: "bold", fill: accent)[#money(g("agreement.monthly_fee", default: 0), sym: sym)]
  (plus applicable VAT), invoiced monthly in advance and payable within 30 days of invoice date.
]

#clause(3, "Term and Termination")[
  This Agreement commences on the Effective Date and runs for an initial term of
  *#g("agreement.term_months", default: "—") months*, renewing thereafter for successive
  12-month periods unless terminated by either party with written notice of
  *#g("agreement.notice_months", default: "—") months* to the end of the then-current term.
  Either party may terminate for material breach not remedied within 30 days of written notice.
]

#clause(4, "Limitation of Liability")[
  Each party's aggregate liability under this Agreement is limited to
  #g("agreement.liability_cap", default: "the cap agreed in writing between the parties").
  Neither party is liable for indirect or consequential loss, loss of profit or loss of data,
  except in cases of wilful misconduct or gross negligence.
]

#clause(5, "Confidentiality and Data Protection")[
  Each party shall keep the other party's confidential information secret and use it only for
  the performance of this Agreement. Where the Provider processes personal data on behalf of
  the Client, the parties shall enter into a separate data processing agreement.
]

#clause(6, "Governing Law")[
  This Agreement is governed by the laws of
  *#g("agreement.governing_law", default: "England and Wales")*, and the courts of that
  jurisdiction have exclusive jurisdiction.
]

#v(22pt)
#text(size: 9.5pt)[Signed by the duly authorised representatives of the parties on *#g("signatures.date", default: "the date first written above")*:]
#v(24pt)
#grid(columns: (1fr, 1fr), column-gutter: 36pt,
  [
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[
      *For the Provider* \
      #g("signatures.provider_name", default: "") \
      #g("provider.company", default: "")
    ]
  ],
  [
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[
      *For the Client* \
      #g("signatures.client_name", default: "") \
      #g("client.company", default: "")
    ]
  ])
