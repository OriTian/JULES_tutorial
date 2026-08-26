# JULES/MORUSES Urban Climate Modelling on EC2

A step-by-step lab for running JULES with the MORUSES urban scheme on a
group EC2 instance — from first SSH connection through building JULES,
running a real site, and plotting the output. No prior JULES experience
assumed.

Every command block below is complete and self-contained — copy the whole
block, paste it into the EC2 terminal, done. The one exception is JULES's
own source code, fetched with `git clone` in Chapter 8 — that's a real
external dependency, not part of this repo.

---

## How to read this

Opening this repo on GitHub, this file (`README.md`) is what you land on —
read it top to bottom, in chapter order, the first time through. The
18 chapters fall into five groups:

```text
Chapter 1        Connect            get onto the EC2 instance over SSH
Chapter 2        Understand         the big picture before you type anything
Chapters 3–9     Build              swap, compiler, Miniforge, NetCDF-Fortran,
                                    FCM, JULES source, compile jules.exe
Chapters 10–12   Run                get a run directory, point it at the
                                    example site's data, execute JULES
Chapters 13–15   Check the output   confirm it ran, load it in Python, plot it
Chapter 16       Your tasks         exercises — change a namelist, rerun,
                                    compare
Chapters 17–18   Reference          common-errors table + a final checklist —
                                    come back to these when something breaks,
                                    no need to read them in order
```

Everything you actually run lives in `scripts/` as well, organised the same
way (`scripts/setup/`, `scripts/run/`, `scripts/postprocessing/`) — see
[`scripts/README.md`](scripts/README.md) for the copy-paste-only fast path
once you understand what each step does. This file is the one to read for
the *why*; `scripts/README.md` is the one to use once you just want the
commands.
