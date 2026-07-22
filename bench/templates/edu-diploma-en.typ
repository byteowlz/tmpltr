// Diploma
// @description: Degree certificate, ornamental layout
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let ink = rgb("#1c2340")
#let gold = rgb("#8a6d2f")
#let signatories = data.at("signatories", default: ())

#set page(paper: "a4", margin: 1.6cm, background: {
  // double ornamental border
  place(center + horizon, rect(width: 100% - 1.9cm, height: 100% - 1.9cm, stroke: 2.2pt + ink))
  place(center + horizon, rect(width: 100% - 2.5cm, height: 100% - 2.5cm, stroke: 0.7pt + gold))
})
#set text(font: "New Computer Modern", size: 11pt, fill: ink)

#align(center)[
  #v(1.4cm)
  // Seal
  #box(width: 3.1cm, height: 3.1cm)[
    #place(center + horizon, circle(radius: 1.5cm, stroke: 1.4pt + gold))
    #place(center + horizon, circle(radius: 1.25cm, stroke: 0.5pt + gold))
    #place(center + horizon, box(width: 2.1cm)[
      #text(size: 5.4pt, fill: gold, weight: "bold")[#g("institution.seal_text", default: "SIGILLUM UNIVERSITATIS")]
    ])
  ]
  #v(0.5cm)

  #text(size: 26pt, weight: "bold", tracking: 1.5pt)[#g("institution.name", default: "The University")]
  #v(2pt)
  #text(size: 11pt, style: "italic", fill: gold)[#g("institution.city")]
  #v(0.5cm)
  #line(length: 34%, stroke: 0.8pt + gold)
  #v(0.7cm)

  #text(size: 12pt, style: "italic")[To all to whom these presents shall come, greeting:]
  #v(0.5cm)
  #text(size: 11.5pt)[Be it known that the Trustees and Faculty, \ by virtue of the authority vested in them, have conferred upon]
  #v(0.55cm)

  #text(size: 22pt, weight: "bold", style: "italic")[#g("graduate.name", default: "—")]
  #v(3pt)
  #line(length: 52%, stroke: 0.5pt + gold)
  #v(0.55cm)

  #text(size: 11.5pt)[the degree of]
  #v(0.35cm)
  #text(size: 17pt, weight: "bold", tracking: 1pt)[#upper(g("degree.title", default: "Bachelor of Arts"))]
  #v(0.25cm)
  #text(size: 12.5pt)[in #text(weight: "bold")[#g("degree.field", default: "the Liberal Arts")]]
  #if g("degree.honors") != "" [
    #v(0.25cm)
    #text(size: 12pt, style: "italic", fill: gold.darken(10%))[#g("degree.honors")]
  ]
  #v(0.5cm)
  #text(size: 11pt)[together with all the rights, privileges, and honors \ thereunto appertaining.]
  #v(0.5cm)
  #text(size: 10.5pt, style: "italic")[Conferred at #g("institution.city", default: "the seat of the University") \ on #g("degree.conferral_date", default: "the day appointed for Commencement")]

  #v(1fr)
  // Signatures
  #if signatories.len() > 0 {
    grid(columns: signatories.map(_ => 1fr), column-gutter: 0.9cm,
      ..signatories.map(s => [
        #line(length: 100%, stroke: 0.6pt + ink)
        #v(2pt)
        #text(size: 9.5pt, weight: "bold")[#s.at("name", default: "")] \
        #text(size: 8.5pt, style: "italic")[#s.at("title", default: "")]
      ]))
  } else {
    line(length: 40%, stroke: 0.6pt + ink)
  }
  #v(0.9cm)
]
