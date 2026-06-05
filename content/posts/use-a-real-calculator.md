---
title: "Use a Real Calculator"
date: 2026-06-05
tags: ["R", "unix", "cli", "computing"]
draft: true
smallweb_ignore: true
---

I've noticed a disturbing trend and it's painful to watch. Like, actually makes your teeth hurt, eyeballs swell, needles in the bottom of your feet painful. Well, maybe not quite, but here it is.
Ask a random person a simple arithmetic question, the type of thing where a bill has to be split or adding up the cost of a trip or checking some kid's homework. The type of math that comes up
in day to day life. What happens next? Watch them pull up Google (or worse, an AI/LLM chatbot interface of some sort), and type the calculation in the search bar. Yeah, that's it. Angry yet?

Besides the particular choice of calculator boiling a gallon of water's worth of energy on some server on the other side of the continent to send the answer to a device that would have made an Apollo
engineer literally faint, to calculate something slower than a $5 calculator with a square centimeter of solar panel powering it could do, it's just downright wrong. Okay, maybe not wrong wrong, but
feels so wrong. We all have these pinnacle of digital technology devices in front of us, why not use them?

What's more interesting, let's *really* connect with that tech. Sure, you can use the calculator application with whatever desktop your computer, or some javascript behemoth on your phone. But consider the
humble CLI. Consider something that's been useful since the 70s. Early in that decade, interactive computing was all the rage. Myself, I can't imagine how exciting it was to go from painstakingly building
a stack of punch cards to drop off with the computer operator, to a screen that responds instantly to keypresses, but it must have been amazing. Around that time, some statistics professors decided they wanted
their non-computer-science students to be able to use terminals to do their work. They came up with the idea of an interactive command line that was both simple enough to let undergraduate students get going
within 5 minutes doing the calculations for their class, but powerful enough that their grad students could complete their PhD work without having to switch to god-awful Fortran (sorry, but not).
They came up with the `S` language, and it's been in use for this ever since. It was re-written for x86 back in the 90s and fortunately released as the open source `R` language, and today powers just about all
statistics development and a big chunk of the data science fad. Just like in the 70s, it's both powerful, and simple enough to install and use in 5 minutes for basic calculations. So why not connect
with your mainframe forebears and use it as your computer calculator?

Install the R base package, and run `R` from the command line. It starts fast, uses little RAM, saves all your history to a `.Rhistory` file in the same directory, and even saves your calculations for you
if you want to re-open it in the future and have your calculator's "memory" restored! If I need to do a quick calculation, I simply run `R`, then type the calculation (i.e., `> 350/7` or `> 2^8`). `R` will
obey order of operations, but use brackets liberally to avoid confusion, and feel free to save your answers to variables that get stored in the environment (i.e., `> vacation_cost = 1000+1300+(2500*2)`, and then
`> vacation_cost / 2` to split the bill). When you quit with `Ctrl+D` or `quit()`, it offers to save your environment to a file in the working directory called `.RData` that will be restored next time you run R
in that same directory. R is a weird language with deep roots into the experimental days of languages, inspired by Lisp and full of weirdos to today. If you decide to
really dive in and learn, I can say from experience, that it is a good tool to earn a living, but that's not necessary. It's also a cool, weird calculator with lots of history of computing tied up in it. It's also
fast, CLI, and lightweight. Enjoy.
