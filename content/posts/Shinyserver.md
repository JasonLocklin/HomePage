+++
title = 'Notes on Deploying a Virtual Private Shiny Server'
date = 2024-12-13
draft = false
+++

## Why Shiny and Surveydown?
Shiny is a mature product for creating dynamic web applications (typically dashboards) with R. It's been around a while and developed professionally by Posit. Surveydown is a brand new project that uses Shiny as the engine for
surveys. Keep that in mind. It's very new and being actively developed.

Writing surveys in code opens up several valuable possibilities:

Transparency: Version controlling your survey code provides a clear history of changes. Unlike traditional survey tools, you can identify exactly which version of a survey was presented to each respondent. The survey code can be published (e.g., to GitHub) without any risk of compromising response data.

Collaboration: Being entirely source code-based makes it possible to share survey code or individual questions in a "bank" that can be used across teams or organizations. Traditional software development tools facilitate collaborative work.

Reproducibility: There's no other system where it's easy to publish a survey, and anyone else can literally just run that exact survey (or individual questions).

Cost: While surveys can be hosted for free on shinyapps.io or similar platforms, with databases on Supabase, I prefer having control over the infrastructure. A cheap VPS ($5/month in this example) provides complete control over performance and configuration. For organizations, it can be hosted on-premises behind your firewall for only the cost of basic server hardware.

## Why a Personal Virtual Server?
Having a personal development environment for Shiny applications is essential for rapid prototyping and experimentation. A Virtual Private Server (VPS) provides the perfect sandbox to freely test new ideas, break things, and quickly iterate on designs without worrying about impacting production systems or dealing with traditional IT constraints. This freedom to experiment leads to better final products and a deeper understanding of how Shiny applications behave in a hosted environment.

This guide walks through setting up such a VPS development environment, specifically focused on testing both Shiny dashboards and Surveydown surveys with non-production data. While this setup isn't intended for production use, it serves as an excellent foundation for documenting requirements when working with IT departments to configure secure production hosts. The hands-on experience gained from managing your own server also provides invaluable insights into the security and configuration considerations needed in a production environment.

The focus is on quick deployment of a disposable VPS that can be recreated easily when needed. Future improvements could include automating the process with tools like Ansible.

That said, if you just want to set up a surveydown survey and don't want to administer a system from scratch ***Stop right here***. You are absolutely encouraged to push your surveys to shinyapps.io (or Posit Connect if you pay for it) from within RStudio, and connect to a free database on Supabase, just as the surveydown documentation describes. Your data will be stored in your choice of AWS region, and it will work just fine, for free. It's a click of a button to deploy.

So to summarize, this is an exercise specifically for someone who wants to:
* Learn how the nuts and bolts work (possibly so that they can advocate intelligently to IT professionals who you ask to deploy something like this on premises).
* Exercise control-freak level management of their survey platform
* Find bugs and rough edges in the software to turn into fixes to give back to the open source project.

I sympathize with all three, so here we go...

# Setting up the VPS

