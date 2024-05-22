#!/bin/sh

# Build more common/shorter Resume format
pandoc -s --template=tex/template.tex -o tex/resume.tex \
	cv/wrdsbcontact.md \
	cv/professional_summary.md \
	cv/education.md \
	cv/research_experience.md \
	cv/affiliations.md \
	cv/professional_development.md \
	cv/service_activities.md \
	cv/publications.md \
	cv/references.md

pandoc -s -o cv.md \
	cv/contact.md

#CV uses section headings only
sed -i '' 's/subsection/section/' tex/resume.tex
sed -i '' 's/subsection/section/' tex/resume.tex
sed -i '' 's/[[:space:]]\\begin{itemize}/\\begin{innerlist}/' tex/resume.tex
sed -i '' 's/\\begin{itemize}/\\begin{outerlist}/' tex/resume.tex #CV uses outerlist/innerlist instead of itemize
sed -i '' 's/[[:space:]]\\end{itemize}/\\end{innerlist}/' tex/resume.tex
sed -i '' 's/\\end{itemize}/\\end{outerlist}/' tex/resume.tex #CV uses outerlist/innerlist instead of itemize

cd tex/
pdflatex resume.tex
cd ..
mv tex/resume.pdf static/Jason_Locklin_Resume.pdf
