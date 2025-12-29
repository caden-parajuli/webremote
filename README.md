# WebRemote

> [!WARNING]
> This is in very early stages. Do not use this for *any* purpose yet.
> 
> This is the branch for the Rust rewrite of WebRemote. The regular WebRemote README is below.

WebRemote is just what it sounds like, a web-based remote. The vision is for you
to be able to control a Wayland-based Home Theater PC with a PWA on your phone.
The goal is to obtain a "smart TV"-like experience, without the proprietary software/hardware.

Currently it is in very early stages. I will be first making it work for my particular
setup, then I will add configurability and make it more general-purpose. I do want
this to eventually be something anyone can use, but for now my priority is just
hacking something together that works for me.

If you're interested in the vision of this project, don't hesitate to reach out.

## Features

- [x] Installable PWA
- [x] Limited keyboard control (arrow keys, enter, backspace)
- [x] Volume control (through Pipewire/PulseAudio)
- [x] Pause, play, and stop media (for MPRIS-compatible players)
  - [ ] Seek to time
- [x] On-device keyboard input
- [x] Switch between apps
  - [ ] Open apps automatically if needed

## Security

> [!CAUTION]
> You should assume that anyone with access to this service has full control of your user account.

You *must* prevent unauthenticated access to this service, e.g. through a
firewall and HTTP Basic Authentication.
