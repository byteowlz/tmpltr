// Vorsorge-Erinnerung (Recall)
// @description: Recall-Schreiben einer Zahnarzt-/Hausarztpraxis zur fälligen Vorsorge
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

// Money helpers (included as per rules)
#let money(x, sym: "$") = {
  let v = calc.round(float(x), digits: 2)
  let neg = v < 0
  let a = calc.abs(v)
  let i = int(a)
  let c = int(calc.round((a - i) * 100))
  if c == 100 { i = i + 1; c = 0 }
  let s = str(i)
  let out = ""
  let n = s.clusters().len()
  for (k, ch) in s.clusters().enumerate() {
    out = out + ch
    let rem = n - k - 1
    if rem > 0 and calc.rem(rem, 3) == 0 { out = out + "," }
  }
  sym + (if neg { "-" } else { "" }) + out + "." + (if c < 10 { "0" } else { "" }) + str(c)
}

#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

// Theme settings
#let accent = rgb("#007a7c") // Medical teal
#let text-color = rgb("#2c3e50")

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
)

#set text(font: "Libertinus Serif", size: 11pt, fill: text-color)
#set par(justify: true)

// Header: Logo (Initials) and Praxis Info
#let praxis-name = g("praxis.name", default: "Praxis")
#let initials = upper(praxis-name.clusters().slice(0, calc.min(2, praxis-name.clusters().len())).join(""))

#grid(
  columns: (auto, 1fr),
  column-gutter: 20pt,
  align: (left, right),
  [
    #box(fill: accent, inset: 8pt, radius: 50%, width: 40pt, height: 40pt)[
      #set align(center + horizon)
      #text(fill: white, weight: "bold", size: 16pt)[#initials]
    ]
  ],
  [
    #set align(right)
    #text(weight: "bold", size: 12pt)[#g("praxis.name")] \
    #text(size: 10pt)[#g("praxis.strasse") \ #g("praxis.plz_ort") \ #g("praxis.telefon")] \
    #text(size: 10pt, fill: accent)[#g("praxis.online_buchung")]
  ]
)

#v(1.5em)

// Date and Recipient
#set align(left)
#text(size: 10pt)[#g("recall.datum")]

#v(1em)

#box(width: 100%, stroke: 0.5pt + gray.lighten(50%), inset: 10pt)[
  #text(size: 10pt, weight: "bold")[Empfänger:] \
  #g("patient.name") \
  #g("patient.strasse") \
  #g("patient.plz_ort")
]

#v(2em)

// Subject
#text(size: 14pt, weight: "bold", fill: accent)[Vorsorge-Erinnerung]

#v(1em)

// Body
Sehr geehrte(r) #g("patient.name", default: "Patientin/Patient"),

#v(0.5em)

die letzte Untersuchung in unserer Praxis fand am #g("recall.letzte_untersuchung", default: "—") statt. 

Um Ihre Zahngesundheit langfristig zu erhalten, empfehlen wir gemäß dem empfohlenen Zeitraum (#g("recall.empfohlener_zeitraum", default: "—")) eine erneute Kontrolle. 

Konkret steht folgende Leistung an: \
#text(weight: "bold")[#g("recall.faellige_leistung")]

#v(1em)

// Appointment Suggestions
#text(weight: "bold")[Wir haben bereits folgende Terminvorschläge für Sie reserviert:]

#let suggestions = data.at("suggested_appointments", default: ())
#if suggestions.len() > 0 {
  set text(size: 10pt)
  grid(
    columns: (1fr, 1fr, 1fr),
    stroke: none,
    column-gutter: 10pt,
    row-gutter: 6pt,
    ..suggestions.map(s => [
      #box(fill: accent.lighten(90%), inset: 5pt, radius: 2pt, width: 100%)[
        #set align(center)
        #text(weight: "bold", fill: accent)[#s.at("date", default: "")] \
        #text(size: 9pt)[#s.at("time", default: "") Uhr] \
        #text(size: 8pt, style: "italic")[#s.at("type", default: "")]
      ]
    ]).flatten()
  )
} else {
  [Bitte kontaktieren Sie uns für eine Terminvereinbarung.]
}

#v(1.5em)

#text(size: 10pt)[
  #g("recall.bonusheft_hinweis")
]

#v(2em)

// Footer Info
#line(length: 100%, stroke: 0.5pt + accent.lighten(50%))
#grid(
  columns: (1fr, 1fr),
  [
    #text(size: 9pt, style: "italic")[
      #if g("additional_info.cancelation_policy") != "" [#g("additional_info.cancelation_policy")]
    ]
  ],
  align(right)[
    #text(size: 9pt)[
      #if g("additional_info.emergency_contact") != "" [#g("additional_info.emergency_contact")]
    ]
  ]
)
