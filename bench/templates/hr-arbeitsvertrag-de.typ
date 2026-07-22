// Arbeitsvertrag
// @description: Deutscher Arbeitsvertrag mit Paragraphen: Tätigkeit, Vergütung, Urlaub, Kündigungsfristen
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

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.4cm, x: 2.5cm),
  footer: [
    #set text(size: 7.5pt, fill: gray.darken(40%))
    #align(center)[#g("arbeitgeber.firma") · #g("arbeitgeber.strasse") · #g("arbeitgeber.plz_ort") — Seite 1 von 1]
  ])
#set text(font: "Libertinus Serif", size: 10.5pt)
#set par(justify: true, leading: 0.6em)

#align(center)[
  #text(size: 16pt, weight: "bold")[Arbeitsvertrag]
]
#v(2pt)
#align(center)[#line(length: 34%, stroke: 0.8pt)]
#v(10pt)

Zwischen

#pad(left: 1cm)[
  der *#g("arbeitgeber.firma")*, #g("arbeitgeber.strasse"), #g("arbeitgeber.plz_ort"), \
  vertreten durch #g("arbeitgeber.vertreten_durch")
  #h(1fr) — nachfolgend „*Arbeitgeber*" —
]
#v(4pt)
und
#v(4pt)
#pad(left: 1cm)[
  #text(weight: "bold")[#g("arbeitnehmer.name")], #g("arbeitnehmer.strasse"),
  #g("arbeitnehmer.plz_ort"), geboren am #g("arbeitnehmer.geburtsdatum")
  #h(1fr) — nachfolgend „*Arbeitnehmerin*" —
]
#v(4pt)
wird folgender Arbeitsvertrag geschlossen:

#let par-sec(no, title, body) = {
  v(9pt)
  align(center)[#text(weight: "bold")[§ #no #h(6pt) #title]]
  v(3pt)
  body
}

#par-sec(1, "Beginn und Art der Tätigkeit")[
  Das Arbeitsverhältnis beginnt am *#g("vertrag.beginn", default: "—")*. Die
  Arbeitnehmerin wird als *#g("vertrag.position", default: "—")* in der Abteilung
  #g("vertrag.abteilung", default: "—") eingestellt. Der Arbeitgeber behält sich vor,
  ihr eine andere zumutbare, ihrer Qualifikation entsprechende Tätigkeit zu übertragen.
]

#par-sec(2, "Probezeit")[
  Die ersten *#g("vertrag.probezeit_monate", default: "—") Monate* gelten als Probezeit.
  Während der Probezeit kann das Arbeitsverhältnis beiderseits mit einer Frist von zwei
  Wochen gekündigt werden (§ 622 Abs. 3 BGB).
]

#par-sec(3, "Arbeitsort")[
  Arbeitsort ist *#g("vertrag.arbeitsort", default: "—")*. Der Arbeitgeber ist
  berechtigt, die Arbeitnehmerin vorübergehend an anderen Standorten des Unternehmens
  einzusetzen, soweit dies zumutbar ist.
]

#par-sec(4, "Arbeitszeit")[
  Die regelmäßige wöchentliche Arbeitszeit beträgt
  *#g("vertrag.wochenstunden", default: "—") Stunden*. Beginn und Ende der täglichen
  Arbeitszeit richten sich nach den betrieblichen Regelungen.
]

#par-sec(5, "Vergütung")[
  Die Arbeitnehmerin erhält ein monatliches Bruttogehalt in Höhe von
  *#geld(g("vertrag.brutto_monatsgehalt", default: 0))*, zahlbar bargeldlos jeweils
  zum Monatsende. Überstunden sind mit der Vergütung abgegolten, soweit sie 10 % der
  regelmäßigen Arbeitszeit nicht übersteigen.
]

#par-sec(6, "Urlaub")[
  Der Urlaubsanspruch beträgt *#g("vertrag.urlaubstage", default: "—") Arbeitstage*
  im Kalenderjahr. Der Urlaub ist rechtzeitig unter Berücksichtigung der betrieblichen
  Belange abzustimmen.
]

#par-sec(7, "Krankheit")[
  Im Falle der Arbeitsunfähigkeit gelten die gesetzlichen Bestimmungen des
  Entgeltfortzahlungsgesetzes. Die Arbeitnehmerin ist verpflichtet, dem Arbeitgeber
  die Arbeitsunfähigkeit unverzüglich anzuzeigen.
]

#par-sec(8, "Kündigung")[
  Nach Ablauf der Probezeit kann das Arbeitsverhältnis beiderseits mit einer Frist von
  *#g("vertrag.kuendigungsfrist_wochen", default: "—") Wochen* zum Fünfzehnten oder zum
  Ende eines Kalendermonats gekündigt werden. Längere gesetzliche Kündigungsfristen
  gelten für beide Parteien. Die Kündigung bedarf der Schriftform.
]

#par-sec(9, "Verschwiegenheit")[
  Die Arbeitnehmerin verpflichtet sich, über alle Betriebs- und Geschäftsgeheimnisse
  während und nach Beendigung des Arbeitsverhältnisses Stillschweigen zu bewahren.
]

#par-sec(10, "Schlussbestimmungen")[
  Änderungen und Ergänzungen dieses Vertrages bedürfen der Schriftform. Sollten
  einzelne Bestimmungen unwirksam sein, bleibt die Wirksamkeit des Vertrages im
  Übrigen unberührt.
]

#v(20pt)
#g("unterschrift.ort", default: "—"), den #g("unterschrift.datum", default: "—")
#v(28pt)
#grid(columns: (1fr, 1fr), column-gutter: 2cm,
  [
    #line(length: 100%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[Arbeitgeber \ #g("arbeitgeber.vertreten_durch")]
  ],
  [
    #line(length: 100%, stroke: 0.6pt)
    #v(2pt)
    #text(size: 9pt)[Arbeitnehmerin \ #g("arbeitnehmer.name")]
  ])
