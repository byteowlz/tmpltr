// Payment Reminder
// @description: Overdue invoice reminder with late fee and deadline
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

#let accent = rgb("#b23a2f")
#let ink = rgb("#20242b")

#set page(paper: "a4", margin: (top: 2cm, bottom: 2.6cm, left: 2.4cm, right: 2.2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(25%))
    #line(length: 100%, stroke: 0.5pt + gray.lighten(30%))
    #v(2pt)
    #grid(columns: (1fr, 1fr), column-gutter: 10pt,
      [#g("sender.company") · #g("sender.address") · #g("sender.city")],
      align(right)[IBAN #g("sender.iban") · BIC #g("sender.bic")])
  ])
#set text(font: "Adwaita Sans", size: 10pt, fill: ink)

// Header band
#grid(columns: (auto, 1fr),
  column-gutter: 10pt,
  align(horizon)[
    #box(fill: accent, inset: (x: 9pt, y: 7pt), radius: 2pt)[
      #text(fill: white, weight: "bold", size: 13pt)[BW]
    ]
  ],
  align(right + horizon)[
    #text(weight: "bold", size: 12pt)[#g("sender.company")] \
    #text(size: 8.5pt, fill: gray.darken(40%))[#g("sender.address") · #g("sender.city") \ #g("sender.phone") · #g("sender.email")]
  ])
#v(4pt)
#line(length: 100%, stroke: 1.5pt + accent)
#v(16pt)

#grid(columns: (1fr, auto), column-gutter: 24pt,
  [
    #g("recipient.company") \
    #g("recipient.contact") \
    #g("recipient.address") \
    #g("recipient.city")
  ],
  align(right)[
    #text(size: 9pt, fill: gray.darken(35%))[Date: #g("reminder.date")]
  ])
#v(20pt)

#text(size: 14pt, weight: "bold", fill: accent)[#g("reminder.level", default: "Payment Reminder") — Invoice #g("reminder.invoice_number")]
#v(10pt)

Dear #g("recipient.contact", default: "Sir or Madam"),

Despite our previous correspondence, our records show that the following
invoice remains unpaid. We kindly ask you to settle the outstanding balance
without further delay.

#v(8pt)
#block(stroke: 0.7pt + gray.lighten(20%), radius: 3pt, inset: 0pt, width: 100%)[
  #table(columns: (1fr, auto), stroke: none, inset: (x: 10pt, y: 6pt),
    fill: (_, row) => if calc.even(row) { rgb("#faf5f4") } else { white },
    [Invoice number], [*#g("reminder.invoice_number")*],
    [Invoice date], [#g("reminder.invoice_date")],
    [Original amount], [#money(g("reminder.original_amount", default: 0), sym: "£")],
    [Late payment fee], [#money(g("reminder.late_fee", default: 0), sym: "£")],
    table.hline(stroke: 1pt + accent),
    [#text(weight: "bold")[Total now due]], [#text(weight: "bold", fill: accent)[#money(g("reminder.total_due", default: 0), sym: "£")]])
]
#v(10pt)

Please transfer the total amount by *#g("reminder.deadline")* to the account
below, quoting invoice number #g("reminder.invoice_number") as the payment
reference:

#pad(left: 8pt, top: 4pt)[
  #text(size: 9.5pt)[
    IBAN: *#g("sender.iban")* \
    BIC: #g("sender.bic")
  ]
]
#v(8pt)

If payment is not received by the stated deadline, we reserve the right to
initiate formal debt-collection proceedings and to charge statutory interest
under the Late Payment of Commercial Debts (Interest) Act 1998. Should your
payment have crossed this letter, please disregard this reminder.

#v(14pt)
Yours sincerely,
#v(18pt)
*Accounts Receivable* \
#g("sender.company")
