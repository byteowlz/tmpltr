// Gift Card / Voucher
// @description: Voucher with code, value, expiry and redemption terms
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

#let pine = rgb("#1f4d3a")
#let cream = rgb("#f6f1e4")
#let cur = g("voucher.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#let voucher = data.at("voucher", default: (:))
#let terms = voucher.at("terms", default: ())

#set page(width: 110mm, height: auto, margin: (x: 8mm, y: 8mm), fill: cream)
#set text(font: "Libertinus Serif", size: 9pt, fill: pine)

// The card
#block(width: 100%, fill: pine, radius: 6pt, inset: 0pt, clip: true)[
  // top row: issuer + value chip
  #block(width: 100%, inset: (x: 14pt, top: 13pt, bottom: 0pt))[
    #grid(columns: (1fr, auto), align: horizon,
      [
        #text(fill: cream, size: 14pt, weight: "bold")[#g("issuer.name", default: "Gift Card")]
        #v(1pt)
        #text(fill: cream.transparentize(25%), size: 7.5pt, tracking: 1.2pt)[#upper(str(g("issuer.website", default: "")))]
      ],
      box(fill: cream, radius: 4pt, inset: (x: 10pt, y: 7pt))[
        #text(fill: pine, size: 17pt, weight: "bold")[#money(g("voucher.value", default: 0), sym: sym)]
      ])
  ]
  #block(width: 100%, inset: (x: 14pt, y: 10pt))[
    #line(length: 100%, stroke: (paint: cream.transparentize(55%), thickness: 0.5pt, dash: "dashed"))
    #v(8pt)
    #text(fill: cream.transparentize(30%), size: 7pt, tracking: 1.5pt)[GIFT CARD CODE]
    #v(2pt)
    #box(width: 100%, fill: cream.transparentize(88%), radius: 3pt, inset: (x: 10pt, y: 7pt))[
      #text(fill: cream, font: "Cousine", size: 12.5pt, weight: "bold")[#g("voucher.code", default: "————")]
    ]
    #v(7pt)
    #grid(columns: (1fr, 1fr), column-gutter: 10pt,
      [
        #text(fill: cream.transparentize(30%), size: 7pt, tracking: 1.5pt)[ISSUED] \
        #text(fill: cream, size: 8.5pt)[#g("voucher.issued_date", default: "—")]
      ],
      align(right)[
        #text(fill: cream.transparentize(30%), size: 7pt, tracking: 1.5pt)[VALID THROUGH] \
        #text(fill: cream, size: 8.5pt, weight: "bold")[#g("voucher.expiry_date", default: "—")]
      ])
  ]
]

#v(8pt)

// Recipient + message
#if g("voucher.recipient") != "" or g("voucher.message") != "" [
  #block(width: 100%, stroke: 0.75pt + pine.lighten(40%), radius: 4pt, inset: 10pt)[
    #if g("voucher.recipient") != "" [
      #text(size: 8pt, tracking: 1.2pt, fill: pine.lighten(20%))[FOR] #h(4pt)
      #text(size: 10.5pt, weight: "bold", style: "italic")[#g("voucher.recipient")]
      #v(3pt)
    ]
    #if g("voucher.message") != "" [
      #text(size: 9pt, style: "italic")[“#g("voucher.message")”]
    ]
  ]
  #v(8pt)
]

// Terms
#if terms.len() > 0 [
  #text(size: 7.5pt, weight: "bold", tracking: 1pt)[TERMS & CONDITIONS]
  #v(2pt)
  #set text(size: 7pt, fill: pine.lighten(15%))
  #list(tight: true, spacing: 2.5pt, marker: [·], ..terms.map(t => [#t]))
  #v(6pt)
]

#align(center)[
  #text(size: 7pt, fill: pine.lighten(20%))[
    Redeem online at #text(weight: "bold")[#g("issuer.website", default: "our website")] or present this voucher in store.
  ]
]
