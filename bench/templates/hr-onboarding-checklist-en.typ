// Employee Onboarding Checklist
// @description: Checklist grid: IT setup, HR docs, training, buddy — with owners and status
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let violet = rgb("#5b34c9")
#let bg = rgb("#f7f5fc")

#let pill(status) = {
  let s = lower(str(status))
  let (c, t) = if s.contains("done") or s.contains("complete") { (rgb("#1e8a4c"), "Done") }
    else if s.contains("progress") { (rgb("#c47f10"), "In progress") }
    else if s == "" { (gray, "—") }
    else { (gray.darken(30%), str(status)) }
  box(fill: c.lighten(85%), stroke: 0.6pt + c.lighten(40%), radius: 6pt, inset: (x: 6pt, y: 2.5pt),
    text(size: 7.5pt, weight: "semibold", fill: c.darken(10%))[#t])
}

#let tick(status) = {
  let done = lower(str(status)).contains("done")
  box(width: 10pt, height: 10pt, radius: 2pt, baseline: 1.5pt,
    stroke: 1pt + (if done { rgb("#1e8a4c") } else { gray.darken(10%) }),
    fill: if done { rgb("#1e8a4c") } else { white },
    align(center + horizon, if done { text(fill: white, size: 7.5pt, weight: "bold")[✓] }))
}

#set page(paper: "a4", margin: (top: 1.9cm, bottom: 2cm, x: 2.1cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(30%), font: "Arimo")
    #grid(columns: (1fr, auto),
      [People Ops · Onboarding checklist v3.2],
      [Confidential — internal use])
  ])
#set text(font: "Arimo", size: 9.5pt)

// Header
#grid(columns: (auto, 1fr), column-gutter: 12pt, align: horizon,
  box(fill: violet, radius: 5pt, inset: 10pt)[
    #text(fill: white, weight: "bold", size: 15pt)[⬢]
  ],
  [
    #text(size: 17pt, weight: "bold", fill: violet.darken(20%))[Employee Onboarding Checklist]
    #v(1pt)
    #text(size: 9pt, fill: gray.darken(40%))[New-hire readiness tracker · People Operations]
  ])
#v(10pt)

// Employee card
#block(fill: bg, stroke: 0.6pt + violet.lighten(60%), radius: 5pt, inset: 12pt, width: 100%)[
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 12pt, row-gutter: 9pt,
    ..(
      ("New hire", g("employee.name", default: "—")),
      ("Start date", g("employee.start_date", default: "—")),
      ("Position", g("employee.position", default: "—")),
      ("Department", g("employee.department", default: "—")),
      ("Manager", g("employee.manager", default: "—")),
      ("Onboarding buddy", g("employee.buddy", default: "—")),
    ).map(((lbl, val)) => [
      #text(size: 7pt, fill: violet.darken(10%), tracking: 0.7pt)[#upper(lbl)] \
      #text(size: 10pt, weight: "semibold")[#val]
    ])
  )
]
#v(12pt)

// Checklist
#let items = data.at("items", default: ())
#text(size: 11pt, weight: "bold", fill: violet.darken(20%))[Checklist]
#v(5pt)
#if items.len() > 0 {
  table(
    columns: (auto, 1fr, auto, auto, auto),
    align: (center + horizon, left, left, left, left),
    stroke: (x, y) => (bottom: 0.5pt + violet.lighten(75%)),
    inset: (x: 8pt, y: 6.5pt),
    fill: (_, row) => if row == 0 { violet.lighten(90%) } else { white },
    table.header(
      [],
      [#text(size: 8pt, weight: "bold", fill: violet.darken(15%), tracking: 0.5pt)[TASK]],
      [#text(size: 8pt, weight: "bold", fill: violet.darken(15%), tracking: 0.5pt)[OWNER]],
      [#text(size: 8pt, weight: "bold", fill: violet.darken(15%), tracking: 0.5pt)[DUE]],
      [#text(size: 8pt, weight: "bold", fill: violet.darken(15%), tracking: 0.5pt)[STATUS]]),
    ..items.map(it => (
      [#tick(it.at("status", default: ""))],
      [#it.at("task", default: "")],
      [#text(size: 9pt, fill: gray.darken(50%))[#it.at("owner", default: "—")]],
      [#text(size: 9pt, fill: gray.darken(50%))[#it.at("due", default: "—")]],
      [#pill(it.at("status", default: ""))],
    )).flatten()
  )
} else {
  text(fill: gray, style: "italic")[No checklist items defined yet.]
}
#v(14pt)

// IT setup + notes
#grid(columns: (1fr, 1.4fr), column-gutter: 12pt,
  block(stroke: 0.6pt + violet.lighten(60%), radius: 5pt, inset: 11pt, width: 100%)[
    #text(size: 8pt, weight: "bold", fill: violet.darken(15%), tracking: 0.7pt)[IT SETUP]
    #v(6pt)
    #set text(size: 9pt)
    #grid(columns: (auto, 1fr), column-gutter: 8pt, row-gutter: 6pt,
      text(fill: gray.darken(40%))[Laptop], text(weight: "medium")[#g("it.laptop_model", default: "—")],
      text(fill: gray.darken(40%))[Username], text(font: "Cousine", size: 8.5pt)[#g("it.username", default: "—")],
      text(fill: gray.darken(40%))[Email], text(font: "Cousine", size: 8.5pt)[#g("it.email", default: "—")])
  ],
  block(fill: rgb("#fdf8ec"), stroke: 0.6pt + rgb("#e5cf8f"), radius: 5pt, inset: 11pt, width: 100%)[
    #text(size: 8pt, weight: "bold", fill: rgb("#8a6d1a"), tracking: 0.7pt)[NOTES]
    #v(6pt)
    #text(size: 9pt)[#{ let n = g("notes"); if n == "" [ — ] else [ #n ] }]
  ])
