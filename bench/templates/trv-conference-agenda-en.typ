// Conference Agenda
// @description: Day program with sessions, speakers, rooms
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration & Styling
#let accent = rgb("#2e5a88")
#let secondary = rgb("#f8f9fa")
#let text-main = rgb("#333333")
#let text-muted = rgb("#666666")

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 1.8cm, right: 1.8cm),
)
#set text(font: "Libertinus Serif", size: 10pt, fill: text-main)

// Header Section
#block(width: 100%, inset: 0pt)[
  #grid(
    columns: (1fr, auto),
    align: (left, right),
    [
      #text(size: 24pt, weight: "bold", fill: accent)[#g("conference.name", default: "Conference Agenda")] \
      #text(size: 12pt, fill: text-muted)[#g("conference.dates", default: "")] \
      #text(size: 11pt)[#g("conference.venue", default: "")] \
      #text(size: 11pt)[#g("conference.city", default: "")]
    ],
    [
      // Logo: Initials of the organizer
      #let org = g("conference.organizer", default: "CA")
      #let org-str = str(org)
      #let clusters = org-str.clusters()
      #let len = clusters.len()
      #let initials = upper(clusters.slice(0, calc.min(2, len)).join(""))
      #box(
        fill: accent,
        inset: 8pt,
        radius: 2pt,
        width: 45pt,
        height: 45pt,
        align(center + horizon)[
          #text(fill: white, weight: "bold", size: 18pt)[#initials]
        ]
      )
    ]
  )
]

#v(10pt)
#line(length: 100%, stroke: 0.5pt + accent)
#v(10pt)

// Registration Info Box (Attendee Details)
#block(
  fill: secondary,
  inset: 10pt,
  radius: 4pt,
  width: 100%
)[
  #grid(
    columns: (1fr, 1fr, 1fr),
    [
      #text(size: 8pt, weight: "bold", fill: accent)[ATTENDEE] \
      #text(weight: "bold")[#g("registration.name", default: "—")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: accent)[TICKET TYPE] \
      #g("registration.ticket_type", default: "—")
    ],
    align(right)[
      #text(size: 8pt, weight: "bold", fill: accent)[BADGE NO] \
      #text(font: "Cousine", weight: "bold")[#g("registration.badge_no", default: "—")]
    ]
  )
]

#v(20pt)

// Agenda Content
#let days = data.at("days", default: ())

#if days.len() > 0 {
  for day in days {
    let day-date = day.at("date", default: "")
    let sessions = day.at("sessions", default: ())
    
    // Day Header
    block(width: 100%)[
      #text(size: 16pt, weight: "bold", fill: accent)[#day-date]
      #v(4pt)
      #line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
      #v(8pt)
    ]
    
    if sessions.len() > 0 {
      table(
        columns: (auto, 1fr, 1fr, auto),
        stroke: none,
        inset: 6pt,
        column-gutter: 10pt,
        row-gutter: 8pt,
        
        // Table Header
        table.header(
          [#text(size: 8pt, weight: "bold", fill: text-muted)[TIME]],
          [#text(size: 8pt, weight: "bold", fill: text-muted)[SESSION]],
          [#text(size: 8pt, weight: "bold", fill: text-muted)[SPEAKER]],
          [#text(size: 8pt, weight: "bold", fill: text-muted)[ROOM/TRACK]]
        ),
        
        // Session Rows
        ..sessions.map(((s)) => (
          // Time
          [#text(font: "Cousine", size: 9pt)[#s.at("time", default: "")]],
          
          // Title & Track
          [
            #text(weight: "bold")[#s.at("title", default: "")] \
            #let track = s.at("track", default: "")
            #if track != "" [
              #text(size: 8pt, fill: accent.lighten(20%))[#track]
            ]
          ],
          
          // Speaker
          [#text(size: 9pt)[#s.at("speaker", default: "—")]],
          
          // Room
          align(right)[
            #text(size: 9pt)[#s.at("room", default: "")]
          ]
        )).flatten()
      )
    }
    v(20pt)
  }
} else {
  align(center, text(style: "italic", fill: text-muted)[No agenda items available.])
}

#v(1fr)

// Footer
#set text(size: 8pt, fill: text-muted)
#align(center)[
  #g("conference.name", default: "") · #g("conference.organizer", default: "") \
  #text(style: "italic")[Printed for #g("registration.name", default: "Guest")]
]
