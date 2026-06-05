---
title: "A WeeChat Jail on FreeBSD with Bastille"
date: 2026-06-03
tags: ["freebsd", "jails", "bastille", "weechat", "homelab", "zfs", "tailscale"]
draft: true
smallweb_ignore: true
---


## Intro: rebuilding the homelab on FreeBSD

This is the first of several posts where I intend to document re-creating my homelab setup with a FreeBSD server. That project is a whole other post, but in short, I have run homelab setups with various machines and Linux based operating systems for many years, and purchased an off-lease ThinkCentre to re-build everything on FreeBSD. I wanted to learn the system, and wanted to take advantage of jails to provide service isolation without the RAM requirements of virtual machines (RAM is expensive now!).

In this post, to try out creating a useful, "production" jail I started by creating one for the IRC client "Weechat."


## Why WeeChat is a good first jail

Most would think of Weechat as a TUI IRC client, typically run in a terminal on your desktop or in a Screen or Tmux session on a shell account somewhere. However, Weechat also serves as an always-on IRC "bouncer" on its own, and provides for relay connections other clients can use, keeping logs as long as you like. So in this sense, it's a kind of mix of a server and application. Some people run it as a system service, so why not make it a jail? It doesn't need to be internet facing, and has minimal dependencies, so is a great candidate for trying a first always-on jail on the homelab server.


## Background reading

I am not going to go over the well-trodden documentation of setting up jails on FreeBSD (plus it would eventually become obsolete when I forget to update this). Instead, have a look at the Bastille docs and FreeBSD handbook for a background.

- Bastille template syntax (the `Bastillefile` hooks used below): <https://docs.bastillebsd.org/en/latest/chapters/template.html>
- Bastille docs home: <https://docs.bastillebsd.org/>
- FreeBSD Handbook — Jails and Containers: <https://docs.freebsd.org/en/books/handbook/jails/>
- `jail(8)`: <https://man.freebsd.org/cgi/man.cgi?jail(8)>
- `zfs(8)`: <https://man.freebsd.org/cgi/man.cgi?zfs(8)>
- `daemon(8)`: <https://man.freebsd.org/cgi/man.cgi?daemon(8)>
- `pw(8)`: <https://man.freebsd.org/cgi/man.cgi?pw(8)>

I intend to mostly use Weechat directly over SSH. The jail has a "weechat" user that uses only key-based authentication, and connects to the running Weechat TUI immediately, instead of a shell. Using `ForceCommand` means that even the weechat user cannot change that. I will use Bastille commands on the host if I need a shell, not ssh:
- `sshd_config(5)` (see `Match` / `ForceCommand`): <https://man.freebsd.org/cgi/man.cgi?sshd_config(5)>

One other component — Weechat is intended to run in the foreground of a terminal session as a TUI, but we want it to run all the time and simply connect to it. Most people use tmux (or Screen, or via Byobu), but those are overkill for a single application, and I don't like to nest my tmux sessions. I started using dtach years ago for this purpose, but am moving to a newer program this time, "abduco". These serve to background a single program and allow you to (re)connect to just that program via a socket. Do one thing, and do that one thing well:
- `abduco`: <https://www.brain-dump.org/projects/abduco/>

## Network architecture

I will document my network architecture in another post, but for now, to make sense of the example code, it's worth knowing that:

- This jail lives on an internal-only subnet (10.10.10.0/24) reachable only over my Tailnet.
- The FreeBSD host advertises a route to this subnet, so any machine on the Tailnet can hit the jail IP directly on any port.

Alternatives I could have used instead of route advertisement:
  - host networking (move sshd to an alternate port to avoid conflicting with the host)
  - NAT with port forwarding to the jail (again, moving the ssh port for the forward)
  - a bridge to put the jail IP directly on the LAN subnet

## Step 1 — ZFS datasets and jail creation

Notes about storage:

- Dedicated ZFS datasets keep config and logs on clean pools (easy to snapshot/back up).
- chown to uid/gid 1001 so the in-jail `weechat` user owns them through the nullfs mounts.


First: create the datasets for non-ephemeral data (config and state files like IRC logs and weechat settings and scripts). I put them in `zroot/jails` to make backing up easy; `zroot/bastille` will have the Bastille-created datasets, which wipe when destroying jails, so anything under there should be considered ephemeral.

```sh
zfs create zroot/jails/weechat
zfs create zroot/jails/weechat/config
zfs create zroot/jails/weechat/local
```


The default user in the jail will likely be 1001, make sure it can write to those datasets:

```sh
chown -R 1001:1001 /zroot/jails/weechat
```

Using standard Bastille commands, create the jail, giving it a VNET IP address on the bridge subnet, attached to the network interface so it has Internet access.

```sh
bastille create weechat 15.0-RELEASE 10.10.10.3 em0
```


Apply the template. I cloned my fork of the Bastille_templates repository to `/usr/local/bastille/templates` for easy access, but it can be anywhere.

```sh
bastille template weechat /usr/local/bastille/templates/Bastille_templates/irc/weechat
```

## Step 2 — The template (`Bastillefile`)

Walkthrough of the commands in the Bastillefile:

- PKG: install abduco (detachable session), weechat, en-aspell (English spell check used in Weechat).
- SYSRC: enable sshd and the weechat rc service I created.

User creation: I create the weechat user, then mount the host's authorized keys file inside the jail so that any key that can log into my personal account on the host can log into Weechat (you would need to change this if adapting to your needs). It's mounted read-only, so a breach of Weechat cannot change who is allowed to log in to the host. Copying the file would also work, but then it wouldn't get updated between jail builds.

