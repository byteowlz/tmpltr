// Visa Approval Letter
// @description: Visa grant notice: type, validity, conditions
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 3cm)
)

// Use Tinos (a Times New Roman clone) for a formal, official government look
#set text(font: "Tinos", size: 11pt, lang: "en")
#set par(justify: true)

// Header: Authority Logo (Text initials) and Office Details
#let auth-name = g("authority.name", default: "Government Authority")
// Guarding array indexing and using upper() as a function
#let auth-initials = upper(auth-name.clusters().slice(0, calc.min(3, auth-name.clusters().len())).join(""))

#grid(
  columns: (1fr, 1fr),
  [
    #box(fill: rgb("#003366"), inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 18pt)[#auth-initials]
    ]
  ],
  align(right)[
    #text(weight: "bold", size: 12pt)[#g("authority.name", default: "Government Authority")] \
    #text(size: 10pt)[#g("authority.office", default: "")] \
    #text(size: 10pt)[#g("authority.address", default: "")] \
    #text(size: 10pt)[#g("authority.city", default: ""), #g("authority.state", default: "") #g("authority.postal", default: "")] \
    #text(size: 10pt)[#g("authority.country", default: "")]
  ]
)

#v(1cm)

// Reference Number and Date
#grid(
  columns: (1fr, 1fr),
  [],
  align(right)[
    #text(weight: "bold")[Date of Issue: #g("visa.issue_date", default: "N/A")] \
    #text(weight: "bold")[Visa Number: #g("visa.number", default: "N/A")]
  ]
)

#v(0.5cm)

// Subject Line - Fixed: removed invalid 'decoration' argument
#align(center)[
  #underline(text(size: 14pt, weight: "bold")[
    NOTIFICATION OF VISA GRANT
  ])
]

#v(0.5cm)

// Salutation
#text(weight: "bold")[Dear #g("applicant.name", default: "Applicant"),]

#v(0.5cm)

// Main Body
We are pleased to inform you that your application for a visa has been successful. Your visa details are outlined below. Please ensure you carry a copy of this notification and your valid passport when traveling.

#v(0.5cm)

// Visa Details Table
#table(
  columns: (1fr, 2fr),
  stroke: none,
  inset: 6pt,
  table.header(
    [#text(weight: "bold")[Detail]], [#text(weight: "bold")[Information]]
  ),
  table.hline(stroke: 0.5pt),
  [Visa Type], [#g("visa.type", default: "N/A")],
  [Visa Number], [#g("visa.number", default: "N/A")],
  [Date of Birth], [#g("applicant.dob", default: "N/A")],
  [Nationality], [#g("applicant.nationality", default: "N/A")],
  [Passport Number], [#g("applicant.passport_no", default: "N/A")],
  [Valid From], [#g("visa.valid_from", default: "N/A")],
  [Valid Until], [#g("visa.valid_until", default: "N/A")],
  [Entries], [#g("visa.entries", default: "N/A")],
  table.hline(stroke: 0.5pt),
)

#v(0.8cm)

// Conditions Section
#text(weight: "bold", size: 12pt)[Visa Conditions]
#v(0.2cm)
#text(size: 10pt, style: "italic", fill: gray.darken(50%))[The following conditions apply to your stay in the country:]

#let conditions = data.at("visa.conditions", default: ())
#if type(conditions) == array and conditions.len() > 0 {
  list(..conditions.map(c => [ #c ]))
} else {
  [No specific conditions attached to this visa.]
}

#v(1cm)

// Footer/Closing
#text(size: 10pt)[
  Please note that the grant of this visa is subject to your continued compliance with all laws and visa conditions. Failure to comply may result in the cancellation of your visa.
]

#v(1cm)

#grid(
  columns: (1fr, 1fr),
  [],
  align(right)[
    #text(weight: "bold")[Visa Processing Officer] \
    #g("authority.name", default: "Government Authority") \
    #g("authority.office", default: "")
  ]
)

#v(2cm)

// Official Seal Placeholder (Text based)
#align(center)[
  #text(size: 8pt, fill: gray.darken(40%))[
    This is an electronically generated document. No signature is required.
  ]
]
