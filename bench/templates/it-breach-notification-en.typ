// Data Breach Notification
// @description: GDPR Art. 34 customer notice: scope, data, measures
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm)
)

// Use Tinos for a formal, legalistic serif look
#set text(font: "Tinos", size: 11pt, lang: "en")
#set par(justify: true)

// Accent color: Deep charcoal/navy for a serious tone
#let accent = rgb("#2c3e50")
#let warning = rgb("#c0392b")

// Header: Logo (Initials) and Company Info
#let comp-name = g("company.name", default: "··")
#let initials = upper(comp-name.clusters().slice(0, calc.min(2, comp-name.clusters().len())).join(""))

#grid(
  columns: (1fr, auto),
  align: (left, right),
  [
    #box(fill: accent, inset: 8pt, radius: 2pt)[
      #text(fill: white, weight: "bold", size: 14pt)[#initials]
    ]
    #v(4pt)
    #text(weight: "bold", size: 12pt)[#comp-name]
  ],
  [
    #set text(size: 9pt)
    #g("company.address") \
    #g("company.postal") #g("company.city") \
    #g("company.country") \
    #v(4pt)
    #text(fill: gray.darken(50%))[#g("company.hotline") | #g("company.dpo_email")]
  ]
)

#v(1.5cm)

// Subject Line
#text(size: 16pt, weight: "bold", fill: accent)[IMPORTANT: NOTICE OF DATA BREACH]
#v(0.5cm)

#text(size: 10pt, weight: "bold", fill: warning)[Subject: Notification pursuant to Art. 34 GDPR]
#v(0.8cm)

// Date and Salutation
#align(right)[#g("date")]
#v(0.5cm)

Dear Customer,

#v(0.4cm)

We are writing to inform you of a recent data security incident involving some of your personal information. At #g("company.name"), we take the privacy and security of your data extremely seriously, and we are providing this notice to explain what happened, what information was involved, and what steps we are taking.

// Breach Details Section
#text(size: 13pt, weight: "bold", fill: accent)[1. What Happened?]
#v(0.2cm)
#g("breach.description")

#v(0.4cm)
#text(size: 13pt, weight: "bold", fill: accent)[2. When Did This Occur?]
#v(0.2cm)
The incident occurred during the period of *#g("breach.occurred_period")*. Our security systems identified the unauthorized activity on *#g("breach.discovered_date")*.

// Data Categories
#v(0.4cm)
#text(size: 13pt, weight: "bold", fill: accent)[3. What Information Was Involved?]
#v(0.2cm)
Our investigation has determined that the following categories of your personal data may have been accessed:

#let data-cats = data.at("breach.data_categories", default: ())
#if data-cats.len() > 0 {
  list(..data-cats.map(it => [#it]))
} else {
  [Information currently under investigation.]
}

#v(0.4cm)
#text(size: 13pt, weight: "bold", fill: accent)[4. Scope of the Incident]
#v(0.2cm)
Approximately *#g("breach.affected_count", default: 0)* user records were impacted by this incident.

// Measures Taken
#v(0.4cm)
#text(size: 13pt, weight: "bold", fill: accent)[5. What We Are Doing]
#v(0.2cm)
Upon discovery, we immediately initiated our incident response protocol. Our actions include:

#let measures = data.at("breach.measures_taken", default: ())
#if measures.len() > 0 {
  list(..measures.map(it => [#it]))
} else {
  [We are currently implementing remediation steps.]
}

#if g("breach.authority_notified") == "true" [
  #v(0.4cm)
  We have also notified the relevant supervisory authorities regarding this breach.
]

// Recommendations
#v(0.4cm)
#rect(fill: rgb("#fdf2f2"), stroke: 0.5pt + warning, inset: 12pt, radius: 4pt)[
  #text(weight: "bold", fill: warning)[What You Can Do]
  #v(4pt)
  To help protect your information, we recommend the following actions:
  
  #let recs = data.at("breach.recommendations", default: ())
  #if recs.len() > 0 {
    list(..recs.map(it => [#it]))
  } else {
    [Please remain vigilant and monitor your accounts for suspicious activity.]
  }
]

// Closing
#v(1cm)
We sincerely apologize for any concern or inconvenience this incident may cause you. We remain committed to protecting your data and improving our security measures to prevent such occurrences in the future.

#v(0.8cm)

Sincerely,

#text(weight: "bold")[The Data Protection Team] \
#g("company.name")

#v(2cm)
#line(length: 100%, stroke: 0.5pt + gray)
#set text(size: 8pt, fill: gray.darken(50%))
#align(center)[
  This is an official security communication. For further inquiries, please contact our Data Protection Officer at #g("company.dpo_email") or via our hotline at #g("company.hotline").
]