- MOUNT the ZFS config/local datasets read-write so all state lands on the dedicated pool.

- CP usr / overlays the rc.d script (see Step 3).

- The appended sshd_config block is a neat trick: `Match User weechat` + `ForceCommand` so that *any* ssh login as weechat immediately attaches the running abduco session with the Weechat TUI instead of getting a shell. This is usually used for security reasons (unlike `.profile`, the weechat user cannot change this if it was ever compromised), but it also turns out to be extremely convenient.


```
PKG abduco weechat en-aspell

SYSRC sshd_enable=YES
SYSRC weechat_enable=YES

CMD pw useradd -n weechat -m -s /bin/sh -c "WeeChat IRC"
CMD mkdir -p /home/weechat/.ssh
CMD chmod 700 /home/weechat/.ssh
CMD chown -R weechat:weechat /home/weechat/.ssh

# Change 'jay' to the correct user's home path on your host
MOUNT /home/jay/.ssh/authorized_keys /home/weechat/.ssh/authorized_keys nullfs ro 0 0


CMD mkdir -p /home/weechat/.config/weechat
CMD mkdir -p /home/weechat/.local
CMD chown -R weechat:weechat /home/weechat

# State dataset mounts
MOUNT /zroot/jails/weechat/config /home/weechat/.config/weechat nullfs rw 0 0
MOUNT /zroot/jails/weechat/local /home/weechat/.local nullfs rw 0 0

# Bring in the service file
CP usr /
CMD chmod +x /usr/local/etc/rc.d/weechat

# Force ssh logins to attach weechat
CMD sh -c 'echo "" >> /etc/ssh/sshd_config'
CMD sh -c 'echo "Match User weechat" >> /etc/ssh/sshd_config'
CMD sh -c 'echo "    ForceCommand /usr/local/bin/abduco -a /var/run/weechat/abduco.sock" >> /etc/ssh/sshd_config'
CMD sh -c 'echo "    PasswordAuthentication no" >> /etc/ssh/sshd_config'
```

## Step 3 — The service script (`usr/local/etc/rc.d/weechat`)

The service script starts Weechat inside abduco, running as the weechat user at system boot, and restarts it if it quits (changing some settings in Weechat requires a restart, so I can run `/quit` and immediately re-connect).


```sh
#!/bin/sh
#
# PROVIDE: weechat
# REQUIRE: NETWORKING LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name="weechat"
rcvar="weechat_enable"
weechat_user="weechat"
pidfile="/var/run/weechat/weechat.pid"
socket="/var/run/weechat/abduco.sock"

start_cmd="weechat_start"
stop_cmd="weechat_stop"
status_cmd="weechat_status"

weechat_start() {
    install -d -o weechat -m 700 /var/run/weechat
    /usr/sbin/daemon -u weechat -p ${pidfile} -r \
        /usr/local/bin/abduco -c ${socket} /usr/local/bin/weechat
}

weechat_stop() {
    if [ -f ${pidfile} ]; then
        kill $(cat ${pidfile})
        rm -f ${pidfile}
    fi
}

weechat_status() {
    if [ -f ${pidfile} ] && kill -0 $(cat ${pidfile}) 2>/dev/null; then
        echo "weechat is running as pid $(cat ${pidfile})"
    else
        echo "weechat is not running"
    fi
}

load_rc_config $name
run_rc_command "$1"
```

## Step 4 — SSH client config

I added this to every machine's `~/.ssh/config` so `ssh weechat` opens the TUI directly.

```
Host weechat
  Hostname 10.10.10.3
  User weechat
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

`ServerAliveInterval`/`CountMax` keep the attached session from going stale. No need for mosh here — connecting is instant and takes you right to the same Weechat TUI, so any method of having SSH re-connect on a connection hang or laptop sleep works fine.

## Using it

`ssh weechat` instantly attaches the running WeeChat TUI — it *feels* instant, faster than launching Weechat locally. `Ctrl+\` detaches instantly; Weechat keeps running in the background on the server. The workflow is really seamless.


### Notes

- As with tmux and other solutions, if you connect from multiple terminals at once and they are different sizes, one will appear garbled until you interact with it. A solution if that's a real problem is to run a Weechat client locally, connecting to the IRC relay in this jailed Weechat.
- The jail only permits attach-via-ForceCommand login. For an actual shell I use Bastille commands on the host (`bastille console weechat`), not ssh.
- Configure WeeChat normally while attached over ssh; everything persists in the state ZFS pools under `zroot/jails/weechat`, so logs and settings are easy to view, snapshot, and back up independent of the jail root.
- Upgrades: the jail can be treated as ephemeral — destroy and rebuild from the template, state survives on ZFS.
- Gotcha: Bastille complains about the mounts on destroy. Cleanest option is to start the jail, umount the two state ZFS pools, then stop and destroy.
- I will probably point an internal TLS-enabled reverse proxy at it for things like the Glowingbear web UI.


## Download the files

Templates are on my GitHub fork of Bastille_templates:

<https://github.com/JasonLocklin/Bastille_templates/tree/main/irc/weechat>

- `Bastillefile`: <https://raw.githubusercontent.com/JasonLocklin/Bastille_templates/main/irc/weechat/Bastillefile>
- `usr/local/etc/rc.d/weechat`: <https://raw.githubusercontent.com/JasonLocklin/Bastille_templates/main/irc/weechat/usr/local/etc/rc.d/weechat>
