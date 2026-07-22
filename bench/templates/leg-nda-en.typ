// Mutual Non-Disclosure Agreement
// @description: NDA with parties, purpose, term, governing law, signatures
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#set page(paper: "a4", margin: (top: 2.6cm, bottom: 2.6cm, left: 2.8cm, right: 2.8cm),
  footer: [
    #set text(size: 8pt, fill: gray.darken(20%))
    #align(center)[Mutual Non-Disclosure Agreement · #g("party_a.company", default: "Party A") / #g("party_b.company", default: "Party B") · Page 1 of 1]
  ])
#set text(font: "Tinos", size: 10.5pt)
#set par(justify: true, leading: 0.72em)

#let clause(n, title, body) = {
  v(9pt)
  text(weight: "bold")[#n. #title.] + [ ] + body
}

#align(center)[
  #text(size: 15pt, weight: "bold", tracking: 1.5pt)[MUTUAL NON-DISCLOSURE AGREEMENT]
  #v(2pt)
  #line(length: 40%, stroke: 0.7pt)
]
#v(10pt)

This Mutual Non-Disclosure Agreement (the "*Agreement*") is entered into and effective as of *#g("nda.effective_date", default: "the date of last signature")* (the "*Effective Date*") by and between:

#v(6pt)
#grid(columns: (auto, 1fr), column-gutter: 12pt, row-gutter: 10pt,
  [*(1)*], [*#g("party_a.company", default: "Party A")*, with its registered office at #g("party_a.address", default: "—"), represented by #g("party_a.represented_by", default: "—") ("*Party A*"); and],
  [*(2)*], [*#g("party_b.company", default: "Party B")*, with its registered office at #g("party_b.address", default: "—"), represented by #g("party_b.represented_by", default: "—") ("*Party B*"),])
#v(4pt)

Party A and Party B are each referred to as a "*Party*" and together as the "*Parties*".

#clause(1, "Purpose")[
  The Parties wish to exchange certain confidential information in connection with
  #g("nda.purpose", default: "a potential business relationship between the Parties")
  (the "*Purpose*").
]

#clause(2, "Confidential Information")[
  "*Confidential Information*" means any information disclosed by one Party (the
  "*Disclosing Party*") to the other Party (the "*Receiving Party*"), whether in
  written, oral, electronic or other form, that is designated as confidential or
  that reasonably should be understood to be confidential given the nature of the
  information and the circumstances of disclosure, including business plans,
  technical data, specifications, know-how, financial information and customer data.
]

#clause(3, "Obligations of the Receiving Party")[
  The Receiving Party shall (a) use Confidential Information solely for the
  Purpose; (b) protect it with at least the same degree of care it uses for its own
  confidential information, and no less than reasonable care; (c) not disclose it
  to any third party without the prior written consent of the Disclosing Party; and
  (d) limit access to those of its employees and advisers who need to know it for
  the Purpose and who are bound by confidentiality obligations no less protective
  than those herein.
]

#clause(4, "Exclusions")[
  Confidential Information does not include information that (a) is or becomes
  publicly available through no breach of this Agreement; (b) was lawfully known to
  the Receiving Party prior to disclosure; (c) is lawfully received from a third
  party without restriction; or (d) is independently developed without use of the
  Confidential Information. Disclosures required by law or court order are
  permitted, provided the Receiving Party gives prompt notice where legally
  permissible.
]

#clause(5, "Term and Survival")[
  This Agreement shall remain in force for a period of
  *#g("nda.term_years", default: "—") years* from the Effective Date. The
  obligations of confidentiality shall survive expiry or termination of this
  Agreement for a further period of
  *#g("nda.survival_years", default: "—") years*.
]

#clause(6, "Return or Destruction")[
  Upon written request of the Disclosing Party, the Receiving Party shall promptly
  return or destroy all Confidential Information, including copies thereof, and
  confirm such destruction in writing.
]

#clause(7, "No Licence; No Obligation")[
  Nothing in this Agreement grants any licence or other rights in the Confidential
  Information, nor obliges either Party to enter into any further agreement.
]

#clause(8, "Governing Law and Jurisdiction")[
  This Agreement shall be governed by #g("nda.governing_law", default: "the governing law agreed by the Parties").
  Exclusive place of jurisdiction for all disputes arising out of or in connection
  with this Agreement shall be #g("nda.jurisdiction", default: "the competent courts at the seat of Party A").
]

#v(22pt)
#text(weight: "bold")[IN WITNESS WHEREOF], the Parties have executed this Agreement by their duly authorised representatives.

#v(26pt)
#grid(columns: (1fr, 1fr), column-gutter: 36pt, row-gutter: 6pt,
  [
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[
      *#g("party_a.company", default: "Party A")* \
      Name: #g("signatures.a_name", default: "") \
      Date: #g("signatures.a_date", default: "")
    ]
  ],
  [
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[
      *#g("party_b.company", default: "Party B")* \
      Name: #g("signatures.b_name", default: "") \
      Date: #g("signatures.b_date", default: "")
    ]
  ])
