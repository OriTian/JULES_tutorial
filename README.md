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

## How to read this — a beginner's guide

Never used a GitHub repo before? Here's exactly what to click, in order.

**Step 0.** You're already looking at the right thing. When you open this
repo's page on GitHub, `README.md` (this file) is what's shown to you
automatically, scrollable top to bottom — you don't need to go hunting for
a "start here" file, this *is* it.

**Step 1.** Scroll down (or use the links below) and read the 18 chapters
**in order, top to bottom, the first time through**. Each chapter is one
`# Chapter N. ...` heading — don't skip ahead, later chapters assume
you've done the earlier ones. They fall into five groups:

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

Click any chapter below to jump straight to it (these are just anchor
links to further down this same page):

- [Chapter 1. Connect to EC2](#chapter-1-connect-to-ec2)
- [Chapter 2. Understand the JULES workflow](#chapter-2-understand-the-jules-workflow)
- [Chapter 3. Prepare swap memory](#chapter-3-prepare-swap-memory)
- [Chapter 4. Install build tools](#chapter-4-install-build-tools)
- [Chapter 5. Install Miniforge](#chapter-5-install-miniforge)
- [Chapter 6. Install NetCDF-Fortran](#chapter-6-install-netcdf-fortran)
- [Chapter 7. Install FCM](#chapter-7-install-fcm)
- [Chapter 8. Download JULES](#chapter-8-download-jules)
- [Chapter 9. Build JULES](#chapter-9-build-jules)
- [Chapter 10. Get a run directory](#chapter-10-get-a-run-directory)
- [Chapter 11. Prepare the run directory](#chapter-11-prepare-the-run-directory)
- [Chapter 12. Run JULES](#chapter-12-run-jules)
- [Chapter 13. Verify the output](#chapter-13-verify-the-output)
- [Chapter 14. Read model output in Python](#chapter-14-read-model-output-in-python)
- [Chapter 15. Plot air temperature](#chapter-15-plot-air-temperature)
- [Chapter 16. Your tasks](#chapter-16-your-tasks)
- [Chapter 17. Common errors](#chapter-17-common-errors)
- [Chapter 18. Checklist](#chapter-18-checklist)

**Step 2.** Once you understand *why* each step works (that's what this
file is for), the actual copy-paste commands also live in the `scripts/`
folder, one subfolder per group above, each with its own beginner-friendly
README:

- [`scripts/setup/README.md`](scripts/setup/README.md) — Chapters 1–9's connect/build steps
- [`scripts/run/README.md`](scripts/run/README.md) — Chapter 12's run step
- [`scripts/postprocessing/README.md`](scripts/postprocessing/README.md) — Chapters 13–15's check/plot steps
- [`scripts/preprocessing/README.md`](scripts/preprocessing/README.md) — only if you're building a *new* site, not the tutorial's example
- [`scripts/cleanup/README.md`](scripts/cleanup/README.md) — freeing disk space on the instance, any time

Or [`scripts/README.md`](scripts/README.md) itself bundles all of the
above into one page of ready-to-paste blocks, in order, with no
explanation — the fast path once you already know what each step does.

**In short: read this file for the *why*, use `scripts/` for the
commands.**
