// Patient Summary Letter
// @description: Plain-language letter to patient after consultation: findings, plan, medication changes, follow-up
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)

// Use Tinos for a professional, readable serif look common in medical letters
#set text(font: "Tinos", size: 11pt, lang: "en")
#set par(justify: false, leading: 0.65em)

// Header: Clinic Branding
#let clinic-name = g("clinic.name", default: "Medical Clinic")
#let clinic-initials = upper(clinic-name.clusters().slice(0, calc.min(2, clinic-name.clusters().len())).join(""))
#let accent-color = rgb("#2d5a27") // Medical green

#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #box(fill: accent-color, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#clinic-initials]
    ]
    #v(-6pt)
    #text(weight: "bold", size: 14pt, fill: accent-color)[#clinic-name] \
    #text(size: 9pt, fill: gray.darken(50%))[#g("clinic.department", default: "")]
  ],
  [
    #set align(right)
    #text(size: 9pt)[#g("clinic.address")] \
    #text(size: 9pt)[Phone: #g("clinic.phone", default: "—")]
  ]
)

#v(1em)
#line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
#v(1em)

// Date and Patient Info
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 9pt, fill: gray.darken(50%))[DATE] \
    #text(weight: "bold")[#g("letter.date")]
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(50%))[PATIENT] \
    #text(weight: "bold")[#g("patient.name")] \
    #text(size: 9pt)[DOB: #g("patient.dob")] \
    #text(size: 9pt)[ID: #g("patient.nhs_or_id")]
  ]
)

#v(1.5em)

// Letter Body
#text(size: 12pt, weight: "bold")[#g("letter.salutation", default: "Dear Patient,")]

#v(0.5em)

#g("letter.summary")

#v(1em)

// Findings Section
#text(weight: "bold", fill: accent-color)[Your Test Results & Findings]
#v(0.3em)
#g("letter.findings_plain")

#v(1.5em)

// Medication Changes Section
#text(weight: "bold", fill: accent-color)[Medication Updates]
#v(0.5em)

#let med-changes = data.at("letter.medication_changes", default: ())
#if med-changes.len() > 0 {
  table(
    columns: (1fr, 1fr, 1fr),
    stroke: none,
    inset: 5pt,
    fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
    table.header(
      [#text(size: 9pt, weight: "bold")[Medication]],
      [#text(size: 9pt, weight: "bold")[Change]],
      [#text(size: 9pt, weight: "bold")[Reason]],
    ),
    ..med-changes.map(((it)) => (
      [#it.at("name", default: "")],
      [#it.at("change", default: "")],
      [#it.at("reason", default: "")],
    )).flatten()
  )
} else {
  [No changes were made to your medications at this time.]
}

#v(1.5em)

// Plan Section
#text(weight: "bold", fill: accent-color)[Next Steps & Plan]
#v(0.3em)
#g("letter.plan")

#v(1.5em)

// Safety Netting
#block(
  fill: rgb("#f4f7f4"),
  inset: 10pt,
  radius: 4pt,
  stroke: 0.5pt + accent-color.lighten(50%)
)[
  #text(weight: "bold", size: 10pt, fill: accent-color)[Important: Safety Information] \
  #v(2pt)
  #text(size: 10pt)[#g("letter.safety_netting")]
]

#v(2em)

// Closing and Clinician
#grid(
  columns: (1fr, auto),
  [
    #v(1em)
    #text(weight: "bold")[Sincerely,] \
    #v(2em)
    #text(weight: "bold")[#g("clinician.name")] \
    #text(size: 9pt, fill: gray.darken(50%))[#g("clinician.role")]
  ],
  align(bottom)[
    #text(size: 8pt, fill: gray.darken(50%))[
      Follow-up scheduled for: \
      *#g("letter.followup_date", default: "TBC")*
    ]
  ]
)

#v(1fr)

// Footer
#line(length: 100%, stroke: 0.5pt + gray.lighten(50%))
#set align(center)
#text(size: 7pt, fill: gray.darken(50%))[
  This is a summary of your consultation. Please keep this document for your records. 
  If you have questions, please contact #g("clinic.name") at #g("clinic.phone").
]
