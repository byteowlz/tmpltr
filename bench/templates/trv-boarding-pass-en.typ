// Boarding Pass
// @description: Compact boarding card with gate, seat, barcode ref
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
// Renamed parameter to 'def_val' to avoid name collision with the keyword 'default'
#let g(path, def_val: "") = get(data, path, default: def_val)

// Boarding pass layout archetype: ticket
// Using a narrow custom size for a realistic ticket feel
#set page(
  width: 210mm, 
  height: 105mm, 
  margin: 5mm
)

#let accent = rgb("#003366") // Deep airline blue
#let secondary = rgb("#e0e0e0")

#set text(font: "Adwaita Sans", size: 9pt)

// --- Layout Logic ---

// Header: Airline Name and Flight Info
#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #text(size: 14pt, weight: "bold", fill: accent)[#g("airline.name", def_val: "AIRLINE")] \
    #text(size: 10pt, weight: "bold")[#g("airline.code", def_val: "XX")]
  ],
  [
    #text(size: 18pt, weight: "black")[#g("flight.number", def_val: "--")] \
    #text(size: 10pt)[#g("flight.date", def_val: "--")]
  ]
)

#v(2mm)
#line(length: 100%, stroke: 0.5pt + gray)
#v(2mm)

// Main Body: Passenger and Route
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  [
    #text(size: 7pt, fill: gray.darken(50%))[PASSENGER] \
    #text(weight: "bold", size: 11pt)[#g("passenger.name", def_val: "---")] \
    #let ff = g("passenger.frequent_flyer", def_val: "")
    #if ff != "" [
      #text(size: 8pt)[#ff] \
      #text(size: 8pt, fill: accent)[#g("passenger.status", def_val: "")]
    ]
  ],
  [
    #text(size: 7pt, fill: gray.darken(50%))[FROM / TO] \
    #text(size: 12pt, weight: "bold")[#g("flight.from_code", def_val: "---")] \
    #text(size: 8pt)[#g("flight.from_city", def_val: "---")] \
    #text(size: 10pt, weight: "bold")[arrow.r] \
    #text(size: 12pt, weight: "bold")[#g("flight.to_code", def_val: "---")] \
    #text(size: 8pt)[#g("flight.to_city", def_val: "---")]
  ],
  [
    #text(size: 7pt, fill: gray.darken(50%))[CLASS / ZONE] \
    #text(weight: "bold")[#g("flight.class", def_val: "---")] \
    #text(size: 14pt, weight: "black")[ZONE #g("flight.zone", def_val: "--")]
  ]
)

#v(4mm)

// Boarding Details Grid
#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 5pt,
  [
    #text(size: 7pt, fill: gray.darken(50%))[GATE] \
    #text(size: 14pt, weight: "bold")[#g("flight.gate", def_val: "--")]
  ],
  [
    #text(size: 7pt, fill: gray.darken(50%))[BOARDING] \
    #text(size: 14pt, weight: "bold")[#g("flight.boarding_time", def_val: "--")]
  ],
  [
    #text(size: 7pt, fill: gray.darken(50%))[SEAT] \
    #text(size: 18pt, weight: "black", fill: accent)[#g("flight.seat", def_val: "--")]
  ],
  [
    #text(size: 7pt, fill: gray.darken(50%))[SEQ] \
    #text(size: 12pt, weight: "bold")[#g("flight.sequence", def_val: "--")]
  ]
)

#v(2mm)

// Departure Time
#align(center)[
  #text(size: 8pt, fill: gray.darken(50%))[DEPARTURE TIME] \
  #text(size: 11pt, weight: "bold")[#g("flight.departure_time", def_val: "--")]
]

#v(4mm)

// Barcode Section
#set align(center)
#box(width: 100%, fill: white, inset: 5pt)[
  // Simulating a barcode with a monospace font and characters
  #text(font: "Cousine", size: 10pt, spacing: 1pt)[
    #g("barcode_ref", def_val: "000000000000000000000000000000000000000000000000")
  ]
]
