// Consumer Loan Agreement Summary
// @description: Loan terms: principal, APR, schedule, parties, signatures
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

#let cur = g("loan.currency", default: "GBP")
#let sym = if cur == "EUR" { "€" } else if cur == "USD" { "$" } else { "£" }
#let navy = rgb("#14213d")

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.4cm, left: 2.4cm, right: 2.4cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #g("lender.name") · #g("lender.regulator_id") #h(1fr) Agreement ref. LN-#g("loan.term_months", default: "0")-#g("signatures.date", default: "")
  ])
#set text(font: "Libertinus Serif", size: 10pt)
#set par(justify: true)

#align(center)[
  #text(size: 16pt, weight: "bold", fill: navy)[Consumer Loan Agreement — Summary of Terms]
  #v(2pt)
  #text(size: 9pt, fill: gray.darken(30%))[Regulated by the Consumer Credit Act 1974 (as amended)]
  #v(4pt)
  #line(length: 40%, stroke: 1pt + navy)
]
#v(10pt)

*This agreement is made between:*
#v(4pt)
#grid(columns: (1fr, 1fr), column-gutter: 18pt,
  block(stroke: 0.6pt + navy, inset: 9pt, radius: 2pt, width: 100%)[
    #text(size: 8pt, weight: "bold", fill: navy)[THE LENDER] \
    #v(2pt)
    #text(weight: "bold")[#g("lender.name")] \
    #g("lender.address") \
    #text(size: 8.5pt)[#g("lender.regulator_id")]
  ],
  block(stroke: 0.6pt + navy, inset: 9pt, radius: 2pt, width: 100%)[
    #text(size: 8pt, weight: "bold", fill: navy)[THE BORROWER] \
    #v(2pt)
    #text(weight: "bold")[#g("borrower.name")] \
    #g("borrower.address") \
    #text(size: 8.5pt)[Date of birth: #g("borrower.dob") · #g("borrower.email")]
  ])
#v(12pt)

#text(size: 11pt, weight: "bold", fill: navy)[1. Key financial terms]
#v(4pt)
#table(columns: (1fr, 1fr), stroke: 0.5pt + gray.lighten(30%), inset: 6.5pt,
  [Amount of credit (principal)], [*#money(g("loan.amount", default: 0), sym: sym)*],
  [Annual Percentage Rate (APR)], [*#g("loan.apr", default: "0")% APR* (fixed)],
  [Duration of agreement], [#g("loan.term_months", default: "0") monthly instalments],
  [Monthly repayment], [#money(g("loan.monthly_payment", default: 0), sym: sym), due on the 1st of each month],
  [First repayment date], [#g("loan.first_payment_date")],
  [Purpose of the loan], [#g("loan.purpose")],
  [Disbursement account], [#g("loan.account_iban")])
#v(8pt)

#text(size: 11pt, weight: "bold", fill: navy)[2. Repayment]
#v(3pt)
The Borrower shall repay the credit in equal monthly instalments as set out above, by direct
debit from the account nominated in the direct debit mandate. Early repayment is permitted in
full or in part at any time; a rebate of charges will be calculated in accordance with the
Consumer Credit (Early Settlement) Regulations 2004.
#v(6pt)

#text(size: 11pt, weight: "bold", fill: navy)[3. Right of withdrawal]
#v(3pt)
The Borrower may withdraw from this agreement, without giving any reason, within 14 calendar
days beginning on the day after the day this agreement is made, by giving notice to the Lender
and repaying the credit together with accrued interest.
#v(6pt)

#text(size: 11pt, weight: "bold", fill: navy)[4. Missing payments]
#v(3pt)
Missing payments could have severe consequences: default interest and reasonable costs may be
charged, the whole outstanding balance may become due, and missed payments will be reported to
credit reference agencies, making it more difficult or more expensive to obtain credit.
#v(6pt)

#text(size: 11pt, weight: "bold", fill: navy)[5. Signatures]
#v(3pt)
This is a summary of the principal terms. The full agreement, including the pre-contract credit
information (SECCI), has been provided to the Borrower.
#v(16pt)

#grid(columns: (1fr, 1fr), column-gutter: 28pt,
  [
    #line(length: 100%, stroke: 0.7pt + black)
    #v(2pt)
    #text(size: 8.5pt)[Signature of the Lender \ #g("lender.name") \ #g("signatures.place"), #g("signatures.date")]
  ],
  [
    #line(length: 100%, stroke: 0.7pt + black)
    #v(2pt)
    #text(size: 8.5pt)[Signature of the Borrower \ #g("borrower.name") \ #g("signatures.place"), #g("signatures.date")]
  ])
