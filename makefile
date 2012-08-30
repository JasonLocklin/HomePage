#Recreate CV and main page whenever something needs to be updated
# Jason Locklin
#


all : cv web apa.csl


#git pull


index.html: template.html
	pandoc -s --template=template.html -o index.html current_research.md \
		publications.md interests.md

apa.csl:
	wget "http://zotero.org/styles/apa" -O apa.csl 

citations.md: locklin.bib
	#Note, in makefiles, $ needs to be doubled.
	grep "@" locklin.bib | sed 's/@[a-zA-Z]*{/@/' | sed ':a;N;$$!ba;s/\n/ /g'  | sed 's/,$$/]/g' | sed 's/^/[/' > citations.md

	
cv.md: apa.csl citations.md
	pandoc --bibliography locklin.bib --csl=apa.csl -o cv.md citations.md
	tail cv.md -n+2 > cv2.md #this leaves just the bibliography
	#pandoc -S --bibliography locklin.bib --csl=apa.csl -o cv.pdf locklin.md
	#pandoc -t latex --natbib locklin.bib --csl=apa.csl #uncomment for natbib
