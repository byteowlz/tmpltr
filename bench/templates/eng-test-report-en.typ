// Qualification Test Report
// @description: Product test report with test cases, measured results, pass/fail verdicts
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration
#let accent = rgb("#2e5a88")
#let fail-color = rgb("#c0392b")
#let pass-color = rgb("#27ae60")
#let bg-gray = rgb("#f8f9fa")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: context {
    let lab-name = g("lab.name", default: "Laboratory")
    set text(size: 8pt, fill: gray.darken(50%), font: "Adwaita Sans")
    grid(columns: (1fr, 1fr),
      [#lab-name],
      align(right)[Report: #g("report.number", default: "—")]
    )
    v(4pt)
    line(length: 100%, stroke: 0.5pt + gray)
  }
)

#set text(font: "Tinos", size: 10.5pt)

// Title Section
#grid(columns: (1fr, auto),
  [
    #text(size: 24pt, weight: "bold", fill: accent)[Qualification Test Report] \
    #text(size: 12pt, fill: gray.darken(40%))[Standard: #g("report.standard", default: "N/A")]
  ],
  align(right)[
    #box(fill: accent, inset: 6pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 10pt)[#upper(g("summary.verdict", default: "UNKNOWN"))]
    ]
  ]
)

#v(12pt)

// Metadata Blocks
#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  rect(fill: bg-gray, stroke: none, inset: 10pt, width: 100%)[
    #text(weight: "bold", size: 9pt, fill: accent)[TEST SUBJECT (DUT)] \
    #v(4pt)
    #text(size: 11pt, weight: "bold")[#g("dut.name", default: "—")] \
    #text(size: 10pt)[Model: #g("dut.model", default: "—")] \
    #text(size: 10pt)[Serial: #g("dut.serial", default: "—")] \
    #text(size: 10pt)[Firmware: #g("dut.fw_version", default: "—")]
  ],
  rect(fill: bg-gray, stroke: none, inset: 10pt, width: 100%)[
    #text(weight: "bold", size: 9pt, fill: accent)[REPORT DETAILS] \
    #v(4pt)
    #text(size: 10pt)[Report No: #g("report.number", default: "—")] \
    #text(size: 10pt)[Date: #g("report.date", default: "—")] \
    #text(size: 10pt)[Engineer: #g("report.engineer", default: "—")] \
    #text(size: 10pt)[Client: #g("client.company", default: "—")]
  ]
)

#v(18pt)

// Summary Section
#text(size: 14pt, weight: "bold", fill: accent)[Executive Summary]
#v(4pt)
#line(length: 100%, stroke: 1pt + accent)
#v(6pt)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 10pt)[
  align(center)[
    #text(size: 8pt, fill: gray.darken(50%))[PASSED] \
    #text(size: 18pt, weight: "bold", fill: pass-color)[#g("summary.passed", default: "0")]
  ],
  align(center)[
    #text(size: 8pt, fill: gray.darken(50%))[FAILED] \
    #text(size: 18pt, weight: "bold", fill: fail-color)[#g("summary.failed", default: "0")]
  ],
  align(center)[
    #text(size: 8pt, fill: gray.darken(50%))[OVERALL VERDICT] \
    #text(size: 14pt, weight: "bold")[#g("summary.verdict", default: "—")]
  ]
]

#v(6pt)
#block(fill: white, stroke: 0.5pt + gray, inset: 8pt, width: 100%)[
  #text(size: 9pt, weight: "bold")[Remarks:] \
  #text(size: 9.5pt, style: "italic")[#g("summary.remarks", default: "No remarks provided.")]
]

#v(24pt)

// Test Results Table
#text(size: 14pt, weight: "bold", fill: accent)[Detailed Test Results]
#v(6pt)

#let tests = data.at("tests", default: ())

#if tests.len() > 0 {
  table(
    columns: (auto, 1fr, 1fr, auto),
    stroke: none,
    inset: 8pt,
    fill: (x, y) => if y == 0 { bg-gray } else { white },
    table.header(
      [#text(weight: "bold")[ID]],
      [#text(weight: "bold")[Test Description & Requirement]],
      [#text(weight: "bold")[Measured Result]],
      [#text(weight: "bold")[Verdict]]
    ),
    ..tests.map(((it)) => (
      [#text(font: "Cousine", size: 9pt)[#it.at("id", default: "—")]],
      [
        #text(weight: "bold")[#it.at("name", default: "—")] \
        #text(size: 8.5pt, fill: gray.darken(40%))[#it.at("requirement", default: "—")]
      ],
      [#it.at("measured", default: "—")],
      [
        #let v = upper(it.at("verdict", default: ""))
        #if v == "PASS" [
          #text(fill: pass-color, weight: "bold")[✔ PASS]
        ] else if v == "FAIL" [
          #text(fill: fail-color, weight: "bold")[✘ FAIL]
        ] else [
          #text(fill: gray)[#v]
        ]
      ]
    )).flatten()
  )
} else {
  align(center, text(fill: gray)[No test data available.])
}

#v(30pt)

// Footer / Accreditation
#v(1fr)
#line(length: 100%, stroke: 0.5pt + gray)
#grid(columns: (1fr, 1fr),
  [
    #text(size: 8pt, weight: "bold")[Laboratory Information] \
    #text(size: 8pt)[#g("lab.name", default: "—")] \
    #text(size: 8pt)[#g("lab.address", default: "—")] \
    #text(size: 8pt)[#g("lab.accreditation", default: "—")]
  ],
  align(right)[
    #text(size: 8pt, fill: gray.darken(50%))[
      This report is generated electronically. 
      Verification of results requires original raw data logs.
    ]
  ]
)
