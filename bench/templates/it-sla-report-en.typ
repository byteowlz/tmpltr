// Monthly SLA Report
// @description: Uptime, response times, credits per service
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let teal = rgb("#0f766e")
#let good = rgb("#15803d")
#let bad = rgb("#b91c1c")
#let mist = rgb("#f0fdfa")
#let hair = rgb("#d4e5e2")

#let pctfmt(x) = {
  let v = float(x)
  let s = str(calc.round(v, digits: 2))
  if not s.contains(".") { s = s + ".00" }
  s + "%"
}
#let met(target, achieved) = float(achieved) >= float(target)

#set page(paper: "a4", margin: (top: 1.9cm, bottom: 2.2cm, left: 2.1cm, right: 2.1cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(25%), font: "Arimo")
    #line(length: 100%, stroke: 0.5pt + hair)
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [#g("provider.company") · Service Level Report],
      align(right)[Contract #g("customer.contract_no", default: "—") · Page 1 of 1])
  ])
#set text(font: "Arimo", size: 9.5pt, fill: rgb("#17302c"))

// Header: logo-right layout
#grid(columns: (1fr, auto), align: (left + horizon, right),
  [
    #text(size: 19pt, weight: "bold", fill: teal)[Service Level Report]
    #v(2pt)
    #text(size: 10pt, fill: gray.darken(40%))[Reporting period: *#g("period.month", default: "—") #g("period.year")*]
  ],
  {
    let pname = g("provider.company", default: "··")
    let initials = upper(pname.clusters().slice(0, calc.min(2, pname.clusters().len())).join(""))
    box(fill: teal, radius: 50%, inset: 11pt, text(fill: white, weight: "bold", size: 14pt)[#initials])
  })
#v(4pt)
#line(length: 100%, stroke: 2pt + teal)
#v(10pt)

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #text(size: 8pt, fill: teal, tracking: 1pt)[PROVIDER] \
    #text(weight: "bold")[#g("provider.company", default: "—")]
  ],
  [
    #text(size: 8pt, fill: teal, tracking: 1pt)[CUSTOMER] \
    #text(weight: "bold")[#g("customer.company", default: "—")] \
    #text(size: 8.5pt, fill: gray.darken(40%))[Contract no. #g("customer.contract_no", default: "—")]
  ])
#v(12pt)

// Overall availability hero box
#let overall = g("summary.overall_pct", default: "")
#block(fill: mist, stroke: 1pt + hair, radius: 5pt, inset: 12pt, width: 100%)[
  #grid(columns: (auto, 1fr), column-gutter: 16pt, align: horizon,
    [
      #text(size: 8pt, fill: teal, tracking: 1pt)[OVERALL AVAILABILITY] \
      #text(size: 26pt, weight: "bold", fill: if overall == "" { gray } else { teal })[
        #if overall == "" [—] else [#pctfmt(overall)]
      ]
    ],
    [
      #text(size: 8pt, fill: teal, tracking: 1pt)[SERVICE CREDITS THIS PERIOD] \
      #v(2pt)
      #text(size: 10.5pt, weight: "medium")[#g("summary.total_credit", default: "None")]
    ])
]
#v(12pt)

// Per-service table
#let services = data.at("services", default: ())
#text(size: 8pt, fill: teal, tracking: 1pt)[AVAILABILITY BY SERVICE]
#v(4pt)
#if services.len() > 0 {
  table(
    columns: (1fr, auto, auto, auto, auto, auto, auto),
    align: (left, right, right, center, right, right, right),
    stroke: none,
    inset: (x: 7pt, y: 6pt),
    fill: (_, row) => if row == 0 { teal } else if calc.odd(row) { mist } else { white },
    table.header(
      ..([Service], [Target], [Achieved], [Status], [Downtime], [Incidents], [Credit])
        .map(h => text(fill: white, weight: "bold", size: 8.5pt)[#h])),
    ..services.map(s => {
      let t = s.at("sla_target_pct", default: 0)
      let a = s.at("achieved_pct", default: 0)
      let ok = met(t, a)
      (
        [#s.at("name", default: "")],
        [#pctfmt(t)],
        [#text(weight: "bold", fill: if ok { good } else { bad })[#pctfmt(a)]],
        [#box(fill: if ok { good } else { bad }, radius: 7pt, inset: (x: 6pt, y: 2pt),
          text(fill: white, size: 7pt, weight: "bold")[#if ok [MET] else [MISSED]])],
        [#s.at("downtime_min", default: 0) min],
        [#s.at("incidents", default: 0)],
        [#{let c = s.at("credit_pct", default: 0); if float(c) > 0 { text(fill: bad, weight: "bold")[#c%] } else { text(fill: gray)[—] }}],
      )
    }).flatten()
  )
} else {
  text(fill: gray)[No services in scope for this period.]
}
#v(12pt)

// Notes
#if g("summary.notes") != "" [
  #text(size: 8pt, fill: teal, tracking: 1pt)[REMARKS]
  #v(4pt)
  #block(stroke: (left: 2.5pt + teal), inset: (left: 10pt, y: 2pt))[
    #text(size: 9pt)[#g("summary.notes")]
  ]
  #v(12pt)
]

#text(size: 8pt, fill: gray.darken(25%))[
  Availability is measured per the definitions in the Master Service Agreement
  #g("customer.contract_no", default: "") and excludes announced maintenance windows.
  Service credits are applied automatically to the next invoice.
]
