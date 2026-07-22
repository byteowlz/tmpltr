// Course Completion Certificate
// @description: Training certificate with hours, topics, grade
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let accent = rgb("#0e7c6b")
#let topics = get(data, "course.topics", default: ())

#set page(paper: "a4", flipped: true, margin: (top: 1.8cm, bottom: 1.6cm, left: 3cm, right: 2.4cm),
  background: place(dx: 0mm, dy: 0mm, rect(width: 14mm, height: 210mm, fill: accent)))
#set text(font: "Adwaita Sans", size: 10.5pt)

#align(center)[
  #text(size: 12pt, weight: "bold", fill: accent)[#upper(g("provider.name"))] \
  #text(size: 8.5pt, fill: gray.darken(30%))[#g("provider.address")]
]
#v(10pt)

#align(center)[
  #text(size: 30pt, weight: "bold", tracking: 3pt)[CERTIFICATE] \
  #text(size: 12pt, tracking: 6pt, fill: gray.darken(20%))[OF COMPLETION]
]
#v(10pt)
#align(center)[#line(length: 30%, stroke: 1.6pt + accent)]
#v(10pt)

#align(center)[
  #text(size: 10pt)[This is to certify that] \
  #v(5pt)
  #text(size: 21pt, weight: "bold")[#g("participant.name")] \
  #text(size: 9pt, fill: gray.darken(30%))[born #g("participant.dob")] \
  #v(5pt)
  #text(size: 10pt)[has successfully completed the course] \
  #v(4pt)
  #text(size: 15pt, weight: "bold", fill: accent)[#g("course.title")] \
  #v(3pt)
  #text(size: 10pt)[#str(g("course.hours", default: "—")) contact hours · #g("course.start_date") – #g("course.end_date") · Final result: #text(weight: "bold")[#g("course.grade")]]
]
#v(12pt)

#if topics.len() > 0 [
  #align(center)[
    #box(width: 78%)[
      #text(size: 9pt, weight: "bold", fill: gray.darken(30%), tracking: 1.5pt)[COURSE CONTENT]
      #v(3pt)
      #columns(2, gutter: 18pt)[
        #for t in topics [
          #text(size: 9pt)[#text(fill: accent)[▸] #t] \
        ]
      ]
    ]
  ]
]
#v(1fr)

#grid(columns: (1fr, auto, 1fr), column-gutter: 20pt, align: bottom,
  align(center)[
    #line(length: 85%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[#g("issued.instructor") \ #text(fill: gray.darken(30%), style: "italic")[Course Instructor]]
  ],
  align(center)[
    #text(size: 8.5pt, fill: gray.darken(30%))[#g("issued.place"), #g("issued.date")] \
    #text(size: 8.5pt, fill: gray.darken(30%))[Certificate no. #text(weight: "bold")[#g("course.certificate_no")]]
  ],
  align(center)[
    #line(length: 85%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[#g("issued.director") \ #text(fill: gray.darken(30%), style: "italic")[Director of Studies]]
  ])
#v(8pt)
#align(center)[#text(size: 7.5pt, fill: gray)[#g("provider.accreditation")]]
