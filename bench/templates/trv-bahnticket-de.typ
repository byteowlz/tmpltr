// Bahn-Fahrkarte
// @description: Online-Ticket mit Verbindung, Wagen/Platz, Preis
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

#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

// Ticket Layout Settings
#let accent = rgb("#e30613") // Classic red accent
#let dark-bg = rgb("#f8f8f8")
#let connections = data.at("verbindung", default: ())

// Page setup: Narrower for a ticket feel
#set page(
  paper: "a4", 
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.5cm, right: 1.5cm)
)
#set text(font: "Adwaita Sans", size: 10pt)

// Header: Logo and Company
#grid(columns: (1fr, auto),
  align(left)[
    #text(weight: "bold", size: 18pt, fill: accent)[#g("bahn.unternehmen", default: "Bahn")]
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(50%))[Buchungsnummer: #g("ticket.auftragsnummer", default: "—")]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent)
#v(10pt)

// Passenger and Class Info
#grid(columns: (1fr, 1fr, 1fr),
  [
    #text(size: 8pt, fill: gray.darken(50%))[REISENDER] \
    #text(weight: "bold")[#g("reisender.name", default: "—")] \
    #text(size: 9pt)[#g("reisender.bahncard", default: "")]
  ],
  [
    #text(size: 8pt, fill: gray.darken(50%))[DATUM] \
    #text(weight: "bold")[#g("ticket.datum", default: "—")]
  ],
  align(right)[
    #text(size: 8pt, fill: gray.darken(50%))[KLASSE] \
    #text(weight: "bold", size: 14pt)[#g("ticket.klasse", default: "")]
  ]
)

#v(15pt)

// Connections
#text(weight: "bold", size: 12pt)[Verbindungen]
#v(5pt)

#if connections.len() > 0 {
  for (idx, conn) in connections.enumerate() {
    let zug = conn.at("zug", default: "—")
    let von = conn.at("von", default: "—")
    let nach = conn.at("nach", default: "—")
    let ab = conn.at("abfahrt", default: "—")
    let an = conn.at("ankunft", default: "—")
    let gleis = conn.at("gleis_ab", default: "—")
    let wagen = conn.at("wagen", default: "—")
    let platz = conn.at("platz", default: "—")

    block(fill: dark-bg, inset: 10pt, radius: 4pt, width: 100%)[
      #grid(columns: (1fr, auto, 1fr),
        align(left)[
          #text(weight: "bold", size: 11pt)[#ab] \
          #text(size: 9pt)[#von]
        ],
        align(center)[
          #text(fill: accent, weight: "bold")[#zug] \
          #text(size: 8pt)[Gleis #gleis]
        ],
        align(right)[
          #text(weight: "bold", size: 11pt)[#an] \
          #text(size: 9pt)[#nach]
        ]
      )
      #v(5pt)
      #line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
      #v(5pt)
      #grid(columns: (1fr, 1fr, 1fr),
        [#text(size: 9pt)[Wagen: *#wagen*]],
        [#text(size: 9pt)[Platz: *#platz*]],
        align(right)[#text(size: 9pt)[#zug]]
      )
    ]
    if idx < connections.len() - 1 { v(8pt) }
  }
} else {
  text(fill: gray)[Keine Verbindungen gefunden.]
}

#v(20pt)

// Payment and Total
#grid(columns: (1fr, auto),
  [
    #text(size: 8pt, fill: gray.darken(50%))[ZAHLART] \
    #g("ticket.zahlart", default: "—")
  ],
  align(right)[
    #text(size: 10pt)[Gesamtpreis:] \
    #text(size: 18pt, weight: "bold", fill: accent)[#geld(g("ticket.preis", default: 0))]
  ]
)

#v(20pt)

// Validity and Legal
#rect(stroke: 0.5pt + gray, inset: 10pt, width: 100%)[
  #set text(size: 8pt)
  #text(weight: "bold")[Hinweise & Gültigkeit: \ ]
  #g("gueltigkeit", default: "Bitte bewahren Sie Ihr Ticket bis zum Ende der Reise auf.")
]

#v(1fr)

// Footer
#align(center)[
  #text(size: 7pt, fill: gray.darken(50%))[
    Dies ist ein elektronisches Dokument. Ein Ausdruck ist für die Beförderung zulässig. 
    #g("bahn.unternehmen", default: "Bahn") · #g("ticket.auftragsnummer", default: "")
  ]
]
