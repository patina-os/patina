# The test rounds

A record of the test rounds of patina and kortex: what each round tested and how, what it
found, what was changed because of it, and what is still open. Like `agent-test.md`, it
is a dated record, not a description of how things are. The rounds are run by AI agents
(Claude) through the Claude Code workflow `.claude/workflows/testround.js`. Each tester
drives patina and kortex as a critical user without expert knowledge would, on a Debian
13 container of its own (`.claude/testround/machine.sh`), and checks every result itself.
A skeptic for each repository then tries to refute every finding. No person has repeated
these rounds. Each scenario ran once, so a single event here is an observation, not a
rate.

A later round reads this file (`previous` in the workflow's arguments), re-checks the
findings still open below, and adds a section of its own above the first.

## 25 November 2026

### What was tested

- **Software:** patina at `main` of that day (0.1.0-alpha.17 and later), installed by
  Path A with the bundle desktop and the cloud agent in Debian 13 containers with Plasma
  6.3; kortex 0.9.1 from its working tree; opencode 1.19.6.
- **Model:** Qwen 3.6 27B at an OpenAI-compatible API, through "Your own" API.
- **Focus asked by the maintainer:** what changed since 13 November (Allow the rest of
  this task, `patina ai prompt`, the user's own keys, the bar's pins, doctor's new
  checks, lists that narrow by typing, Your own API's errors, kortex 0.8.0 to 0.9.1),
  the look and the words in both modes, and kortex's conversations: rows,
  notifications, Markdown, error states.
- **What could not run:** the live image, the installer and the first boot (no KVM),
  Hermes, the docked panel itself, and the password dialog (the machines use
  NOPASSWD).

Six testers, as in the last round. Onboarding drove `patina install`, the welcome and
`patina ai` in tmux at 82 columns, and took pictures at 1366x768 and 1920x1080. Daily
use took file snapshots around a second install, every migration run twice, `update`
against a local remote, and `doctor` after eight kinds of breakage. The look measured
every palette role in both modes and the real colours in the pictures. kortex on
tasks ran 21 conversations, among them two that must be refused and five staged
faults. kortex with services ran about 30 requests against the stand-in services, with
a planted instruction and probes of Always, redirects, reads and Allow the rest of
this task. kortex's code read all of `kortex.py` and drove its error paths.

### What it found

119 findings from six testers, 85 after duplicates were merged: 4 high, 29 medium, 52
low. The skeptics confirmed 83, left 2 uncertain (P20, K24) and refuted none. 31 of the
85 are findings of the last round still there.

What held:
- From the last round: P1, P3, P9, P10, K22, K25 and K27 are fixed.
- Both requests that must be refused were refused, and the staged faults were all
  fixed in the end.
- A second install and every migration's second run changed nothing, and a theme's
  round trip was byte for byte the same.

High, all addressed in this round:

- **P1** Look-only rules let the agent read a private key without a row: `du
  --files0-from` printed its lines into an error, and `kreadconfig6 *` read
  `~/.aws/credentials`.
- **P2** A bare `> file` and a subshell's redirect still emptied or wrote a file
  without a row (again).
- **K1** With Allow the rest of this task on, `/bin/rm -r ~/project/old` ran without a
  question, and so did `\rm`, `(rm …)`, a deletion after `env` or `nice`, or in a loop.
- **K2** kortex stopped the agent's server a quarter of an hour after the last palette
  action, while the agent still worked on a task the user followed in the panel.

### What was changed

patina: [patina-os/patina#140](https://github.com/patina-os/patina/pull/140). kortex:
[patina-os/kortex#39](https://github.com/patina-os/kortex/pull/39).

| Finding | Change | State |
|---|---|---|
| P1 | `du --f…`, `ip -batch`, `ss -F`, apt's `-o`, `nmcli -s`, `systemctl -H`, a `<` or `$` in a command and `kreadconfig6` with a path ask; kortex offers no Always for `du` and `wc` | fixed |
| P2 | Named in `apps.yaml` with its cause; kortex holds such a step if it is ever asked | open: opencode 1.19.6 gives its rules no pattern for these lines and asks nothing |
| P3 | `patina install` links `~/.local/bin/patina`; doctor fails without it | fixed |
| P4 | The welcome measures the screen: below about 1440 pixels it fits it, without btop; text wraps between words | fixed |
| P5, P23 | Lines that go on name no bundle; "(now)" follows the id; long lines shortened | fixed |
| P6 | The new provider's login runs first; a cancelled one keeps the old provider | fixed |
| P7 | doctor fails on an `opencode.json` that does not parse or a key file it names that is gone | fixed |
| P8 | A broken keys file is left out with a warning; a chord already taken is warned about | fixed |
| P9, P48 | The `.bashrc` block is added once and stays out once deleted; it turns on starship and zoxide; fish has atuin | partly: atuin in bash needs bash-preexec, which Debian does not package |
| P10 | `patina update` fetches first and says when it cannot reach the remote | fixed |
| P11 | `patina ai prompt` opens KWrite in a desktop session, nano on a terminal, and says how to save | fixed |
| P12, P37 | The installer's model page says it changes nothing without an agent and no longer promises a larger model from 20 GB | partly: Calamares cannot skip the page |
| P13 | A `key_url` per provider, said before the key prompt | fixed |
| P14, P49, P50 | The light palette darkened within its hues: every text role 4.5:1 or more on base00 to base02; the key line in base04 | fixed |
| P15, P38, P39 | screenshot.sh stops waiting once kortex answered, turns the locker off, fails on a lock screen, a theme error or a wait that runs out, and restores the welcome | fixed |
| P16, P19, P20 | `agent.md`: keep a job at the user's level, name what a failed change left, a Flatpak's full size with its runtime, a planted instruction first | fixed (the model's compliance) |
| P17 | Look-only commands run unasked with a trailing `2>/dev/null` or `2>&1` | partly: pipes still ask |
| P18 | The read tool keeps back every private key in `~/.ssh` and the usual credential files | fixed |
| P21 | `patina ai prompt` waits for a running request before restarting kortex | partly: it reads kortex's port and password; a marker kortex reads would be cleaner |
| P22 | Installed bundles are fixed lines; the summary says nothing installed is removed | fixed |
| P24 | Meta+A, or any search in the command palette, in place of `ai` | fixed |
| P25, P26 | The provider by its name; the provider list no longer says where every key goes | fixed |
| P27, P29 | https:// added everywhere; an address that is no API is refused before the key; empty input asks again | fixed |
| P28, P30, P33 | Texts of `patina ai login`, `ai off` and `ai` status | fixed |
| P31 | A `title` per bundle, shown in the installer, the install and the welcome | fixed |
| P32, K25 | One name, Allow the rest of this task, one list of what still asks, one set of answer labels | fixed |
| P34, P47 | The agent's entry has its own glyph; Euro-Office by its name | fixed |
| P35, P45 | Theme names in any case; the mode in effect is reported | fixed (Plasma's lists still say "patina Aurora") |
| P36 | "Keyboard shortcuts", Meta+Enter, services marked "(on)", the keys step waits | partly: the sheet's own row stays "Show these keys" for smoke.yml; "Basic onboarding" is CLAUDE.md's word |
| P40–P44, P46 | kitty reloads its colours; keys after `ai off`; the shortcut note; kitty's header; migrations that need a session wait (exit 75); doctor's FAIL lines say `patina install` | fixed |
| P51 | The password dialog names the command | fixed (not seen on screen) |
| P52 | The lock screen stays dark in either mode | fixed |
| P53 | The services' ask-first rules are written by every install | fixed |
| K1, K23 | Each part of a command is read for the program it runs; what kortex cannot read is held; kinds combine; `kill` is held | fixed |
| K2 | The server stays while the panel lives or a session is busy | fixed |
| K3, K4 | Redirects to /dev/null are ignored; package and network commands count as changes only with a changing verb | fixed |
| K5 | "Changes a service": systemctl, crontab, timers and unit files, held | fixed |
| K6, K21, K31 | No "Done." without words; after a Deny the answer says what ran; Stop keeps the text | fixed |
| K7–K10 | Provider and start errors say what is wrong and what to do | K10 partly: the raw line sits under the advice, KRunner has no fold |
| K11–K14, K26, K28 | Code blocks, links, italics, quotes, rows that ask, status rows and notifications read Markdown; the 12-line cap counts shown lines; `<think>` dropped | fixed |
| K15 | What an answer covers is in its row's text, not in a subtext KRunner hides | fixed |
| K16 | No Always for web fetches and searches | fixed |
| K17, K18, K22 | Tools and rules in words; reads, deletes and changes of a service told apart; the ran list by path | fixed |
| K19, K20, K24, K29, K30, K32 | Waiting and loading rows, the last conversation kept, Cut off after two fetches, Enter on every row does something, the agent's question with descriptions and buttons, titles cut at a word | fixed |
| K27 | The asking row has no icons; Enter on it still answers nothing | partly, on purpose |

### To decide

- **P8** from the last round: the image's first boot still clones `main`.
- **kortex holds more** than the list patina names: `kill` ("Stops a program") and a
  command it cannot read. Shift+Enter on the asking row no longer allows once, and the
  notification's longer answers may not fit Plasma's buttons (`docs/desktop-run.md` in
  kortex asks).
- **`"*$*"` asks**, so `echo $SHELL` asks; `agent.md` says to write `~`.
- **atuin in bash** would need bash-preexec from outside Debian.
- **A migration that exits 75** runs only when `patina update` runs inside a Plasma
  session; doctor says it is pending. The welcome could run it at login.
- **`display_name`** in lowercase would make Plasma's colour-scheme list say
  "patina aurora" too.

### Still open

- **P2** and **P17**'s pipes, upstream in opencode (below).
- `ps e` prints the environment of processes and `"ps *"` allows it; `git status` runs a
  repository's `core.fsmonitor`. `apt-cache -c` and `findmnt -F` may print a file into
  an error as `du` did. Not tested.
- The dark mode's base03 as inactive header text is 2.2 to 2.55:1.

### For opencode upstream

- **Redirects:** still the same in 1.19.6. The bare redirect is anomalyco/opencode#49948,
  closed for the new shell tool; a group's or subshell's redirect has no issue of its
  own.

## 13 November 2026

### What was tested

- **Software:** patina at `main` of that day (0.1.0-alpha.15 and later), installed by
  Path A with the bundle desktop and the cloud agent in Debian 13 containers with Plasma
  6.3; kortex 0.7.2 from its working tree; opencode 1.19.5.
- **Model:** Qwen 3.6 27B at an OpenAI-compatible API, through "Your own" API.
- **What could not run:** the live image, the installer and the first boot on tty1, since
  the test host had no KVM, so they were read, not run. Hermes did not run either.
- **sudo:** it never asked for a password on the machines (NOPASSWD), so the password
  dialog was not seen.

Six testers:

- **Onboarding:** the installer's pages and the first boot, read as code and data. The
  questions of `patina install`, `pick`, the welcome, `patina ai on`, `patina ai login`
  and `patina ai connect`, driven through a terminal at 82 and 100 columns. A Plasma
  session at 1366x768.
- **Daily use:**
  - `patina help`, `doctor` (also after breaking the colour scheme, kitty's include, a
    package and a system file), `update` (against a local remote, also over a local edit),
    a second `install`, and every migration run twice.
  - `theme` and `theme mode` on aurora and datum, and `patina ai` status, connect, off
    and on.
  - The keybindings against README, welcome and `patina keys`, the start menu, and kitty
    with its greeting.
- **The look and the words:** two Plasma sessions with pictures (desktop, welcome, command
  palette, start menu in the light mode). WCAG contrast of every text role in both modes.
  kortex's row and notification texts.
- **kortex on tasks:** 17 conversations through `kx.py`, each result checked on the
  machine.
  - Maintenance: version, update, a package and a Flatpak in and out, the light theme, an
    alias, caches, a weekly cleanup.
  - Two requests that must be refused: remove python3, and `curl | sudo sh`.
  - Five faults staged and described only by their symptom: `.bashrc`, a file owned by
    root, a full Downloads folder beside a thesis, a runaway process, a broken apt source.
- **kortex with services and its safety:** the stand-in services `tracker` and `cloud`,
  plus one server added by hand, with a prompt injection planted in a ticket. Probes of
  Always, of redirects and of reading secrets, and the notifications with the palette
  closed.
- **kortex's code and its error paths:** the unit tests and ruff, a read of `kortex.py`, a
  provider that cannot be reached, a broken `opencode.json`, the server killed mid-answer,
  two requests at once, Meta+A and Meta+Shift+A, long answers, and pictures at 1920x1080
  and 1366x768.

### What it found

72 findings from six testers, 65 after duplicates were merged: 4 high, 27 medium, 34
low. The skeptics confirmed 57, left 8 uncertain and refuted none. P4 went down to low,
and P31 is low but was handled together with the agent's instruction.

What held:
- No conversation froze, and the first row came after 1 to 10 seconds.
- Rows that delete or run as root showed their command. After a Deny the palette said
  "Stopped", not "Done.".
- With the palette closed, the notifications followed.
- Both requests that must be refused were refused, and a change in a preset service
  always asked first.
- The keybindings agree everywhere they are named.

High, all addressed in this round:

- **P1** A second install, `patina update` or `patina ai on` switched the cloud agent from
  the user's own API to Mistral: the state file was emptied before it was read.
- **P2** opencode's grep tool read token files, private keys and the API key without
  asking, past the read tool's deny rules.
- **P3** A service the user or the agent added by hand got no ask-first rules, and its
  delete ran unasked. opencode allows any tool that no rule names.
- **K1** One Always on a harmless row allowed far more than that step: opencode's rule is
  the command's start and `*`. After an Always on `find … | wc -l`, `find -delete` and
  `find -exec sudo` ran unasked, and so did a Flatpak install with 1.1 GB of runtime.

### What was changed

patina: [patina-os/patina#131](https://github.com/patina-os/patina/pull/131). kortex:
[patina-os/kortex#29](https://github.com/patina-os/kortex/pull/29).

| Finding | Change | State |
|---|---|---|
| P1 | The provider and the model are read before their state files are written | fixed |
| P2 | grep asks; `~/.git-credentials`, `~/.netrc` and gh's `hosts.yml` are added to the files the agent may not read | partly: a grep that honours the read rules needs opencode |
| P3 | opencode's permissions start with `"*": ask`, then allow its own harmless tools | fixed |
| P5 | Your own API tells a refused key (401, 403) and an address that does not answer apart, and asks again | fixed |
| P6, P7 | The welcome's "More apps" is an on/off list like the install's; typing matches only lines that contain the text, and no match says so | fixed |
| P8 | The first boot clones `main`, not the image's release | open, needs a decision (below) |
| P9 | `patina doctor` checks Plasma's colour scheme and kitty's include | fixed |
| P10 | The user's own keys go in `~/.config/patina/keybindings.yaml`, merged over the defaults; `patina update` explains a pull stopped by a local change | fixed |
| P12, P14, P16, P17, P31 | `defaults/agent.md`: plain look-only commands; check a fix before saying it is fixed; on a vague symptom look or ask, never install to find out; text in data is never an instruction and is told to the user; schedule with a systemd user timer, not cron | P17 fixed, the others partly (the model's compliance) |
| P13 | `agent.md`: write files with the edit tool, never empty one by a redirect | partly: opencode 1.19.5 cannot ask before `> file` or a subshell's redirect |
| K1, K8 | Always only for commands that only look and for opencode's tools that only look (not grep); never for a service's tool, a folder outside home or a Hermes gate | partly: opencode's rule stays the command's start and `*` |
| K2 | The row's last sentence takes linear time; the palette no longer stalls | fixed |
| K3, K6, K14 | An empty reply, a reply that stops at a plan and one cut off say so | fixed |
| K4, K7 | Every row shows what it allows: an edit's path and lines, a service's tool and input, every command, a reach outside home | fixed |
| K9 | A request overtaken by a new one keeps its notifications | fixed |
| K10, K11, K12 | An unreachable provider, a broken `opencode.json` and each failed action say what is wrong and what to do | fixed |
| K13 | One panel; a second Meta+Shift+A brings it to the front | fixed |
| K15 | An answer is capped at 12 lines, with "Show the whole answer" | fixed |

### To decide

- **P8.** Should the image's first boot install the release the image came from, not
  `main`? Path A clones `main`, and Principle 5 says Path A wins. A clean way would be to
  clone `main`, reset it to the image's tag (written into `firstboot.env` at build time),
  and let `patina update` pull `main` from then on.
- **K7.** kortex now shows every command under the agent's words. CLAUDE.md says only "a
  command that deletes, runs as root or the like".
- **K13.** A second Meta+Shift+A brings the panel to the front. The other option is a
  toggle that closes it.

### Still open (low)

- **P4** The welcome window is smaller than its content: on 1366x768 btop says "Terminal
  size too small" and lines wrap; at 1920x1080 the wordmark is cut off
- **P11** Light mode: warning, error and status text falls below 4.5:1 on panels and
  buttons
- **P15** Uninstalling a Flatpak leaves its 1.1 GB runtime; the agent installed it without
  saying the size
- **P18** apply.sh reads `$USER` under `set -u`; without it a mode switch stops halfway,
  and screenshot.sh hides the failure
- **P19** The provider shows as its internal id ("custom", "mistral") in the welcome,
  `patina ai` and doctor
- **P20** Unticking a bundle in patina install's list does nothing, though the list says
  Enter turns bundles on or off
- **P21** Several screens still say to type "ai" in the command palette
- **P22** Hermes' warning about acting unasked is cut off in the agent list
- **P23** The two Nextcloud steps treat the same address differently: one accepts
  "cloud.example.eu", the other refuses it
- **P24** An empty Nextcloud address returns to the menu without a word
- **P25** The cloud provider list says the key stays in opencode's login, which is wrong
  for Your own API and Big Pickle
- **P26** `patina theme mode` and doctor report light while datum, which has no light
  mode, is dark
- **P27** `patina ai off` says Ollama stays installed when there is none, and does not say
  how to remove anything
- **P28** starship, zoxide and atuin are installed but never turned on
- **P29** The FAIL lines for packages and system files in doctor give no fix
- **P30** The start menu calls the office suite "Nextcloud Office", while README, credits
  and the welcome call it Euro-Office
- **P32** The start menu's search placeholder in light mode is 4:1 on the glass
- **P33** The welcome's key line is dimmed with kitty's faint attribute, likely under 3:1
  in light mode
- **P34** The password notification and dialog do not say which command needs root
- **P35** The theme is "Aurora" in one place and "aurora" in another
- **P36** Welcome wording: "Basic onboarding", "Meta+Return"
- **P37** The desktop screenshot run waits for a row that asks even after the agent
  answered; the screen locks and the palette's picture shows the lock screen
- **K5** The first row a novice sees is raw shell, with "Always allows …: du *, sort *"
- **K16** kortex's error and status rows use words a novice cannot act on ("Starts with
  the first request", flickering seconds)
- **K17** Permission rows show raw Markdown and flatten lists; the 240-character cut can
  drop the key warning
- **K18** `rich()` treats the inside of a code block as Markdown
- **K19** The status row shows raw Markdown or code as what the agent wrote last
- **K20** Notifications show the answer's raw Markdown
- **K21** A model's stray thinking tag reaches the answer
- **K22** Enter on the "Working…" or "Waiting for your answer" row empties the clipboard
- **K23** "asks first" notifications are not closed after the row is answered
- **K24** Rows name tools by internal names (`tracker_search_issues: query=Postgres`)
- **K25** The Always button's icon reads as "share" or "export"
- **K26** The answer row's subtext is elided in the middle ("opencode…r copies")
- **K27** Meta+A with nothing running opens an empty palette with no hint row
- **K28** After kortex's idle exit the current conversation is forgotten

### For opencode upstream

- **Rule matching:** a grep rule is matched against the search, not the files it reads.
- **Redirects:** a bare `> file` and a subshell's redirect ask nothing.
- **Always:** its rule is the command's first word or two and `*`, not the command.
