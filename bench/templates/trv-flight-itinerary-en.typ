// Flight Itinerary
// @description: Booking confirmation with segments, passenger, fare
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

#let accent = rgb("#0c6b62")
#let light = rgb("#e8f3f1")
#let cur = g("booking.currency", default: "EUR")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, x: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%))
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [#g("agency.name") · #g("agency.phone") · #g("agency.email")],
      [E-ticket itinerary/receipt · Page 1 of 1])
  ])
#set text(font: "Adwaita Sans", size: 10pt)

// Header band
#block(fill: accent, width: 100%, inset: (x: 14pt, y: 11pt), radius: 3pt)[
  #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
    [
      #text(fill: white, weight: "bold", size: 15pt)[FLIGHT ITINERARY]
      #linebreak()
      #text(fill: white.transparentize(20%), size: 9pt)[Issued by #g("agency.name", default: "—") on #g("booking.date", default: "—")]
    ],
    [
      #text(fill: white.transparentize(25%), size: 8pt)[BOOKING REFERENCE]
      #linebreak()
      #text(fill: white, weight: "bold", size: 19pt, font: "Cousine")[#g("booking.reference", default: "——————")]
    ])
]
#v(4pt)
#grid(columns: (auto, 1fr), column-gutter: 8pt, align: horizon,
  box(fill: light, inset: (x: 8pt, y: 4pt), radius: 12pt)[
    #text(fill: accent, weight: "bold", size: 9pt)[#g("booking.status", default: "PENDING")]
  ],
  text(size: 9pt, fill: gray.darken(40%))[Please verify all details. Names must match travel documents exactly.])
#v(12pt)

// Passengers
#text(weight: "bold", fill: accent, size: 11pt)[Passengers]
#v(3pt)
#let pax = data.at("passengers", default: ())
#if pax.len() > 0 {
  table(columns: (auto, 1fr, auto, auto),
    align: (center, left, center, right),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + accent) } else { (bottom: 0.5pt + gray.lighten(40%)) },
    inset: 5.5pt,
    table.header([*\#*], [*Name (as on passport)*], [*Type*], [*E-ticket number*]),
    ..pax.enumerate().map(((i, p)) => (
      [#(i + 1)],
      [#p.at("name", default: "")],
      [#p.at("type", default: "ADT")],
      [#text(font: "Cousine", size: 9pt)[#p.at("ticket_no", default: "—")]],
    )).flatten())
} else {
  text(fill: gray)[No passengers on record.]
}
#v(12pt)

// Segments
#text(weight: "bold", fill: accent, size: 11pt)[Flight segments]
#v(3pt)
#let segs = data.at("segments", default: ())
#if segs.len() > 0 {
  for (i, s) in segs.enumerate() {
    block(breakable: false, stroke: 0.6pt + gray.lighten(30%), radius: 3pt, inset: 0pt, width: 100%, below: 7pt)[
      #block(fill: light, width: 100%, inset: (x: 10pt, y: 6pt), radius: (top: 3pt))[
        #grid(columns: (auto, 1fr, auto), align: horizon, column-gutter: 10pt,
          text(weight: "bold", fill: accent)[#s.at("flight", default: "—")],
          text(size: 9pt)[#s.at("airline", default: "")],
          text(size: 9pt, fill: gray.darken(30%))[Segment #(i + 1)])
      ]
      #pad(x: 10pt, y: 7pt)[
        #grid(columns: (1.2fr, auto, 1.2fr, 1fr), column-gutter: 10pt, align: (left, center + horizon, left, left),
          [
            #text(size: 8pt, fill: gray.darken(40%))[DEPART] \
            #text(weight: "bold")[#s.at("from", default: "—")] \
            #text(size: 9pt)[#s.at("depart", default: "—")]
          ],
          text(fill: accent, size: 13pt)[→],
          [
            #text(size: 8pt, fill: gray.darken(40%))[ARRIVE] \
            #text(weight: "bold")[#s.at("to", default: "—")] \
            #text(size: 9pt)[#s.at("arrive", default: "—")]
          ],
          [
            #text(size: 8pt, fill: gray.darken(40%))[CLASS · SEAT · BAGGAGE] \
            #text(size: 9pt)[#s.at("class", default: "—") \ Seat #s.at("seat", default: "—") \ #s.at("baggage", default: "—")]
          ])
      ]
    ]
  }
} else {
  text(fill: gray)[No flight segments on record.]
}
#v(8pt)

// Fare
#grid(columns: (1fr, auto), column-gutter: 20pt,
  [
    #text(size: 8.5pt, fill: gray.darken(30%))[
      Check-in opens 24 hours before departure. Arrive at the airport no later
      than 2 hours before scheduled departure for intra-European flights.
      Changes and refunds are subject to the fare conditions of the booked
      class and may incur airline fees.
    ]
  ],
  align(right)[
    #table(columns: (auto, auto), stroke: none, align: (left, right), inset: 3pt,
      [Base fare], [#money(g("fare.base", default: 0), sym: sym)],
      [Taxes, fees & surcharges], [#money(g("fare.taxes", default: 0), sym: sym)],
      table.hline(stroke: 1pt + accent),
      [#text(weight: "bold")[Total (#cur)]], [#text(weight: "bold", fill: accent, size: 11pt)[#money(g("fare.total", default: 0), sym: sym)]])
  ])
