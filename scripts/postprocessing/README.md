# Postprocessing — a beginner's guide

JULES just finished and wrote a `.nc` file into `output/`. Now what? This
folder has two small scripts for looking at what came out — nothing fancy,
just enough to sanity-check a run and pull out the one number the urban
tutorial actually cares about.

## What's a `.nc` file, and how do I even open one?

JULES output is NetCDF — a binary file format for scientific data, not
something you can `cat` and read. Both scripts below use the Python
`netCDF4` library to open it; think of the file as a dictionary of
variables (`t1p5m_gb`, `tstar`, ...), each one an array of numbers indexed
by time (and, for per-tile variables, by tile too).

```bash
source ~/miniforge3/bin/activate   # or wherever your Python env lives
```

Both scripts need that first, since `netCDF4`/`matplotlib`/`pandas` live
there, not in the system Python.

## `plot_quicklook.py` — "did the run actually work?"

The first thing to run after any JULES simulation, before any real
analysis. Plots one variable over time and saves a PNG — if the line looks
like a plausible temperature curve (not all zeros, not `NaN`, not a flat
line), the run worked.

```bash
python plot_quicklook.py output/my_run.hourly_output.nc \
    --var t1p5m_gb --out quicklook.png
```

```text
nc_path    the JULES output file to read
--var      which variable to plot (default: t1p5m_gb, 1.5m air temperature)
--out      where to save the PNG (default: quicklook.png)
```

Kelvin variables (`t1p5m_gb`, `tstar_gb`, `t1p5m`, `tstar`) are
automatically converted to Celsius for the plot — everything else is
plotted in whatever units JULES wrote it in.

## `read_tile_output.py` — "what's the actual urban temperature?"

`_gb` variables (e.g. `t1p5m_gb`) are already a **gridbox mean** — JULES
has blended together all 10 tile types (vegetation, lake, soil, ice,
canyon, roof) into one number, weighted by how much of the point each tile
covers. That's usually *not* what you want for an urban study: a point
that's 40% urban and 60% grass will report a gridbox mean pulled a long
way toward "grass," diluting the very signal you're trying to see.

This script instead reads the **per-tile** output (`t1p5m`, `tstar` —
no `_gb` suffix, one value per tile) and recombines just the two urban
tiles:

```text
T_urban = (frac_canyon * T_canyon + frac_roof * T_roof) / (frac_canyon + frac_roof)
```

i.e. an urban-only average, re-normalised so canyon+roof adds up to 1.0
instead of diluting through soil/grass/lake/ice.

Unlike `plot_quicklook.py`, this one isn't a ready-to-run command-line
tool — it's a small function (`load_output(...)`) you call with four
numbers specific to your run. Open the file, edit the example at the
bottom, and run it:

```python
data = load_output(
    "output/my_run.hourly_output.nc",
    canyon_idx=8, roof_idx=9,          # from THIS run's jules_surface_types.nml
    canyon_frac=0.36, roof_frac=0.41,  # from THIS run's frac.nc
)
print(data["tstar_urban_only"].mean())
```

```bash
python read_tile_output.py
```

**Before running this on anything other than the tutorial's example
site**, check that run's own `jules_surface_types.nml` for `canyon_idx`/
`roof_idx`, and `frac.nc` for `canyon_frac`/`roof_frac` — the script needs
these four numbers, and **tile order is not fixed across run
directories** (see the tile-order warning in the project's `CLAUDE.md` if
you're working from JASMIN). Using the wrong index silently reads the
wrong tile, with no error.

## Which one do I run first?

```text
1. plot_quicklook.py    every time, right after a run -- did it work at all?
2. read_tile_output.py  only once you specifically want the urban-only
                         (canyon+roof) temperature, not the gridbox mean
```
