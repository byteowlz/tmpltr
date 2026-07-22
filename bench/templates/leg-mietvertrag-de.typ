// Mietvertrag Wohnraum
// @description: Wohnungsmietvertrag: Objekt, Miete, Nebenkosten, Kaution
// @version: 1.0.0
#import "@local/tmpltr-lib:1.0.0": tmpltr-data, get

#let data = tmpltr-data()
#let g(path, default: "") = get(data, path, default: default)

#let ink = rgb("#1f2a1f")
#let accent = rgb("#2e5a34")

#set page(paper: "a4", margin: (top: 2.2cm, bottom: 2.4cm, left: 2.4cm, right: 2.2cm),
  footer: [
    #set text(size: 8pt, fill: gray.darken(35%))
    #line(length: 100%, stroke: 0.4pt + gray)
    #v(2pt)
    #grid(columns: (1fr, auto), [Mietvertrag über Wohnraum · #g("objekt.strasse"), #g("objekt.plz_ort")], [Seite #context counter(page).display() von #context counter(page).final().first()])
  ])
#set text(font: "Tinos", size: 10.5pt, fill: ink, lang: "de")
#set par(justify: true, leading: 0.62em)

#align(center)[
  #text(size: 17pt, weight: "bold", tracking: 0.6pt)[MIETVERTRAG]
  #v(1pt)
  #text(size: 11pt)[über Wohnraum]
  #v(3pt)
  #line(length: 42%, stroke: 1.2pt + accent)
]
#v(10pt)

#grid(columns: (1fr, 1fr), column-gutter: 20pt,
  [
    #text(size: 8.5pt, tracking: 1pt, fill: accent, weight: "bold")[VERMIETER] \
    #v(2pt)
    #text(weight: "bold")[#g("vermieter.name", default: "—")] \
    #g("vermieter.strasse", default: "—") \
    #g("vermieter.plz_ort", default: "—")
  ],
  [
    #text(size: 8.5pt, tracking: 1pt, fill: accent, weight: "bold")[MIETER] \
    #v(2pt)
    #text(weight: "bold")[#g("mieter.name", default: "—")] \
    #g("mieter.strasse", default: "—") \
    #g("mieter.plz_ort", default: "—") \
    #if g("mieter.geburtsdatum") != "" [geboren am #g("mieter.geburtsdatum")]
  ])
#v(6pt)
#align(center)[#text(style: "italic")[— nachstehend „Vermieter" und „Mieter" genannt — wird folgender Mietvertrag geschlossen:]]
#v(8pt)

#let para(nr, title, body) = {
  v(7pt)
  text(weight: "bold")[§ #nr #h(6pt) #title]
  v(3pt)
  body
}

#para(1, [Mieträume])[
  Der Vermieter vermietet dem Mieter zu Wohnzwecken die Wohnung
  #text(weight: "bold")[#g("objekt.strasse", default: "—"), #g("objekt.plz_ort", default: "—")],
  #g("objekt.etage", default: "—"), bestehend aus #g("objekt.zimmer", default: "—") Zimmern,
  Küche, Bad, Diele, mit einer Wohnfläche von ca. #g("objekt.flaeche_qm", default: "—") m².
  #if g("objekt.stellplatz") != "" [Mitvermietet wird: #g("objekt.stellplatz").]
]

#para(2, [Mietzeit])[
  Das Mietverhältnis beginnt am #text(weight: "bold")[#g("miete.mietbeginn", default: "—")]
  und läuft auf unbestimmte Zeit. Es kann von beiden Parteien unter Einhaltung
  der gesetzlichen Fristen (§ 573c BGB) gekündigt werden.
]

#para(3, [Miete und Nebenkosten])[
  Die monatliche Miete setzt sich wie folgt zusammen:
  #v(4pt)
  #table(
    columns: (1fr, auto),
    align: (left, right),
    stroke: (x, y) => (bottom: 0.4pt + gray.darken(20%)),
    inset: (x: 8pt, y: 5pt),
    fill: (_, row) => if row == 3 { accent.lighten(88%) } else { white },
    [Grundmiete (Kaltmiete)], [#g("miete.kalt", default: "—") €],
    [Vorauszahlung Betriebskosten], [#g("miete.nebenkosten_vorauszahlung", default: "—") €],
    [Vorauszahlung Heizung/Warmwasser], [#g("miete.heizkosten_vorauszahlung", default: "—") €],
    [#text(weight: "bold")[Gesamtmiete monatlich]], [#text(weight: "bold")[#g("miete.gesamt", default: "—") €]],
  )
  #v(4pt)
  Die Miete ist #g("miete.zahlungsweise", default: "monatlich im Voraus") auf das Konto
  des Vermieters, IBAN #text(weight: "bold")[#g("miete.iban", default: "—")], zu zahlen.
  Über die Betriebskosten wird jährlich abgerechnet.
]

#para(4, [Kaution])[
  Der Mieter leistet eine Mietsicherheit in Höhe von
  #text(weight: "bold")[#g("miete.kaution", default: "—") €] (§ 551 BGB).
  Die Zahlung kann in drei gleichen monatlichen Teilbeträgen erfolgen; die erste
  Rate ist bei Mietbeginn fällig. Die Kaution wird getrennt vom Vermögen des
  Vermieters verzinslich angelegt.
]

#para(5, [Schönheitsreparaturen und Instandhaltung])[
  Die Schönheitsreparaturen während der Mietzeit übernimmt der Mieter, soweit
  sie durch seinen Gebrauch erforderlich werden. Kleinreparaturen trägt der
  Mieter bis 100 € im Einzelfall, höchstens 8 % der Jahreskaltmiete pro Jahr.
]

#para(6, [Sonstiges])[
  Untervermietung bedarf der vorherigen schriftlichen Zustimmung des Vermieters.
  Änderungen und Ergänzungen dieses Vertrags bedürfen der Textform. Sollten
  einzelne Bestimmungen unwirksam sein, bleibt der Vertrag im Übrigen wirksam.
]

#v(20pt)
#g("unterschrift.ort", default: "—"), den #g("unterschrift.datum", default: "—")
#v(26pt)
#grid(columns: (1fr, 1fr), column-gutter: 1.8cm,
  [
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[Vermieter]
  ],
  [
    #line(length: 100%, stroke: 0.7pt)
    #text(size: 9pt)[Mieter]
  ])
