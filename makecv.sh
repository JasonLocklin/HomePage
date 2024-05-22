#!/bin/zsh

# Build CV
pandoc -s --template=tex/template.tex -o tex/locklin.tex \
  cv/contact.md \
	cv/professional_summary.md \
	cv/education.md \
	cv/research_experience.md \
	cv/affiliations.md \
	cv/service_activities.md \
	cv/funding.md \
	cv/professional_development.md \
	cv/teaching_experience.md \
	cv/publications.md \
	cv/skills.md \
  cv/footnote.md

pandoc -s -o cv.md \
  cv/contact.md \
  cv/professional_summary.md \
	cv/education.md \
	cv/research_experience.md \
	cv/affiliations.md \
	cv/service_activities.md \
	cv/funding.md \
	cv/professional_development.md \
	cv/teaching_experience.md \
	cv/publications.md \
	cv/skills.md

#CV uses section headings only
sed -i '' 's/subsection/section/' tex/locklin.tex
sed -i '' 's/subsection/section/' tex/locklin.tex
sed -i '' 's/[[:space:]]\\begin{itemize}/\\begin{innerlist}/' tex/locklin.tex
sed -i '' 's/\\begin{itemize}/\\begin{outerlist}/' tex/locklin.tex  #CV uses outerlist/innerlist instead of itemize
sed -i '' 's/[[:space:]]\\end{itemize}/\\end{innerlist}/' tex/locklin.tex
sed -i '' 's/\\end{itemize}/\\end{outerlist}/' tex/locklin.tex  #CV uses outerlist/innerlist instead of itemize

cd tex/
pdflatex locklin.tex
cd ..
mv tex/locklin.pdf static/CV_Jason_Locklin.pdf
