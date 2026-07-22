// Darlehensvertrag
// @description: Privatdarlehen: Parteien, Summe, Zins, Tilgung, Unterschriften
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
#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}

#set page(paper: "a4", margin: (top: 2.6cm, bottom: 2.6cm, left: 2.6cm, right: 2.4cm),
  footer: [
    #set text(size: 8pt, fill: gray.darken(30%))
    #align(center)[Darlehensvertrag · #g("darlehensgeber.name") / #g("darlehensnehmer.name") · Seite 1 von 1]
  ])
#set text(font: "New Computer Modern", size: 10.5pt, lang: "de")
#set par(justify: true, leading: 0.62em)

#align(center)[
  #text(size: 17pt, weight: "bold")[Darlehensvertrag]
  #v(2pt)
  #text(size: 9.5pt, fill: gray.darken(50%))[— privates Gelddarlehen gemäß §§ 488 ff. BGB —]
]
#v(14pt)

Zwischen

#pad(left: 1.2cm)[
  *#g("darlehensgeber.name")* \
  #g("darlehensgeber.strasse"), #g("darlehensgeber.plz_ort") \
  #text(size: 9pt, fill: gray.darken(40%))[— nachfolgend „Darlehensgeber" —]
]

und

#pad(left: 1.2cm)[
  *#g("darlehensnehmer.name")*, geboren am #g("darlehensnehmer.geburtsdatum") \
  #g("darlehensnehmer.strasse"), #g("darlehensnehmer.plz_ort") \
  #text(size: 9pt, fill: gray.darken(40%))[— nachfolgend „Darlehensnehmer" —]
]

wird folgender Darlehensvertrag geschlossen:

#v(6pt)
#let par-title(no, t) = [
  #v(8pt)
  #text(weight: "bold")[§ #no #h(4pt) #t]
  #v(2pt)
]

#par-title(1)[Darlehenssumme und Auszahlung]
Der Darlehensgeber gewährt dem Darlehensnehmer ein Darlehen in Höhe von
*#geld(g("darlehen.betrag", default: 0))*. Die Auszahlung erfolgt am
#g("darlehen.auszahlungsdatum") durch Überweisung auf das Konto des
Darlehensnehmers, IBAN *#g("darlehen.iban")*.

#par-title(2)[Verwendungszweck]
Das Darlehen dient folgendem Zweck: #g("darlehen.verwendung", default: "keiner besonderen Zweckbindung").

#par-title(3)[Verzinsung]
Das Darlehen wird mit *#(str(g("darlehen.zinssatz", default: 0)).replace(".", ",")) % p. a.* verzinst.
Die Zinsen werden auf den jeweils offenen Darlehensbetrag berechnet und sind
mit den monatlichen Raten fällig.

#par-title(4)[Rückzahlung]
Die Rückzahlung erfolgt in *#g("darlehen.laufzeit_monate", default: 0) gleichbleibenden
Monatsraten* zu je *#geld(g("darlehen.rate", default: 0))* (Zins und Tilgung),
jeweils fällig zum Monatsersten, erstmals im Folgemonat nach Auszahlung.
Sondertilgungen sind jederzeit ohne Vorfälligkeitsentschädigung zulässig.

#par-title(5)[Kündigung]
Bei Zahlungsverzug mit mindestens zwei aufeinanderfolgenden Raten kann der
Darlehensgeber den Vertrag fristlos kündigen und die Restschuld sofort fällig
stellen. Im Übrigen gelten die gesetzlichen Kündigungsregelungen der
§§ 488 Abs. 3, 489 BGB.

#par-title(6)[Schlussbestimmungen]
Änderungen und Ergänzungen dieses Vertrages bedürfen der Schriftform. Sollte
eine Bestimmung unwirksam sein, bleibt der Vertrag im Übrigen wirksam.

#v(26pt)
#g("unterschrift.ort"), den #g("unterschrift.datum")
#v(30pt)
#grid(columns: (1fr, 1cm, 1fr),
  [
    #line(length: 100%, stroke: 0.7pt)
    #v(1pt)
    #text(size: 8.5pt)[#g("darlehensgeber.name") (Darlehensgeber)]
  ],
  [],
  [
    #line(length: 100%, stroke: 0.7pt)
    #v(1pt)
    #text(size: 8.5pt)[#g("darlehensnehmer.name") (Darlehensnehmer)]
  ])
