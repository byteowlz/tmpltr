// byteowlz Projektsteckbrief Template

#import "@local/tmpltr-lib:1.0.0": tmpltr-data, brand-logo, brand-font, brand-color

#let data = tmpltr-data()

#let logo-path = brand-logo(data, variant: "primary", default: none)
#let primary-font = brand-font(data, usage: "body", default: "Helvetica Neue")
#let primary-color = brand-color(data, "primary", default: "#0f172a")

#set page(paper: "a4", margin: 2cm)
#set text(font: primary-font, size: 11pt)

Hello