// Scheduled Maintenance Notice
// @description: Maintenance window, affected systems, expected impact
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration
#let accent = rgb("#2d3436")
#let warning = rgb("#d63031")
#let info = rgb("#0984e3")
#let bg-light = rgb("#f9f9f9")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)
#set text(font: "Adwaita Sans", size: 10pt, lang: "en")

// Header: Logo and Notice ID
#let provider-name = g("provider.company", default: "Service Provider")
#let initials = upper(provider-name.clusters().slice(0, calc.min(2, provider-name.clusters().len())).join(""))

#grid(columns: (1fr, auto),
  align(left)[
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#initials]
    ]
    #v(4pt)
    #text(size: 9pt, fill: gray.darken(50%))[#g("provider.status_page", default: "status.provider.io")]
  ],
  align(right)[
    #text(size: 10pt, weight: "bold", fill: accent)[MAINTENANCE NOTICE] \
    #text(size: 9pt, fill: gray.darken(50%))[ID: #g("notice.id", default: "—")]
  ]
)

#v(1cm)

// Title and Date
#align(center)[
  #text(size: 22pt, weight: "bold", fill: accent)[Scheduled Maintenance] \
  #v(4pt)
  #text(size: 12pt, fill: warning.lighten(20%))[Action Required: System Window Notification]
]

#v(1cm)

// Maintenance Window Card
#block(fill: bg-light, inset: 16pt, radius: 4pt, width: 100%)[
  #grid(columns: (1fr, 1fr), column-gutter: 20pt,
    [
      #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[START TIME] \
      #text(size: 12pt, weight: "bold")[#g("notice.window_start", default: "—")] \
      #text(size: 9pt, fill: gray.darken(50%))[Timezone: #g("notice.timezone", default: "UTC")]
    ],
    [
      #text(size: 8pt, weight: "bold", fill: gray.darken(50%))[END TIME] \
      #text(size: 12pt, weight: "bold")[#g("notice.window_end", default: "—")] \
      #text(size: 9pt, fill: gray.darken(50%))[Timezone: #g("notice.timezone", default: "UTC")]
    ]
  )
]

#v(1cm)

// Affected Services
#text(size: 13pt, weight: "bold", fill: accent)[Affected Services]
#v(6pt)
#let services = data.at("notice.affected_services", default: ())
#if services.len() > 0 {
  grid(columns: (1fr, 1fr), column-gutter: 10pt, row-gutter: 8pt,
    ..services.map(s => [
      #circle(radius: 3pt, fill: warning)[ ] #text(size: 10pt)[#s]
    ]).flatten()
  )
} else {
  [No specific services identified.]
}

#v(1cm)

// Impact and Workaround
#text(size: 13pt, weight: "bold", fill: accent)[Expected Impact]
#v(4pt)
#text(style: "italic", fill: gray.darken(30%))[#g("notice.impact", default: "No impact details provided.")]

#v(1cm)

#text(size: 13pt, weight: "bold", fill: accent)[Recommended Workaround / Action]
#v(4pt)
#text(fill: black)[#g("notice.workaround", default: "No action required.")]

#v(2cm)

// Footer / Contact
#line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
#v(8pt)
#grid(columns: (1fr, auto),
  [
    #text(size: 9pt, fill: gray.darken(50%))[
      This is an automated notification from #g("provider.company"). 
      Please visit our status page for real-time updates.
    ]
  ],
  align(right)[
    #text(size: 9pt, weight: "bold")[Support: #g("notice.contact", default: "support@provider.com")]
  ]
)
