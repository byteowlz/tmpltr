// Software License Certificate
// @description: License grant: product, seats, term, key
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let navy = rgb("#123c63")
#let gold = rgb("#b28a2f")
#let cream = rgb("#fbf9f4")

#set page(paper: "a4", margin: 1.6cm, fill: cream)
#set text(font: "Tinos", size: 10pt, fill: rgb("#22292f"))

// Double border frame
#block(width: 100%, height: 100%, stroke: 2.5pt + navy, inset: 4pt)[
  #block(width: 100%, height: 100%, stroke: 0.75pt + gold, inset: (x: 2cm, y: 1.6cm))[

    // Vendor mark
    #align(center)[
      #let vname = g("vendor.company", default: "··")
      #let initials = upper(vname.clusters().slice(0, calc.min(2, vname.clusters().len())).join(""))
      #box(stroke: 1.5pt + gold, radius: 50%, inset: 10pt, text(fill: navy, weight: "bold", size: 14pt, font: "Arimo")[#initials])
      #v(8pt)
      #text(size: 11pt, tracking: 2pt, fill: navy)[#upper(vname)]
      #v(1pt)
      #text(size: 8pt, fill: gray.darken(35%))[#g("vendor.address")]
    ]
    #v(14pt)
    #align(center)[
      #line(length: 30%, stroke: 0.5pt + gold)
      #v(10pt)
      #text(size: 24pt, fill: navy, weight: "bold", tracking: 1pt)[Certificate of License]
      #v(6pt)
      #text(size: 10pt, style: "italic", fill: gray.darken(40%))[This certifies that]
      #v(6pt)
      #text(size: 15pt, weight: "bold")[#g("licensee.company", default: "—")]
      #v(2pt)
      #text(size: 9pt, fill: gray.darken(35%))[#g("licensee.address")]
      #v(6pt)
      #text(size: 10pt, style: "italic", fill: gray.darken(40%))[
        is granted a valid license to use the software product
      ]
      #v(6pt)
      #text(size: 14pt, weight: "bold", fill: navy)[#g("license.product", default: "—")
        #if g("license.version") != "" [ v#g("license.version")]]
      #v(10pt)
      #line(length: 30%, stroke: 0.5pt + gold)
    ]
    #v(14pt)

    // Grant details grid
    #table(
      columns: (auto, 1fr),
      stroke: (x, y) => (bottom: 0.4pt + gold.lighten(40%)),
      inset: (x: 10pt, y: 6.5pt),
      [#text(size: 8.5pt, fill: navy, weight: "bold")[LICENSE TYPE]], [#g("license.type", default: "—")],
      [#text(size: 8.5pt, fill: navy, weight: "bold")[LICENSED SEATS]], [#str(g("license.seats", default: "—"))],
      [#text(size: 8.5pt, fill: navy, weight: "bold")[DATE OF ISSUE]], [#g("license.issued", default: "—")],
      [#text(size: 8.5pt, fill: navy, weight: "bold")[LICENSE VALID UNTIL]], [#g("license.valid_until", default: "—")],
      [#text(size: 8.5pt, fill: navy, weight: "bold")[SUPPORT & UPDATES UNTIL]], [#g("license.support_until", default: "—")],
      [#text(size: 8.5pt, fill: navy, weight: "bold")[MAINTENANCE]], [#g("license.maintenance_included", default: "—")],
      [#text(size: 8.5pt, fill: navy, weight: "bold")[LICENSEE CONTACT]], [#g("licensee.contact", default: "—")],
    )
    #v(14pt)

    // License key box
    #align(center)[
      #text(size: 8pt, fill: gray.darken(40%), tracking: 1.5pt)[PRODUCT LICENSE KEY]
      #v(4pt)
      #block(fill: white, stroke: 1pt + navy, radius: 3pt, inset: (x: 18pt, y: 9pt))[
        #text(font: "Cousine", size: 12pt, weight: "bold", fill: navy)[#g("license.key", default: "————")]
      ]
    ]
    #v(1fr)

    // Signature row
    #grid(columns: (1fr, auto, 1fr), column-gutter: 20pt, align: bottom,
      [
        #align(center)[
          #line(length: 80%, stroke: 0.75pt + rgb("#22292f"))
          #v(3pt)
          #text(size: 8.5pt)[Authorized signature, #g("vendor.company", default: "Vendor")]
        ]
      ],
      [
        // Embossed-style seal
        #box(stroke: (paint: gold, thickness: 1.5pt, dash: "densely-dotted"), radius: 50%, inset: 14pt)[
          #align(center)[
            #text(size: 7pt, fill: gold.darken(15%), tracking: 1pt, font: "Arimo")[OFFICIAL \ LICENSE \ SEAL]
          ]
        ]
      ],
      [
        #align(center)[
          #line(length: 80%, stroke: 0.75pt + rgb("#22292f"))
          #v(3pt)
          #text(size: 8.5pt)[Date of issue: #g("license.issued", default: "—")]
        ]
      ])
    #v(8pt)
    #align(center)[
      #text(size: 7pt, fill: gray.darken(25%))[
        This certificate evidences the license grant under the End User License Agreement between the parties.
        Keep the license key confidential. Verification: licensing\@#{lower(g("vendor.company", default: "vendor").split(" ").at(0, default: "vendor")) + ".com"}
      ]
    ]
  ]
]
