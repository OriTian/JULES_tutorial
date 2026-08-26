# JULES Namelists — a beginner's guide

If you've never seen a `.nml` file before, start here. This page assumes
nothing.

## What even is a "namelist"?

A namelist is just a Fortran config file — JULES is written in Fortran, and
Fortran programs read their settings from files shaped like this:

```fortran
&jules_time
  main_run_start = '2023-02-01 00:00:00'
  main_run_end   = '2023-07-31 23:00:00'
  timestep_len   = 3600
/
```

Read it like a dictionary:

```text
&jules_time    the name of this block of settings
main_run_start   a setting inside it, with a value
main_run_end     another setting
timestep_len     another setting
/              end of the block
```

That's the whole syntax. A `.nml` file is just one or more of these blocks,
one after another. JULES opens a folder full of these files at startup,
reads every block, and configures itself accordingly — no code, no
compiling, just editing text.

## Why are there so many files?

Because JULES is one program that can simulate almost anything (forests,
crops, snow, rivers, cities...), and each of those has its own settings.
Rather than one giant file, JULES splits them into ~40 small files by
topic — `jules_snow.nml` for snow, `jules_rivers.nml` for river routing,
`urban.nml` for the urban scheme, and so on. **You only ever need to touch
a handful of them.** The rest exist because JULES insists on finding every
file it expects, even if the physics in it is switched off for your run.

## What's in this folder

```text
namelists/
└── London_StJamesPark/     one runnable example: all ~41 .nml files JULES needs
```

Each subfolder here is one complete, ready-to-run **case** — a full set of
namelists for one site. `London_StJamesPark/` is the tutorial's worked
example: real ERA5 forcing, real tile fractions, already configured and
tested end to end.

## Try it: copy the example case and run it

```bash
mkdir -p ~/my_first_run
cp -r namelists/London_StJamesPark ~/my_first_run/namelists
~/jules_build/build/bin/jules.exe ~/my_first_run/namelists/
```

That's it — no arguments, no flags, just a folder. `jules.exe` reads every
`.nml` file inside it and starts simulating.

## The 7 files worth actually understanding

Of the ~41 files, these seven carry essentially all of the tutorial's
site-specific and science-specific settings. Everything else can stay as
it is.

| File | What it controls | Plain-English example |
|---|---|---|
| `jules_surface_types.nml` | how many surface tiles exist, and which number is which (e.g. tile 6 = urban canyon) | "this run has 10 tile types, and canyon is #9" |
| `jules_surface.nml` | top-level physics switches | "turn the urban scheme on" |
| `urban.nml` | MORUSES urban-scheme options | "use the two-tile canyon/roof scheme" |
| `ancillaries.nml` | where the land-cover fraction and urban-morphology data live | "this grid cell is 20% urban canyon" |
| `drive.nml` | the weather driving the model | "here's the temperature/wind/rain file, hourly, for this period" |
| `timesteps.nml` | simulation clock | "run from Feb 1 to Jul 31 2023, one hour per step" |
| `output.nml` | what to save, and where | "save air temperature and skin temperature, hourly, to `output/`" |

If you're only skimming one file to understand what a case *does*, read
`drive.nml` + `timesteps.nml` (what weather, what period) and `output.nml`
(what you'll get back).

## Making your own site

Don't write a case from scratch — copy the working one and change only
what needs to change:

```bash
cp -r namelists/London_StJamesPark namelists/My_New_Site
```

Then edit just these, in this order:

1. **`drive.nml`** — point `file=` at your own forcing `.nc`, and set the
   period to match the data you actually have.
2. **`timesteps.nml`** — set `main_run_start`/`main_run_end` to the period
   you want to simulate (must be inside the forcing file's coverage).
3. **`ancillaries.nml`** — point at your site's own fraction/urban-property
   file, or set new `const_val` numbers directly.
4. **`output.nml`** — change `output_dir` if you don't want to overwrite
   the previous run's output.

Everything else in the folder — the other ~37 files — can be left exactly
as copied.

---

[Back to main tutorial](../../README.md)
