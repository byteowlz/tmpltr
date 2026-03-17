// Project Brief Template (2 pages)
// Usage: tmpltr compile templates/project-brief.toml -o project-brief.pdf

#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get, brand-logo, brand-font, brand-color

#let data = tmpltr-data()
#let project = data.at("project", default: (:))
#let blocks = data.at("blocks", default: (:))

// Brand config
#let logo-path = brand-logo(data, variant: "primary", default: none)
#let logo-width-str = get(data, "brand.logo-width", default: "4cm")
#let logo-width = if type(logo-width-str) == str { eval(logo-width-str) } else { 4cm }
#let body-font = brand-font(data, usage: "body", default: "Helvetica Neue")
#let primary-color-str = brand-color(data, "primary", default: "#0f172a")
#let primary-color = if type(primary-color-str) == str { rgb(primary-color-str) } else { primary-color-str }

// Contact/company config
#let contact = data.at("brand", default: (:)).at("contact", default: (:))
#let company-name = contact.at("company", default: "Company")
#let company-legal-form = contact.at("legal-form", default: "")
#let company-full-name = if company-legal-form != "" { company-name + " " + company-legal-form } else { company-name }
#let company-street = contact.at("street", default: "")
#let company-postal-code = contact.at("postal-code", default: "")
#let company-city = contact.at("city", default: "")
#let company-postal-city = if company-postal-code != "" { company-postal-code + " " + company-city } else { company-city }
#let company-email = contact.at("email", default: "")
#let company-phone = contact.at("phone", default: "")
#let company-website = contact.at("website", default: "")
#let company-people = contact.at("people", default: ())

// Project fields
#let title = project.at("title", default: "Project Brief")
#let subtitle = project.at("subtitle", default: "")
#let customer = project.at("customer", default: "")
#let start-date = project.at("start-date", default: "")
#let duration = project.at("duration", default: "")
#let budget = project.at("budget", default: "")
#let sponsor = project.at("sponsor", default: "")
#let manager = project.at("manager", default: if company-people.len() > 0 { company-people.at(0) } else { "" })
#let team = project.at("team", default: company-people)

#let render-logo(width) = {
  if logo-path != none {
    image(logo-path, width: width)
  }
}

#let render-person(person) = {
  if type(person) == dictionary {
    let p-name = person.at("name", default: "")
    let p-title = person.at("title", default: "")
    if p-title != "" [#p-title #p-name] else [#p-name]
  } else {
    person
  }
}

#let render-people(people) = {
  if people.len() > 0 {
    people.map(p => render-person(p)).join(linebreak())
  }
}

#let render-block(block) = {
  if block.at("type", default: "text") == "table" {
    table(
      columns: block.columns.len() * (1fr,),
      stroke: 0.5pt,
      ..block.columns.map(c => [*#c*]),
      ..block.rows.flatten().map(cell => [#cell])
    )
  } else {
    eval(block.content, mode: "markup")
  }
}

#set page(
  paper: "a4",
  margin: (top: 2.2cm, right: 2cm, bottom: 2cm, left: 2.2cm),
  numbering: "1",
  number-align: center + bottom,
)

#set text(font: body-font, size: 11pt, lang: "en")
#set par(justify: true, first-line-indent: 0pt, leading: 0.7em)

// -----------------------------
// PAGE 1
// -----------------------------

#align(center)[
  #render-logo(logo-width)
  #v(1.2em)
  #text(size: 20pt, weight: "bold", fill: primary-color)[#title]
  #if subtitle != "" [
    #v(0.6em)
    #text(size: 13pt)[#subtitle]
  ]
]

#v(1.4em)
#line(length: 100%, stroke: 0.8pt + primary-color)
#v(1em)

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.5em,
  row-gutter: 0.6em,
  [*Customer:*], [#customer],
  [*Start Date:*], [#start-date],
  [*Duration:*], [#duration],
  [*Budget:*], [#budget],
  [*Sponsor:*], [#sponsor],
  [*Project Manager:*], [#render-person(manager)],
)

#v(1.2em)

#text(size: 13pt, weight: "bold", fill: primary-color)[Executive Summary]
#v(0.4em)
#if "summary" in blocks.keys() [
  #render-block(blocks.summary)
]

#v(1em)
#text(size: 13pt, weight: "bold", fill: primary-color)[Objectives]
#v(0.4em)
#if "objectives" in blocks.keys() [
  #render-block(blocks.objectives)
]

#v(1em)
#text(size: 13pt, weight: "bold", fill: primary-color)[Scope]
#v(0.4em)
#if "scope" in blocks.keys() [
  #render-block(blocks.scope)
]

#pagebreak()

// -----------------------------
// PAGE 2
// -----------------------------

#text(size: 14pt, weight: "bold", fill: primary-color)[Project Brief — Delivery Plan]
#v(0.6em)
#line(length: 100%, stroke: 0.6pt + primary-color)

#v(1em)
#text(size: 13pt, weight: "bold", fill: primary-color)[Approach]
#v(0.4em)
#if "approach" in blocks.keys() [
  #render-block(blocks.approach)
]

#v(1em)
#text(size: 13pt, weight: "bold", fill: primary-color)[Milestones]
#v(0.4em)
#if "milestones" in blocks.keys() [
  #render-block(blocks.milestones)
]

#v(1em)
#text(size: 13pt, weight: "bold", fill: primary-color)[Risks & Mitigations]
#v(0.4em)
#if "risks" in blocks.keys() [
  #render-block(blocks.risks)
]

#v(1em)
#text(size: 13pt, weight: "bold", fill: primary-color)[Team]
#v(0.4em)
#render-people(team)

#v(1.4em)
#line(length: 100%, stroke: 0.5pt)
#text(size: 9pt)[
  #company-full-name | #company-street | #company-postal-city \
  #if company-phone != "" [Phone: #company-phone | ]
  #if company-email != "" [#company-email | ]
  #company-website
]