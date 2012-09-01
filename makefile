#Recreate CV and main page whenever something needs to be updated
# Jason Locklin
#


all : website cv publish


website:
	pandoc -s --template=template.html -o index.html current_research.md \
		publications.md interests.md
cv:
	pandoc -s --template=tex/template.tex -o tex/locklin.tex education.md \
		publications.md awards.md teaching.md research_experience.md \
		other_experience.md expertise.md interests.md
	sed -i 's/subsection/section/' tex/locklin.tex  #CV uses section headings only
	sed -i 's/subsection/section/' tex/locklin.tex  #CV uses section headings only
	sed -i 's/\s\\begin{itemize}/\\begin{innerlist}/' tex/locklin.tex 
	sed -i 's/\\begin{itemize}/\\begin{outerlist}/' tex/locklin.tex  #CV uses outerlist/innerlist instead of itemize
	sed -i 's/\s\\end{itemize}/\\end{innerlist}/' tex/locklin.tex 
	sed -i 's/\\end{itemize}/\\end{outerlist}/' tex/locklin.tex  #CV uses outerlist/innerlist instead of itemize
	cd tex/ && pdflatex locklin.tex

publish:
	git pull
	git commit -a
	git push
