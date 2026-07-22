// IT Incident Report
// @description: Postmortem: timeline, impact, root cause, actions
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let ink = rgb("#1c2733")
#let accent = rgb("#e5484d")
#let panel = rgb("#f6f8fa")

#let sev = g("incident.severity", default: "SEV-?")
#let sev-color = if sev == "SEV-1" { rgb("#e5484d") } else if sev == "SEV-2" { rgb("#f76b15") } else if sev == "SEV-3" { rgb("#ffb224") } else { rgb("#8d8d8d") }

#let badge(txt, color) = box(fill: color, radius: 9pt, inset: (x: 8pt, y: 3.5pt),
  text(fill: white, weight: "bold", size: 8.5pt, font: "Adwaita Sans")[#txt])
#let pill(txt) = box(fill: panel, stroke: 0.5pt + rgb("#d7dde3"), radius: 8pt, inset: (x: 7pt, y: 3pt),
  text(size: 8.5pt, fill: ink)[#txt])

#set page(paper: "a4", margin: (top: 1.8cm, bottom: 2.2cm, left: 2cm, right: 2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(20%), font: "Adwaita Sans")
    #line(length: 100%, stroke: 0.5pt + rgb("#d7dde3"))
    #v(2pt)
    #grid(columns: (1fr, auto, 1fr),
      [#g("org.company") — #g("org.team")],
      align(center)[Internal · Confidential],
      align(right)[#g("incident.id") · Page 1 of 1])
  ])
#set text(font: "Adwaita Sans", size: 9.5pt, fill: ink)

// Dark header band
#block(fill: ink, radius: 4pt, inset: 14pt, width: 100%)[
  #grid(columns: (1fr, auto), align: (left, right),
    [
      #text(fill: rgb("#9fb0c0"), size: 8pt, tracking: 1.2pt)[POST-INCIDENT REVIEW]
      #v(3pt)
      #text(fill: white, weight: "bold", size: 15pt)[#g("incident.title", default: "Untitled incident")]
      #v(5pt)
      #text(fill: rgb("#9fb0c0"), size: 8.5pt)[#g("org.company") · #g("org.team")]
    ],
    [
      #badge(sev, sev-color)
      #v(4pt)
      #text(fill: white, size: 9pt, weight: "medium")[#g("incident.id")]
    ])
]
#v(10pt)

// Key facts strip
#grid(columns: (1fr, 1fr, 1fr, 1fr), column-gutter: 6pt,
  ..(("Started", g("incident.start", default: "—")),
     ("Detected", g("incident.detected", default: "—")),
     ("Resolved", g("incident.resolved", default: "—")),
     ("Duration", str(g("incident.duration_min", default: "—")) + " min")).map(((lbl, val)) =>
    block(fill: panel, radius: 3pt, inset: 8pt, width: 100%)[
      #text(size: 7.5pt, fill: gray.darken(30%), tracking: 0.8pt)[#upper(lbl)] \
      #v(1pt)
      #text(size: 9pt, weight: "medium")[#val]
    ]))
#v(10pt)

// Affected services
#let services = data.at("incident", default: (:)).at("affected_services", default: ())
#if services.len() > 0 [
  #text(size: 8pt, fill: gray.darken(30%), tracking: 0.8pt)[AFFECTED SERVICES]
  #v(3pt)
  #services.map(s => pill(s)).join(h(4pt))
  #v(10pt)
]

// Customer impact
#text(size: 8pt, fill: gray.darken(30%), tracking: 0.8pt)[CUSTOMER IMPACT]
#v(3pt)
#block(fill: panel, radius: 3pt, inset: 10pt, width: 100%, stroke: (left: 2.5pt + accent))[
  #g("incident.customer_impact", default: "No customer impact recorded.")
]
#v(10pt)

// Timeline
#let timeline = data.at("timeline", default: ())
#text(size: 8pt, fill: gray.darken(30%), tracking: 0.8pt)[TIMELINE (UTC)]
#v(3pt)
#if timeline.len() > 0 {
  table(
    columns: (auto, 1fr),
    stroke: none,
    inset: (x: 8pt, y: 5pt),
    fill: (_, row) => if calc.odd(row) { panel } else { white },
    ..timeline.map(t => (
      [#text(font: "Cousine", size: 8.5pt, weight: "bold", fill: accent)[#t.at("time", default: "")]],
      [#t.at("event", default: "")],
    )).flatten()
  )
} else {
  text(fill: gray)[No timeline entries.]
}
#v(10pt)

// Root cause
#text(size: 8pt, fill: gray.darken(30%), tracking: 0.8pt)[ROOT CAUSE]
#v(3pt)
#g("root_cause", default: "Root cause analysis pending.")
#v(10pt)

// Action items
#let actions = data.at("action_items", default: ())
#text(size: 8pt, fill: gray.darken(30%), tracking: 0.8pt)[FOLLOW-UP ACTIONS]
#v(3pt)
#if actions.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto),
    align: (center, left, left, left),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + ink) } else { (bottom: 0.5pt + rgb("#e3e8ed")) },
    inset: (x: 8pt, y: 5.5pt),
    table.header(
      [#text(size: 8pt, weight: "bold")[\#]],
      [#text(size: 8pt, weight: "bold")[Action]],
      [#text(size: 8pt, weight: "bold")[Owner]],
      [#text(size: 8pt, weight: "bold")[Due]]),
    ..actions.enumerate().map(((i, a)) => (
      [#(i + 1)],
      [#a.at("action", default: "")],
      [#a.at("owner", default: "—")],
      [#a.at("due", default: "—")],
    )).flatten()
  )
} else {
  text(fill: gray)[No action items.]
}
#v(14pt)

#text(size: 8.5pt, fill: gray.darken(30%))[Prepared by #g("org.report_author", default: "—")]
