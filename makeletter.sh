#!/bin/sh

# Build more common/shorter Resume format
pandoc -s --template=tex/lettertemplate.tex -o tex/letter.tex \
	cv/contact.md \
	letter.md

cd tex/
pdflatex letter.tex
