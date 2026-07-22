// Hospital Discharge Summary
// @description: Admission/discharge, diagnoses, procedures, medications, follow-up
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)
#let garr(path) = { let v = get(data, path, default: none); if type(v) == array { v } else { () } }

#set page(paper: "a4", margin: (top: 2cm, bottom: 2cm, x: 2.2cm),
  footer: [#set text(size: 7.5pt, fill: gray)
    #g("hospital.name") · #g("hospital.address") · #g("hospital.phone") #h(1fr) Page 1])
#set text(font: "Tinos", size: 10pt)

#align(center)[
  #text(size: 14pt, weight: "bold")[#g("hospital.name")] \
  #text(size: 10pt)[#g("hospital.department")] \
  #v(2pt)
  #text(size: 12pt, weight: "bold", tracking: 1pt)[DISCHARGE SUMMARY]
]
#line(length: 100%, stroke: 1pt)
#v(6pt)

#grid(columns: (1fr, 1fr), row-gutter: 4pt,
  [*Patient:* #g("patient.name")], [*MRN:* #g("patient.mrn")],
  [*Date of birth:* #g("patient.dob")], [*Attending:* #g("stay.attending")],
  [*Admitted:* #g("stay.admitted")], [*Discharged:* #g("stay.discharged")])
#v(4pt)
#line(length: 100%, stroke: 0.5pt + gray)
#v(8pt)

#let section(title, body) = [
  #text(weight: "bold", size: 10.5pt)[#upper(title)]
  #v(2pt)
  #body
  #v(8pt)
]

#let dxs = garr("summary.diagnoses")
#section("Discharge Diagnoses")[
  #if dxs.len() > 0 [
    #enum(..dxs.map(d => [#d]))
  ] else [—]
]

#let procs = garr("summary.procedures")
#section("Procedures & Studies")[
  #if procs.len() > 0 [
    #list(..procs.map(p => [#p]))
  ] else [—]
]

#section("Hospital Course")[#g("summary.course", default: "—")]

#let meds = garr("summary.medications")
#section("Discharge Medications")[
  #if meds.len() > 0 {
    table(columns: (1fr, auto, auto), stroke: 0.5pt + gray, inset: 5pt,
      table.header([*Medication*], [*Dose*], [*Frequency*]),
      ..meds.map(m => (
        [#m.at("name", default: "")],
        [#m.at("dose", default: "")],
        [#m.at("frequency", default: "")],
      )).flatten())
  } else [—]
]

#section("Follow-up")[#g("summary.follow_up", default: "—")]

#v(14pt)
#grid(columns: (1fr, 1fr), column-gutter: 30pt,
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8.5pt)[#g("stay.attending"), Attending Physician]],
  [#line(length: 100%, stroke: 0.5pt) #text(size: 8.5pt)[Date]])
