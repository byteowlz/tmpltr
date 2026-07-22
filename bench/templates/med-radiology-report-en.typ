// Radiology Report
// @description: Imaging study: technique, findings, impression
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Configuration
#let accent = rgb("#2c3e50")
#let secondary = rgb("#7f8c8d")
#let bg-light = rgb("#f8f9fa")

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2.5cm, left: 2cm, right: 2cm),
  footer: context [
    #set text(size: 8pt, fill: secondary)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [#g("center.name", default: "Diagnostic Center")],
      align(right)[Page #counter(page).display()]
    )
  ]
)

#set text(font: "Tinos", size: 11pt, lang: "en")

// Header: Clinic Branding
#grid(columns: (auto, 1fr),
  // Logo Box
  box(fill: accent, inset: 8pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 14pt)[
      #let cname = g("center.name", default: "DC")
      #let chars = cname.clusters()
      #let slice_end = calc.min(2, chars.len())
      #upper(chars.slice(0, slice_end).join(""))
    ]
  ],
  align(right)[
    #text(weight: "bold", size: 14pt, fill: accent)[#g("center.name", default: "")] \
    #text(size: 9pt, fill: secondary)[
      #g("center.address", default: "") \
      #g("center.phone", default: "")
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(10pt)

// Report Title
#align(center)[
  #text(size: 18pt, weight: "bold", tracking: 1pt)[RADIOLOGY REPORT] \
  #text(size: 11pt, fill: secondary)[#g("study.modality", default: "") - #g("study.region", default: "")]
]

#v(15pt)

// Patient and Study Metadata Grid
#table(
  columns: (1fr, 1fr),
  stroke: none,
  inset: 5pt,
  // Patient Info
  rect(fill: bg-light, width: 100%, inset: 8pt, radius: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[PATIENT INFORMATION] \
    #v(4pt)
    #text(weight: "bold", size: 12pt)[#g("patient.name", default: "")] \
    #text(size: 10pt)[
      DOB: #g("patient.dob", default: "") \
      ID: #g("patient.id", default: "")
    ]
  ],
  // Study Info
  rect(fill: bg-light, width: 100%, inset: 8pt, radius: 2pt)[
    #text(size: 8pt, weight: "bold", fill: secondary)[STUDY DETAILS] \
    #v(4pt)
    #text(weight: "bold", size: 12pt)[#g("study.modality", default: "")] \
    #text(size: 10pt)[
      Date: #g("study.date", default: "") \
      Region: #g("study.region", default: "")
    ]
  ]
)

#v(10pt)

// Clinical Context
#grid(columns: (1fr),
  [
    #text(size: 9pt, weight: "bold", fill: secondary)[REFERRING PHYSICIAN] \
    #g("study.referring", default: "")
    #v(8pt)
    #text(size: 9pt, weight: "bold", fill: secondary)[CLINICAL INDICATION] \
    #g("study.indication", default: "")
  ]
)

#v(10pt)
#line(length: 100%, stroke: 0.5pt + gray)
#v(10pt)

// Technique
#text(weight: "bold", size: 11pt, fill: accent)[TECHNIQUE] \
#text(size: 10.5pt)[#g("study.technique", default: "")]

#v(12pt)

// Findings
#text(weight: "bold", size: 11pt, fill: accent)[FINDINGS] \
{
  set par(justify: true)
  text(size: 10.5pt)[#g("report.findings", default: "")]
}

#v(12pt)

// Impression
#rect(fill: bg-light, width: 100%, inset: 12pt, radius: 2pt)[
  #text(weight: "bold", size: 11pt, fill: accent)[IMPRESSION] \
  #v(4pt)
  #text(size: 10.5pt, style: "italic")[#g("report.impression", default: "")]
]

#if g("report.recommendation", default: "") != "" [
  #v(12pt)
  #text(weight: "bold", size: 11pt, fill: accent)[RECOMMENDATION] \
  #text(size: 10.5pt)[#g("report.recommendation", default: "")]
]

#v(30pt)

// Signature Block
#grid(columns: (1fr, 1fr),
  [],
  align(right)[
    #text(size: 9pt, fill: secondary)[Electronically Signed By:] \
    #v(4pt)
    #text(weight: "bold", size: 11pt)[#g("radiologist.name", default: "")] \
    #text(size: 9pt)[#g("radiologist.signed_date", default: "")]
  ]
)
