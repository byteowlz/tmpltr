// Employment Contract
// @description: Key terms: position, salary, start date, hours, notice period, clauses
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

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

#let navy = rgb("#12315e")
#let cur = g("terms.currency", default: "GBP")
#let sym = if cur == "USD" { "$" } else if cur == "EUR" { "€" } else { "£" }

#set page(paper: "a4", margin: (top: 2.4cm, bottom: 2.6cm, x: 2.5cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #grid(columns: (1fr, auto),
      [#g("employer.company") · #g("employer.address"), #g("employer.city")],
      [Page 1 of 1])
  ])
#set text(font: "Tinos", size: 10.5pt)
#set par(justify: true, leading: 0.62em)

#align(center)[
  #text(size: 17pt, weight: "bold", fill: navy)[CONTRACT OF EMPLOYMENT]
  #v(2pt)
  #text(size: 9.5pt, fill: gray.darken(50%))[Statement of main terms pursuant to s.1 Employment Rights Act 1996]
]
#v(4pt)
#line(length: 100%, stroke: 1.5pt + navy)
#v(10pt)

This Contract of Employment is entered into between

#pad(left: 1.2cm)[
  *#g("employer.company")*, #g("employer.address"), #g("employer.city"), \
  represented by #g("employer.represented_by") — hereinafter the "*Employer*" —
  #v(4pt)
  and
  #v(4pt)
  *#g("employee.name")*, #g("employee.address"), #g("employee.city"), born #g("employee.dob")
  — hereinafter the "*Employee*" —
]
#v(8pt)

#let clause(no, title, body) = {
  v(7pt)
  text(weight: "bold", fill: navy)[#no. #title]
  v(3pt)
  body
}

#clause("1", "Commencement and Position")[
  The employment commences on *#g("terms.start_date", default: "—")*. The Employee is
  engaged as *#g("terms.position", default: "—")* in the
  #g("terms.department", default: "—") department. The Employer may assign other
  duties consistent with the Employee's qualifications.
]

#clause("2", "Place of Work")[
  The normal place of work is #g("terms.workplace", default: "the Employer's registered office").
]

#clause("3", "Remuneration")[
  The gross annual salary is *#money(g("terms.salary_annual", default: 0), sym: sym)*
  (#cur), payable in twelve equal monthly instalments in arrears on or around the
  last working day of each month, by credit transfer to the Employee's nominated account.
]

#clause("4", "Hours of Work")[
  Normal working hours are *#g("terms.hours_per_week", default: "—") hours per week*,
  Monday to Friday. Reasonable additional hours may be required by the needs of the
  business; the salary in Clause 3 is inclusive of such hours.
]

#clause("5", "Holidays")[
  The Employee is entitled to *#g("terms.vacation_days", default: "—") days* of paid
  annual leave in each holiday year, in addition to public holidays in England and Wales.
  Leave must be approved in advance by the Employee's line manager.
]

#clause("6", "Probationary Period")[
  The first *#g("terms.probation_months", default: "—") months* of employment are a
  probationary period, during which either party may terminate the employment on one
  week's written notice.
]

#clause("7", "Notice")[
  After successful completion of the probationary period, the employment may be
  terminated by either party giving not less than
  *#g("terms.notice_weeks", default: "—") weeks'* written notice. The Employer
  reserves the right to make a payment in lieu of notice.
]

#clause("8", "Confidentiality")[
  The Employee shall not, during or after the employment, disclose any trade secrets
  or confidential information of the Employer or its clients, except as required by law
  or in the proper performance of their duties.
]

#clause("9", "Entire Agreement")[
  This contract, together with the Employee Handbook, constitutes the entire agreement
  between the parties and supersedes all prior arrangements. Amendments must be in writing.
]

#v(22pt)
#g("signatures.place", default: "—"), #g("signatures.date", default: "—")
#v(26pt)
#grid(columns: (1fr, 1fr), column-gutter: 2cm,
  [
    #line(length: 100%, stroke: 0.7pt)
    #v(2pt)
    #text(size: 9pt)[For the Employer \ #g("employer.represented_by")]
  ],
  [
    #line(length: 100%, stroke: 0.7pt)
    #v(2pt)
    #text(size: 9pt)[The Employee \ #g("employee.name")]
  ])
