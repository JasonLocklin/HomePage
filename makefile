#Recreate CV and main page whenever something needs to be updated
# Jason Locklin
#


all : website cv publish


website:
	pandoc -s --template=template.html -o index.html \
		publications.md interests.md affiliations.md
cv:
	pandoc -s --template=tex/template.tex -o tex/locklin.tex geom.md heading.md summary.md education.md \
		publications.md  leadership_roles.md research_experience.md teaching.md \
		training.md  expertise.md awards.md affiliations.md
	#CV uses section headings only
	sed -i 's/subsection/section/' tex/locklin.tex  
	sed -i 's/subsection/section/' tex/locklin.tex  
	sed -i 's/\s\\begin{itemize}/\\begin{innerlist}/' tex/locklin.tex 
	sed -i 's/\\begin{itemize}/\\begin{outerlist}/' tex/locklin.tex  #CV uses outerlist/innerlist instead of itemize
	sed -i 's/\s\\end{itemize}/\\end{innerlist}/' tex/locklin.tex 
	sed -i 's/\\end{itemize}/\\end{outerlist}/' tex/locklin.tex  #CV uses outerlist/innerlist instead of itemize
	cd tex/ && pdflatex locklin.tex
cl:
	pandoc -s --template=tex/template.tex -o cover_letter.tex heading.md cover_letter.md \
		geom.md heading.md summary.md education.md \
		publications.md  leadership_roles.md research_experience.md teaching.md \
		training.md  expertise.md awards.md affiliations.md
	#CV uses section headings only
	sed -i 's/subsection/section/' cover_letter.tex  
	sed -i 's/subsection/section/' cover_letter.tex  
	sed -i 's/\s\\begin{itemize}/\\begin{innerlist}/' cover_letter.tex 
	sed -i 's/\\begin{itemize}/\\begin{outerlist}/' cover_letter.tex  #CV uses outerlist/innerlist instead of itemize
	sed -i 's/\s\\end{itemize}/\\end{innerlist}/' cover_letter.tex 
	sed -i 's/\\end{itemize}/\\end{outerlist}/' cover_letter.tex  #CV uses outerlist/innerlist instead of itemize
	pdflatex cover_letter.tex

publish:
	git pull
	git commit -a
	git push
	ssh jalockli@artsweb.uwaterloo.ca "cd public_html; git pull; chmod a+r * -R"
