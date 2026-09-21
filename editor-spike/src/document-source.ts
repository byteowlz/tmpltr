export interface SpikeDocument {
  number: string;
  date: string;
  title: string;
  client: string;
  contact: string;
  total: string;
  intro: string;
}

export interface SpikeDesign {
  accent: string;
  font: string;
  density: number;
  margin: number;
}

function text(value: string) {
  return value.replaceAll('\\', '\\\\').replaceAll('[', '\\[').replaceAll(']', '\\]').replaceAll('#', '\\#').replaceAll('$', '\\$').replaceAll('@', '\\@');
}

function color(hex: string) { return hex.replace('#', ''); }

export function documentSource(document: SpikeDocument, design: SpikeDesign) {
  const font = 'Libertinus Serif';
  const margin = Math.round(design.margin * 0.36);
  return `#set page(width: 210mm, height: 297mm, margin: 0mm, fill: rgb("f0f1ed"))
#set text(font: "${font}", size: 9.2pt, fill: rgb("17201d"))
#set par(leading: 0.68em)
#let accent = rgb("${color(design.accent)}")
#let muted = rgb("66716c")

#place(top + left, dx: ${margin}mm, dy: 17mm)[
  #text(size: 14pt, weight: "bold", tracking: -1pt)[BYTE\\ OWLZ]
]
#place(top + right, dx: -${margin}mm, dy: 17mm)[
  #align(right)[#text(size: 6.5pt, fill: muted)[PROPOSAL\\ ${text(document.number)}]]
]
#place(top + left, dx: ${margin}mm, dy: 32mm)[#rect(width: ${210 - margin * 2}mm, height: 1.6mm, fill: accent)]
#place(top + left, dx: ${margin}mm, dy: 46mm)[
  #text(size: 6.5pt, tracking: 1pt, fill: muted)[PROPOSAL / ${text(document.date.toUpperCase())}]
]
#place(top + left, dx: ${margin}mm, dy: 56mm)[
  #box(width: ${210 - margin * 2}mm, height: 29mm)[
    #text(size: ${design.font === 'editorial' ? 29 : 24}pt, weight: "bold")[${text(document.title)}]
  ]
]
#place(top + left, dx: ${margin}mm, dy: 94mm)[
  #line(length: ${210 - margin * 2}mm, stroke: .35pt + rgb("aeb5b1"))
  #grid(columns: (1.5fr, 1fr), column-gutter: 12mm,
    [#text(size: 6pt, tracking: .8pt, fill: muted)[PREPARED FOR] #v(2mm) #text(weight: "bold")[${text(document.client)}] #linebreak() #text(size: 7pt, fill: muted)[${text(document.contact)}]],
    [#text(size: 6pt, tracking: .8pt, fill: muted)[TOTAL INVESTMENT] #v(2mm) #text(weight: "bold")[${text(document.total)}] #linebreak() #text(size: 7pt, fill: muted)[plus applicable VAT]]
  )
  #v(4mm)
  #line(length: ${210 - margin * 2}mm, stroke: .35pt + rgb("aeb5b1"))
]
#place(top + left, dx: ${margin}mm, dy: 125mm)[
  #box(width: ${210 - margin * 2}mm, height: 70mm)[
    #text(size: 15pt, weight: "bold")[Understanding the assignment]
    #v(${3 * design.density}mm)
    ${text(document.intro)}
  ]
]
#place(top + left, dx: ${margin}mm, dy: 211mm)[
  #line(length: ${210 - margin * 2}mm, stroke: .35pt + rgb("bbc1be"))
  #grid(columns: (8mm, 1fr, auto), column-gutter: 3mm,
    [#text(fill: accent, weight: "bold")[01]],
    [#text(weight: "bold")[Discovery & architecture] #linebreak() #text(size: 7pt, fill: muted)[Two focused workshops and an implementation blueprint.]],
    [#text(weight: "bold")[€ 5,400]])
  #v(4mm)
  #line(length: ${210 - margin * 2}mm, stroke: .35pt + rgb("bbc1be"))
  #grid(columns: (8mm, 1fr, auto), column-gutter: 3mm,
    [#text(fill: accent, weight: "bold")[02]],
    [#text(weight: "bold")[Implementation sprint] #linebreak() #text(size: 7pt, fill: muted)[Build, test and document two production integrations.]],
    [#text(weight: "bold")[€ 15,900]])
]
#place(bottom + left, dx: ${margin}mm, dy: -15mm)[
  #line(length: ${210 - margin * 2}mm, stroke: .5pt)
  #v(2mm)
  #grid(columns: (1fr, 1fr, 1fr),
    [#text(size: 6pt, fill: muted)[byteowlz.tools]],
    [#align(center)[#text(size: 6pt, fill: muted)[hello\\@byteowlz.tools]]],
    [#align(right)[#text(size: 6pt, fill: muted)[01 / 01]]])
]`;
}
