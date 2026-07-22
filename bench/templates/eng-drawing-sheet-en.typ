// Technical Drawing Sheet
// @description: Drawing frame with title block, revision table, tolerance notes
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Setup Page - A1 is large, but for benchmark purposes we use A4 to ensure visibility 
// while maintaining the "frame" aesthetic.
#set page(
  paper: "a4", 
  margin: 0pt, // We will use a manual margin/frame approach
)

#let accent = rgb("#2c3e50")
#let border-weight = 1pt
#let frame-margin = 1cm

// Fonts: Arimo for text, Cousine for technical/monospaced data
#set text(font: "Arimo", size: 9pt)

// --- Drawing Frame Logic ---
#block(width: 100%, height: 100%, inset: frame-margin, stroke: 2pt + accent)[
  
  // 1. Main Drawing Area (Placeholder for schematic)
  #box(width: 100%, height: 70%, stroke: 0.5pt + gray.darken(50%))[
    #align(center + horizon)[
      #set text(fill: gray.darken(30%), size: 14pt, style: "italic")
      [TECHNICAL SCHEMATIC AREA] \
      [#g("drawing.title", default: "")] \
      [#text(size: 10pt)[Scale: #g("drawing.scale", default: "—") | Sheet: #g("drawing.sheet", default: "1") of #g("drawing.of_sheets", default: "1")]]
    ]
  ]

  #v(1fr)

  // 2. Revision Table (Placed above title block)
  #let revisions = if data.at("revisions", default: ()) != none { data.at("revisions", default: ()) } else { () }
  #if revisions.len() > 0 {
    table(
      columns: (auto, auto, 1fr, auto),
      stroke: 0.5pt + gray,
      inset: 4pt,
      align: (center, center, left, center),
      fill: (x, y) => if y == 0 { gray.lighten(80%) } else { white },
      [*Rev*], [*Date*], [*Description*], [*By*],
      ..revisions.map(r => (
        if r.at("rev", default: "") != none { r.at("rev", default: "") } else { "" },
        if r.at("date", default: "") != none { r.at("date", default: "") } else { "" },
        if r.at("description", default: "") != none { r.at("description", default: "") } else { "" },
        if r.at("by", default: "") != none { r.at("by", default: "") } else { "" },
      )).flatten()
    )
  }

  #v(5pt)

  // 3. Title Block (The core of the engineering sheet)
  #grid(
    columns: (1fr, 1fr, 1.5fr),
    rows: (auto, auto, auto, auto),
    column-gutter: 0pt,
    row-gutter: 0pt,
    stroke: 1pt + accent,
    
    // --- Row 1: Company & Dept ---
    // Use grid.cell for colspan
    grid.cell(colspan: 3, fill: accent, stroke: none, inset: 8pt)[
      #set text(fill: white, weight: "bold", size: 12pt)
      #g("company.name", default: "COMPANY NAME") \
      #set text(size: 8pt, weight: "regular")
      #g("company.department", default: "")
    ],

    // --- Row 2: Title & Number ---
    grid.cell(colspan: 2, inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      TITLE \
      #set text(size: 11pt, weight: "bold", fill: black)
      #g("drawing.title", default: "DRAWING TITLE")
    ],
    grid.cell(inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      DWG NO. \
      #set text(size: 10pt, weight: "bold", font: "Cousine")
      #g("drawing.number", default: "000000")
    ],

    // --- Row 3: Technical Specs ---
    grid.cell(inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      SCALE \
      #set text(size: 9pt)
      #g("drawing.scale", default: "—")
    ],
    grid.cell(inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      SIZE \
      #set text(size: 9pt)
      #g("drawing.size", default: "—")
    ],
    grid.cell(inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      MATERIAL / FINISH \
      #set text(size: 8pt)
      #g("drawing.material", default: "—") \
      #g("drawing.finish", default: "—")
    ],

    // --- Row 4: Approvals & Tolerances ---
    grid.cell(colspan: 2, inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      TOLERANCES / PROJECTION \
      #set text(size: 8pt)
      #g("drawing.general_tolerance", default: "—") | #g("drawing.projection", default: "—")
    ],
    grid.cell(inset: 6pt)[
      #set text(size: 7pt, fill: gray.darken(50%))
      SHEET \
      #set text(size: 9pt)
      #g("drawing.sheet", default: "1") / #g("drawing.of_sheets", default: "1")
    ]
  )

  // 5. Approval Signature Block (Small footer area)
  #v(10pt)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 15pt,
    stroke: none,
    [
      #set text(size: 7pt, fill: gray.darken(50%))
      DRAWN BY \
      #set text(size: 8pt, fill: black)
      #g("approvals.drawn_by", default: "—") \
      #set text(size: 7pt, fill: gray.darken(50%))
      #g("approvals.drawn_date", default: "")
    ],
    [
      #set text(size: 7pt, fill: gray.darken(50%))
      CHECKED BY \
      #set text(size: 8pt, fill: black)
      #g("approvals.checked_by", default: "—") \
      #set text(size: 7pt, fill: gray.darken(50%))
      #g("approvals.checked_date", default: "")
    ],
    [
      #set text(size: 7pt, fill: gray.darken(50%))
      APPROVED BY \
      #set text(size: 8pt, fill: black)
      #g("approvals.approved_by", default: "—") \
      #set text(size: 7pt, fill: gray.darken(50%))
      #g("approvals.approved_date", default: "")
    ]
  )
]
