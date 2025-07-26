#!/bin/sh

# Make short versions of service activities and professional dev by
# drop pagebreak 2s
# remove blank lines
# re-add blank lines after :
# re-add blank lines before \commands
cd cv
grep -v '^\  \-\ ' graduate_research_experience.md | grep -v 'pagebreak\[2\]' | grep -v '^$' | perl -pe 's/:(?=\n)/:\n\n/g' | perl -pe '$_ = "\n" . $_ if /^\s*\\/' > graduate_research_experience_short.md
grep -v '^\  \-\ ' service_activities.md | grep -v 'pagebreak\[2\]' | grep -v '^$' | perl -pe '$_ = "\n" . $_ if /^\s*\\/' > service_activities_short.md
grep -v '^\  \-\ ' professional_development.md | grep -v 'pagebreak\[2\]' | grep -v '^$' | perl -pe '$_ = "\n" . $_ if /^\s*\\/' > professional_development_short.md
cd ..
# publications_short.md references an online list and is made manually


# Build more common/shorter Resume format
pandoc -s --template=tex/template.tex -o tex/resume.tex \
	cv/professional_summary.md \
	cv/career_aim.md \
	cv/education.md \
	cv/teaching_experience.md \
	cv/research_experience.md \
	cv/graduate_research_experience.md \
	cv/service_activities.md \
	cv/affiliations.md \
	cv/professional_development.md \
	cv/graduate_training.md \
	cv/skills.md \
	cv/publications.md #\
	#cv/references.md

	#cv/funding.md

pandoc -s -t plain -o cv.txt \
		cv/professional_summary.md \
		cv/career_aim.md \
		cv/education.md \
		cv/research_experience.md \
		cv/teaching_experience.md \
		cv/graduate_research_experience.md \
		cv/affiliations.md \
		cv/service_activities.md \
		cv/professional_development.md \
		cv/graduate_training.md \
		cv/skills.md \
		cv/publications.md \
#		cv/references.md

	# Build more common/shorter Resume format
pandoc -s --template=tex/template.tex -o tex/resume_short.tex \
		cv/professional_summary.md \
		cv/education.md \
		cv/research_experience_short.md \
		cv/graduate_research_experience_short.md \
		cv/affiliations.md \
		cv/service_activities_short.md \
		cv/professional_development_short.md \
		cv/publications_short.md \
		#cv/references.md

		#cv/funding.md



#Use section headings only
sed -i '' 's/subsection/section/' tex/resume.tex
sed -i '' 's/subsection/section/' tex/resume.tex
sed -i '' 's/[[:space:]]\\begin{itemize}/\\begin{innerlist}/' tex/resume.tex
sed -i '' 's/\\begin{itemize}/\\begin{outerlist}/' tex/resume.tex #CV uses outerlist/innerlist instead of itemize
sed -i '' 's/[[:space:]]\\end{itemize}/\\end{innerlist}/' tex/resume.tex
sed -i '' 's/\\end{itemize}/\\end{outerlist}/' tex/resume.tex #CV uses outerlist/innerlist instead of itemize


cd tex/
pdflatex resume.tex
cd ..
cp tex/resume.pdf static/Jason_Locklin_Resume.pdf

#cp tex/resume.pdf ../../Jason\ \&\ Annette\'s\ Shared\ Files/Laurier\ Package/Jason_Locklin_CV.pdf