*Quick definition: VPS* - If you want to run something on the internet, one way to do it is to pay for a physical computer to be running in some data center somewhere connected to the internet and running 24/7. That's expensive. Fortunately, a concept called "virtualization" lets one physical computer act like many different computers by sharing the CPU and rest of the hardware. Renting a VPS is just like having a server in a rack somewhere, it's just less performant (because it's shared) and it's much, much cheaper.

For this exercise, I chose OVH's VLE-2 tier hosted in Canada, which for a little over $7 Canadian per month, provides a virtual machine with:
- 2 vCPUs
- Fast NVMe SSD storage
- High-speed network connection

These specs ensure smooth performance for development and testing purposes,
while being very low cost.

Initial Setup:
1. Order VPS with latest Ubuntu LTS
2. Wait for credentials via email
3. Log in via SSH using provided credentials

Step 1: Secure the VPS
- Create and configure new admin user:
  ```bash
  # Create user and add to sudo group
  sudo adduser newuser
  sudo usermod -aG sudo newuser
  ```

- Set up SSH key authentication from local machine:
  ```bash
  # Generate key pair on local machine if needed
  ssh-keygen

  # Copy public key to server
  ssh-copy-id newuser@server_ip
  ```

- Disable password authentication:
  ```bash
  # Edit SSH config
  sudo nano /etc/ssh/sshd_config
  ```
Set these options:
  PasswordAuthentication no
  ChallengeResponseAuthentication no

- Test login with new user before logging out
  ```bash
  ssh newuser@server_ip
  ```
- Update system:
```bash
sudo apt update && sudo apt upgrade -y
reboot
```

Step 2: Install R and R Packages
[Installing a Shiny Server](https://posit.co/download/shiny-server/)

Install R:
```bash
sudo apt-get install r-base -y
```

Install Shiny R package:
```bash
sudo su - -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
```

Install our other R packages. These include RMarkdown for hosting those documents,
palmerpenguins is just for the demo, surveydown for surveys, and
the massive tidyverse metapackage.
```bash
sudo su - -c "R -e \"install.packages(c('rmarkdown','palmerpenguins', 'surveydown', 'tidyverse'), repos='https://cran.rstudio.com/')\""
```

Note that the above commands are running R as root/admin to install
those packages. While this isn't normally recommended, it's acceptable for a machine
dedicated to running R Shiny Server as a sandbox. Alternatively, these could
be installed as the 'shiny' user - the user that Shiny Server runs as.

Install Quarto:

Remember, the version number will change over time. Find the most recent one on the [website for Quarto](https://quarto.org/docs/get-started/)

```bash
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.39/quarto-1.6.39-linux-amd64.deb
sha256sum quarto*
sudo gdebi quarto-1.6.39-linux-amd64.deb
```

Step 3: Install Shiny Server

Install dependency:
```bash
sudo apt-get install gdebi-core
```

Download and verify Shiny Server:
```bash
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
sha256sum  shiny-server-*
```

Verify the SHA-256 hash matches the one listed on the download page, then install:
```bash
sudo gdebi shiny-server-1.5.22.1017-amd64.deb
sudo reboot
```

For additional configuration options, refer to the Administrator guide:
https://docs.posit.co/shiny-server/

# Configuring Shiny Server and Deploying a First Shiny App

Shiny server is running at this point, and can be disabled or enabled with:
```bash
sudo systemctl stop/start/restart shiny-server
```

Get information:
```bash
sudo systemctl status shiny-server
```
In my case, the basic install uses less than 40MB of memory.

The default configuration runs Shiny Server on port 3838, unencrypted. If your IP address is 51.51.51.51, you should be able to navigate to http://51.51.51.51:3838 and see the "Welcome to Shiny Server!" webpage.

At this point, anything in the directory `/srv/shiny-server/` will be served by
Shiny Server.

I opened RStudio and created a Shiny app project. By default, it creates a single
app.R file containing a simple Shiny application that displays "Old Faithful
Geyser Data" as a histogram with a slider for selecting the number of bins.

I configured Rclone to mount `/srv` from my VPS on my local
MacBook and copied `app.R` to `/srv/shiny-server/shinydemo/`. Alternatively, it could be copied using Cyberduck or an SSH command:

```bash
scp app.R user@51.51.51.51:/srv/shiny-server/shinydemo/
```

Install Quarto

Now, any Quarto document, RMarkdown file, or Shiny app in a subfolder will work.

# Surveydown

We already installed the surveydown package, and it produces a Shiny app, so we already have what we need to display the surveys. The only thing missing is a database to save the results.


# Database
The purpose of the database is to deal with the concurrent writing of the data. Every interaction of every participant is simultaneously being written to the dataset - that won't work with a plain file. However, data storage, analysis, archiving, etc., these aspects all don't require a database. The best idea is to regularly export the data from the database to an "on disk" file format that is more appropriate to these other tasks. In another post, I will outline a method to write the data frames on a schedule to both CSV and Parquet file formats, where they can be synced to a data lake and/or backed up.

Surveydown is being developed with PostgreSQL database. It will probably work fine with other SQL databases, but it is probably best to stick to what it's being tested on by the developers.

There are 2 options. Run PostgreSQL on the VPS or other server, or use the free plan on Supabase. Unlike running the survey itself on a free service like shinyapps.io, it's unlikely to impact performance whatever you use. Only a tiny bit of data is being sent each time the user presses next (unlike, maybe a large shiny dashboard that needs to read large quantities of data from the database).

I like the option of having both. Supabase is going to be more reliable, and will survive me deleting and re-building the VPS. On the other hand, running a database server permits learning the mechanisms of how the data works, and where performance and backups need to be considered.

Here, I use Supabase, and will make another post outlining setting up and using a database on the VPS.

- Create an account on Supabase.com
- Create a database project. Give it a simple name.
- Supabase provides the credentials to connect to the project

Note that you can use the same project, and use unlimited tables for various surveys.

Future post will outline setting up PostgreSQL on the VPS directly.


## Using Caddy to provide encryption (TLS), caching, and authentication.
Caddy is a wonderful proxy server that automatically manages certificates, and speeds up dynamic web applications by caching content. It can also provide authentication for different domains (e.g., a survey.domain.com for surveys,
and dashboards.domain.com for authenticated dashboards).

Notes to come in separate post

## Translations
A major deficit at the time of writing is the limitations on language translations. There is a flag on the `sd_server()` function that changes the
UI language (i.e., things like warnings), and of course you can call your question wording from a dataframe, so it can be done, however:

1. The `sd_server()` flag isn't something that it looks possible to make user
selectable. You could probably clone your survey for multiple languages with
unique URLs at this point. That could include a landing page that lets the user select a language and forwards them to the correct page. That's not as slick as the dropdown on every page of Qualtrics.

2. I will have to think of the best way to store the translations and call them in the questions based on the language. That's not built into any of the examples yet. Perhaps a YAML file that is parsed by R into a dataframe, and then the variables can be extracted as they are used.
