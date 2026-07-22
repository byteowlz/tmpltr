// Hotel Invoice
// @description: Folio with nights, city tax, extras
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

#let accent = rgb("#2d5a27") // Deep forest green for hospitality feel
#let cur = g("currency", default: "EUR")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(
  paper: "a4", 
  margin: (top: 2cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
  footer: [
    #set text(size: 8pt, fill: gray)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [#g("hotel.name") · #g("hotel.vat_id")],
      align(right)[#g("hotel.address"), #g("hotel.city")]
    )
  ]
)

#set text(font: "Libertinus Serif", size: 10pt)

// Header: Logo and Title
#grid(columns: (1fr, auto),
  [
    #let h-name = g("hotel.name", default: "··")
    #let initials = upper(h-name.clusters().slice(0, calc.min(2, h-name.clusters().len())).join(""))
    #box(fill: accent, inset: 8pt, radius: 0pt)[
      #text(fill: white, weight: "bold", size: 18pt)[#initials]
    ]
  ],
  align(right)[
    #text(size: 22pt, weight: "bold", fill: accent)[GUEST FOLIO] \
    #text(size: 10pt, fill: gray.darken(50%))[#g("stay.confirmation_no", default: "—")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(10pt)

// Guest and Stay Info
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [
    #text(weight: "bold", fill: accent, size: 9pt)[GUEST DETAILS] \
    #v(4pt)
    #text(size: 11pt)[#g("guest.name")] \
    #if g("guest.company") != "" [#g("guest.company") \ ]
    #g("guest.address")
  ],
  [
    #text(weight: "bold", fill: accent, size: 9pt)[STAY INFORMATION] \
    #v(4pt)
    #grid(columns: (auto, 1fr), row-gutter: 4pt, column-gutter: 10pt,
      [Room:], [#g("stay.room")],
      [Check-in:], [#g("stay.check_in")],
      [Check-out:], [#g("stay.check_out")],
      [Nights:], [#g("stay.nights")],
      [Guests:], [#g("stay.guests")]
    )
  ]
)

#v(20pt)

// Charges Table
#let charges = data.at("charges", default: ())
#if charges.len() > 0 {
  table(
    columns: (auto, 1fr, auto),
    stroke: none,
    inset: 6pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      [#text(weight: "bold")[Date]],
      [#text(weight: "bold")[Description]],
      align(right)[#text(weight: "bold")[Amount]]
    ),
    ..charges.map(((it)) => (
      [#it.at("date", default: "—")],
      [#it.at("description", default: "—")],
      align(right)[#money(it.at("amount", default: 0), sym: sym)]
    )).flatten()
  )
} else {
  text(style: "italic", fill: gray)[No charges recorded for this stay.]
}

#v(10pt)

// Totals Section
#align(right)[
  #table(
    columns: (auto, auto),
    stroke: none,
    inset: 4pt,
    column-gutter: 20pt,
    row-gutter: 4pt,
    [#text(size: 9pt)[Room Total],], [#money(g("totals.room_total", default: 0), sym: sym)],
    [#text(size: 9pt)[City Tax],], [#money(g("totals.city_tax", default: 0), sym: sym)],
    [#text(size: 9pt)[Extras],], [#money(g("totals.extras", default: 0), sym: sym)],
    [#text(size: 9pt)[VAT],], [#money(g("totals.vat", default: 0), sym: sym)],
    table.hline(stroke: 0.5pt + gray),
    [#text(weight: "bold", size: 12pt)[Total Amount],], 
    [#text(weight: "bold", size: 12pt, fill: accent)[#money(g("totals.total", default: 0), sym: sym)]]
  )
]

#v(20pt)

// Payment Info
#set text(font: "Adwaita Sans", size: 9pt)
#box(stroke: 0.5pt + gray, inset: 10pt, radius: 2pt, width: 100%)[
  #grid(columns: (1fr, 1fr),
    [
      #text(weight: "bold", fill: accent)[PAYMENT METHOD] \
      #g("totals.payment_method", default: "—") \
      #if g("totals.card_last4") != "" [Card ending in *#g("totals.card_last4")*]
    ],
    align(right)[
      #text(weight: "bold", fill: accent)[CONTACT] \
      #g("hotel.phone") \
      #g("hotel.email", default: "")
    ]
  )
]

#v(10pt)
#text(size: 8pt, style: "italic", fill: gray)[
  Thank you for choosing #g("hotel.name"). We hope to welcome you back soon!
]
