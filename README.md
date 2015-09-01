This is just some of the files used to run my academic personal web page. The page is here:
[http://artsweb.uwaterloo.ca/~jalockli](http://artsweb.uwaterloo.ca/~jalockli).


Basically, I have a handful of markdown files that contain things like contact information, lists of publications, etc., and when `make` is run, [Pandoc](http://johnmacfarlane.net/pandoc/README.html)  and LaTeX are used to generate a static web-page and a CV in the form of a pdf. The makefile also pushes the changes to Github, then ssh's to the web host and pulls the updates. Take a look at the `makefile` to see how it's done.

