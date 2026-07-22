// GDPR Data Access Response
// @description: Art. 15 response letter with data categories and retention
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)
#set text(font: "Libertinus Serif", size: 11pt, lang: "en")

// Theme Colors
#let accent-color = rgb("#2c3e50")
#let secondary-color = rgb("#7f8c8d")

// Header: Controller Info
#grid(columns: (1fr, auto),
  [
    #text(weight: "bold", size: 14pt, fill: accent-color)[#g("controller.company", default: "Data Controller")], \
    #text(size: 10pt, fill: secondary-color)[#g("controller.address")] \
    #text(size: 10pt, fill: secondary-color)[#g("controller.dpo_email")]
  ],
  align(right)[
    #text(weight: "bold", size: 10pt)[Date of Response:] \
    #g("response.date", default: "")
  ]
)

#v(1.5cm)

// Subject Line
#block(inset: (left: 0pt), width: 100%)[
  #text(weight: "bold", size: 13pt)[
    Subject: Response to your Data Subject Access Request (Art. 15 GDPR)
  ]
]

#v(0.5cm)

// Salutation
#text(size: 11pt)[Dear #g("data_subject.name", default: "Data Subject"),]

#v(0.5cm)

// Body Intro
We are writing in response to your request dated #g("data_subject.request_date", default: ""), regarding your right of access to your personal data under Article 15 of the General Data Protection Regulation (GDPR). 

#v(0.5cm)

// Data Categories Section
#text(weight: "bold", fill: accent-color)[1. Categories of Personal Data Processed]
#v(0.2cm)
#let categories = data.at("response.categories", default: ())
#if categories.len() > 0 {
  list(..categories.map(it => [ #it ]))
} else {
  [No specific categories identified.]
}

#v(0.5cm)

// Purposes Section
#text(weight: "bold", fill: accent-color)[2. Purposes of Processing]
#v(0.2cm)
#let purposes = data.at("response.purposes", default: ())
#if purposes.len() > 0 {
  list(..purposes.map(it => [ #it ]))
} else {
  [No specific purposes identified.]
}

#v(0.5cm)

// Recipients Section
#text(weight: "bold", fill: accent-color)[3. Recipients of Your Personal Data]
#v(0.2cm)
#let recipients = data.at("response.recipients", default: ())
#if recipients.len() > 0 {
  list(..recipients.map(it => [ #it ]))
} else {
  [No third-party recipients identified.]
}

#v(0.5cm)

// Retention Section
#text(weight: "bold", fill: accent-color)[4. Data Retention Periods]
#v(0.2cm)
#g("response.retention", default: "Information regarding retention periods is not available.")

#v(1cm)

// Rights Note
#block(
  fill: rgb("#f8f9fa"),
  inset: 12pt,
  radius: 2pt,
  stroke: 0.5pt + secondary-color
)[
  #text(size: 10pt, style: "italic")[
    #g("response.rights_note", default: "You have the right to request rectification or erasure of your personal data, the right to restrict or object to processing, and the right to lodge a complaint with a supervisory authority.")
  ]
]

#v(1.5cm)

// Sign-off
#text(size: 11pt)[
  Sincerely, \
  \
  #text(weight: "bold")[Data Protection Officer] \
  #g("controller.company", default: "")
]

#v(2cm)

// Footer
#set text(size: 8pt, fill: secondary-color)
#align(center)[
  #line(length: 40%, stroke: 0.5pt + secondary-color) \
  #v(2pt)
  #g("controller.company", default: "") · #g("controller.dpo_email", default: "")
]
