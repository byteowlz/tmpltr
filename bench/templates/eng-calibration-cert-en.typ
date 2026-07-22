// Calibration Certificate
// @description: Instrument calibration cert with reference standards, measured deviations, uncertainty
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm),
)

#let accent = rgb("#2e5a88")
#let secondary = rgb("#f8f9fa")
#let text-main = rgb("#333333")

#set text(font: "Tinos", size: 10pt, fill: text-main)

// Header: Lab Identity
#let lab-name = g("lab.name", default: "Laboratory")
#let lab-initials = upper(lab-name.clusters().slice(0, calc.min(3, lab-name.clusters().len())).join(""))

#grid(
  columns: (auto, 1fr),
  column-gutter: 20pt,
  box(fill: accent, inset: 12pt, radius: 2pt)[
    #text(fill: white, weight: "bold", size: 18pt)[#lab-initials]
  ],
  align(right)[
    #text(weight: "bold", size: 14pt, fill: accent)[CALIBRATION CERTIFICATE] \
    #text(size: 9pt, fill: gray.darken(50%))[Certificate No: #g("calibration.cert_no")] \
    #v(2pt)
    #text(size: 8.5pt)[
      #g("lab.name") \
      #g("lab.address"), #g("lab.city") \
      #g("lab.postal") #g("lab.country") \
      Accreditation: #g("lab.accreditation_no")
    ]
  ]
)

#v(10pt)
#line(length: 100%, stroke: 1pt + accent)
#v(10pt)

// Section: Customer & Instrument Info
#grid(
  columns: (1fr, 1fr),
  column-gutter: 30pt,
  [
    #text(weight: "bold", fill: accent, size: 9pt)[CUSTOMER INFORMATION]
    #v(4pt)
    #text(size: 10pt)[#g("customer.company")] \
    #g("customer.address") \
    #g("customer.city"), #g("customer.postal") \
    #g("customer.country")
  ],
  [
    #text(weight: "bold", fill: accent, size: 9pt)[INSTRUMENT UNDER TEST]
    #v(4pt)
    #table(
      columns: (auto, 1fr),
      stroke: none,
      inset: 2pt,
      [Type:], [#g("instrument.type")],
      [Manufacturer:], [#g("instrument.manufacturer")],
      [Model:], [#g("instrument.model")],
      [Serial No:], [#g("instrument.serial")],
      [Asset ID:], [#g("instrument.id_no")],
    )
  ]
)

#v(15pt)

// Section: Calibration Details
#block(fill: secondary, inset: 10pt, radius: 2pt)[
  #set text(size: 9pt)
  #grid(
    columns: (1fr, 1fr, 1fr),
    [#text(weight: "bold")[Date of Calibration:] #g("calibration.date")],
    [#text(weight: "bold")[Due Date:] #g("calibration.due_date")],
    [#text(weight: "bold")[Procedure:] #g("calibration.procedure")],
  )
  #v(4pt)
  #grid(
    columns: (1fr, 1fr),
    [#text(weight: "bold")[Ambient Temp:] #g("calibration.ambient_temp", default: "—") °C],
    [#text(weight: "bold")[Relative Humidity:] #g("calibration.humidity", default: "—") %],
  )
]

#v(15pt)

// Section: Reference Standards
#text(weight: "bold", fill: accent, size: 10pt)[REFERENCE STANDARDS USED]
#v(5pt)
#let standards = data.at("standards", default: ())
#if standards.len() > 0 {
  table(
    columns: (1fr, auto, 1fr),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + accent) } else { (bottom: 0.5pt + gray.lighten(50%)) },
    inset: 6pt,
    align: (left, left, left),
    table.header(
      [Description], [Serial No.], [Traceability]
    ),
    ..standards.map(s => (
      [#s.at("description", default: "")],
      [#s.at("serial", default: "")],
      [#s.at("traceability", default: "")]
    )).flatten()
  )
}

#v(15pt)

// Section: Measurement Results
#text(weight: "bold", fill: accent, size: 10pt)[CALIBRATION RESULTS]
#v(5pt)
#let results = data.at("results", default: ())
#if results.len() > 0 {
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, auto),
    stroke: (x, y) => if y == 0 { (bottom: 1pt + accent) } else { (bottom: 0.5pt + gray.lighten(50%)) },
    inset: 7pt,
    align: (left, right, right, right, right, center),
    table.header(
      [Test Point], [Nominal], [Measured], [Deviation], [Uncertainty], [Unit]
    ),
    ..results.map(r => (
      [#r.at("point", default: "")],
      [#r.at("nominal", default: 0)],
      [#r.at("measured", default: 0)],
      [#r.at("deviation", default: 0)],
      [#r.at("uncertainty", default: 0)],
      [#r.at("unit", default: "")]
    )).flatten()
  )
}

#v(20pt)

// Section: Statement & Signature
#text(weight: "bold", fill: accent, size: 10pt)[STATEMENT OF CONFORMITY]
#v(4pt)
#text(size: 9pt, style: "italic")[#g("statement")]

#v(30pt)

#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 8pt, fill: gray.darken(50%))[
      *Note:* All results are reported under controlled environmental conditions. 
      Calibration is performed in accordance with ISO/IEC 17025.
    ]
  ],
  align(right)[
    #v(10pt)
    #line(length: 120pt, stroke: 0.5pt + black) \
    #text(size: 9pt, weight: "bold")[Authorized Signatory] \
    #text(size: 8pt, fill: gray.darken(50%))[#g("lab.name")]
  ]
)
