// Subscription Confirmation
// @description: Plan, billing cycle, next renewal and cancellation policy
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

#let violet = rgb("#5b3fd4")
#let cur = g("subscription.currency", default: "USD")
#let sym = if cur == "EUR" { "€" } else if cur == "GBP" { "£" } else { "$" }

#set page(paper: "a4", margin: (x: 2.4cm, top: 2cm, bottom: 2.2cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(20%))
    #align(center)[
      #g("provider.name") · #g("provider.address") · #g("provider.support_email")
    ]
  ])
#set text(font: "Adwaita Sans", size: 10pt)

// Gradient-style header band
#block(width: 100%, fill: violet, inset: (x: 16pt, y: 14pt), radius: 4pt)[
  #grid(columns: (1fr, auto), align: horizon,
    [
      #text(fill: white, size: 18pt, weight: "bold")[#g("provider.name", default: "Your subscription")]
      #v(2pt)
      #text(fill: white.transparentize(20%), size: 10pt)[Subscription confirmed — welcome aboard!]
    ],
    box(fill: white, inset: (x: 8pt, y: 6pt), radius: 3pt)[
      #text(fill: violet, weight: "bold", size: 9pt)[ACTIVE]
    ])
]
#v(12pt)

Hi #g("customer.name", default: "there"),

Thanks for subscribing! Your plan is now active on the account
#text(weight: "bold")[#g("customer.email", default: "linked to this confirmation")]
(customer no. #g("customer.customer_no", default: "—")). Here is a summary of your subscription:

#v(10pt)

// Plan card
#block(width: 100%, stroke: 1pt + violet.lighten(50%), radius: 4pt, inset: 0pt, clip: true)[
  #block(width: 100%, fill: violet.lighten(88%), inset: (x: 12pt, y: 8pt))[
    #grid(columns: (1fr, auto), align: horizon,
      text(size: 12.5pt, weight: "bold", fill: violet)[#g("subscription.plan", default: "Subscription plan")],
      text(size: 12.5pt, weight: "bold")[#money(g("subscription.price", default: 0), sym: sym) / #g("subscription.billing_cycle", default: "month")])
  ]
  #block(width: 100%, inset: 12pt)[
    #set text(size: 9.5pt)
    #grid(columns: (1fr, 1fr), column-gutter: 20pt, row-gutter: 8pt,
      [#text(size: 8pt, fill: gray.darken(40%))[START DATE] \ #text(weight: "bold")[#g("subscription.start_date", default: "—")]],
      [#text(size: 8pt, fill: gray.darken(40%))[NEXT RENEWAL] \ #text(weight: "bold")[#g("subscription.next_renewal", default: "—")]],
      [#text(size: 8pt, fill: gray.darken(40%))[BILLING CYCLE] \ #g("subscription.billing_cycle", default: "—")],
      [#text(size: 8pt, fill: gray.darken(40%))[PAYMENT METHOD] \ #g("subscription.payment_method", default: "—") #if g("subscription.card_last4") != "" [ending in •••• #g("subscription.card_last4")]])
  ]
]
#v(10pt)

Your subscription renews automatically. On #text(weight: "bold")[#g("subscription.next_renewal", default: "the renewal date")] we will charge #text(weight: "bold")[#money(g("subscription.price", default: 0), sym: sym)] to your #g("subscription.payment_method", default: "payment method") on file. You will receive a receipt by email after each successful payment.

#v(10pt)

#text(size: 10.5pt, weight: "bold", fill: violet)[Cancellation policy]
#v(3pt)
#block(width: 100%, stroke: (left: 3pt + violet.lighten(40%)), inset: (left: 10pt, y: 3pt))[
  #text(size: 9.5pt)[#g("subscription.cancellation_policy", default: "You can cancel your subscription at any time from your account settings.")]
]
#v(10pt)

#text(size: 9.5pt)[
  Questions? Our support team is happy to help at
  #text(weight: "bold", fill: violet)[#g("provider.support_email")] — just mention your
  customer number #text(weight: "bold")[#g("customer.customer_no", default: "—")].
]

#v(10pt)
Enjoy! \
#text(weight: "bold")[The #g("provider.name", default: "Support") Team]

#v(16pt)
#line(length: 100%, stroke: 0.5pt + gray.lighten(40%))
#v(4pt)
#text(size: 8pt, fill: gray.darken(20%))[
  This is a confirmation of a subscription agreement, not an invoice. Prices include
  applicable taxes unless stated otherwise. Keep this message for your records.
]
