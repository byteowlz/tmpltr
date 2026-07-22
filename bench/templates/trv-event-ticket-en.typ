// Event Ticket
// @description: Concert/conference ticket with seat, entry info, order ref
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let money(x, sym: "$") = {
  let val = float(x)
  let v = calc.round(val, digits: 2)
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

// Ticket dimensions (narrow custom size)
#set page(
  paper: "a4", 
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm),
)

// Theme settings
#let accent = rgb("#2d3436")
#let highlight = rgb("#00b894")
#let bg-light = rgb("#f9f9f9")

#set text(font: "Adwaita Sans", size: 10pt)

// Center the ticket on the page
#align(center + horizon)[
  #box(
    width: 16cm,
    stroke: 1pt + accent,
    radius: 8pt,
    clip: true,
    fill: white,
    [
      // Top Bar: Organizer & Website
      #block(fill: accent, width: 100%, inset: (top: 8pt, bottom: 8pt))[
        #set text(fill: white, size: 9pt)
        #grid(columns: (1fr, auto),
          align(left)[*#upper(g("organizer.name", default: "Organizer"))*],
          align(right)[#g("organizer.website", default: "")]
        )
      ]

      #set align(left)
      #pad(x: 20pt, y: 20pt)[
        // Event Title
        #text(size: 22pt, weight: "bold", fill: accent)[#g("event.name", default: "Event Name")]
        #v(4pt)
        #text(size: 14pt, fill: highlight.darken(20%))[#g("event.venue", default: "Venue")]
        #v(2pt)
        #text(size: 10pt, fill: gray.darken(50%))[#g("event.address", default: ""), #g("event.city", default: "")]

        #v(15pt)

        // Main Info Grid
        #grid(
          columns: (1fr, 1fr, 1fr),
          column-gutter: 10pt,
          [
            #text(size: 8pt, weight: "bold", fill: gray)[DATE] \
            #text(size: 11pt)[#g("event.date", default: "-")]
          ],
          [
            #text(size: 8pt, weight: "bold", fill: gray)[DOORS] \
            #text(size: 11pt)[#g("event.doors_open", default: "-")]
          ],
          [
            #text(size: 8pt, weight: "bold", fill: gray)[START] \
            #text(size: 11pt)[#g("event.start", default: "-")]
          ]
        )

        #v(20pt)
        #line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
        #v(15pt)

        // Ticket Details
        #grid(
          columns: (1fr, 1fr, 1fr, 1fr),
          column-gutter: 10pt,
          [
            #text(size: 8pt, weight: "bold", fill: gray)[TYPE] \
            #text(size: 10pt)[#g("ticket.type", default: "-")]
          ],
          [
            #text(size: 8pt, weight: "bold", fill: gray)[SECTION] \
            #text(size: 14pt, weight: "bold")[#g("ticket.section", default: "-")]
          ],
          [
            #text(size: 8pt, weight: "bold", fill: gray)[ROW] \
            #text(size: 14pt, weight: "bold")[#g("ticket.row", default: "-")]
          ],
          [
            #text(size: 8pt, weight: "bold", fill: gray)[SEAT] \
            #text(size: 14pt, weight: "bold")[#g("ticket.seat", default: "-")]
          ]
        )

        #v(20pt)

        // Bottom Section: Purchaser, Order, Barcode
        #grid(
          columns: (1fr, 1fr),
          [
            #text(size: 8pt, weight: "bold", fill: gray)[PURCHASER] \
            #text(size: 11pt)[#g("ticket.purchaser", default: "-")] \
            #v(8pt)
            #text(size: 8pt, weight: "bold", fill: gray)[ORDER NO.] \
            #text(size: 10pt, font: "Cousine")[#g("ticket.order_no", default: "000000")]
          ],
          align(right)[
            #text(size: 8pt, weight: "bold", fill: gray)[PRICE] \
            #text(size: 18pt, weight: "bold", fill: accent)[
              #let cur = g("ticket.currency", default: "EUR")
              #let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }
              #money(g("ticket.price", default: 0), sym: sym)
            ]
            #v(10pt)
            // Fake Barcode Representation
            #box(fill: black, width: 100%, height: 30pt)[
              #set text(fill: white, size: 6pt, font: "Cousine")
              #align(center + horizon)[#g("ticket.barcode_ref", default: "")]
            ]
          ]
        )
      ]
    ]
  )
]
