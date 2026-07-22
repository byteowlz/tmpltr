// Lease Termination Notice
// @description: Tenant/landlord notice with move-out date and deposit handling
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(paper: "a4", margin: (top: 2.6cm, bottom: 2.6cm, left: 2.8cm, right: 2.8cm))
#set text(font: "Libertinus Serif", size: 11pt)
#set par(justify: true, leading: 0.68em)

// Sender block, top right (personal letter style)
#align(right)[
  #text(weight: "bold")[#g("sender.name", default: "—")] \
  #g("sender.address", default: "—") \
  #g("sender.city", default: "—")
]
#v(16pt)

#g("recipient.name", default: "—") \
#g("recipient.address", default: "—") \
#g("recipient.city", default: "—")

#v(14pt)
#align(right)[#g("termination.termination_date", default: "")]
#v(14pt)

#text(weight: "bold")[Re: Notice of Lease Termination — #g("termination.property_address", default: "—")]
#v(4pt)
#line(length: 100%, stroke: 0.5pt + gray.darken(20%))
#v(8pt)

Dear #g("recipient.name", default: "Sir or Madam"),

#v(4pt)
I am writing to provide formal notice that I am terminating my tenancy of the
premises at #text(weight: "bold")[#g("termination.property_address", default: "—")],
held under the lease agreement commencing #g("termination.lease_start", default: "—").
This letter constitutes the required #g("termination.notice_period", default: "—")
written notice under the terms of the lease.

#v(6pt)
The tenancy will end on #text(weight: "bold")[#g("termination.termination_date", default: "—")].
I intend to vacate the premises and return all keys on or before
#text(weight: "bold")[#g("termination.move_out_date", default: "—")]. I would be glad to
arrange a joint move-out inspection during the final week of the tenancy; please
let me know two or three times that suit you.

#v(6pt)
#box(width: 100%, stroke: (left: 2pt + gray.darken(30%)), inset: (left: 10pt, y: 6pt))[
  #text(size: 10pt)[
    *Security deposit.* I request that my security deposit of
    #text(weight: "bold")[#g("termination.deposit_amount", default: "—")] be returned
    within the statutory period to the following account:
    #g("termination.deposit_iban", default: "—"). Any itemized statement of
    deductions and all future correspondence should be sent to my forwarding
    address: #g("termination.forwarding_address", default: "—").
  ]
]

#v(6pt)
The apartment will be left clean and in the condition required by the lease,
ordinary wear and tear excepted. Utility providers will be notified of the
final meter readings on the move-out date.

#v(6pt)
Thank you for your cooperation during my tenancy. Please confirm receipt of
this notice in writing.

#v(14pt)
Sincerely,
#v(30pt)
#line(length: 45%, stroke: 0.7pt)
#g("sender.name", default: "—") \
#text(size: 9.5pt, fill: gray.darken(45%))[#g("sender.role", default: "Tenant")]
