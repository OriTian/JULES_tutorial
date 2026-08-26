# Preprocessing — a beginner's guide

You only need this folder for **one reason**: running JULES somewhere
other than the tutorial's example site (London St James's Park). If
London is fine for now, skip this whole folder — `data/frac/` and
`data/forcing/` already have everything the example needs.

## What JULES actually needs, in plain terms

To simulate one point, JULES needs two pieces of input data it can't guess
on its own:

```text
"what's the ground made of here?"    -> a frac.nc file  (build_frac_file.py)
"what was the weather here?"         -> a forcing.nc file (download_era5.py)
```

Both are just small NetCDF files with one number (or one row of numbers)
per timestep or per tile — not the huge multi-GB gridded datasets you might
picture. That's what makes point-mode JULES runnable on a t3.micro EC2
instance: you're never loading a whole country's worth of data, just one
point's.

## `build_frac_file.py` — "what's the ground made of here?"

JULES splits every location into 10 tile types (5 vegetation + lake, soil,
ice, urban canyon, urban roof) and needs to know what **fraction** of your
point is each one, summing to 1.0. This script just writes those 10
numbers into the tiny NetCDF shape `ancillaries.nml` expects.

```bash
python build_frac_file.py my_site_frac.nc \
  0 0 0 0 0   0 0.3 0   0.4 0.3
# brd_leaf ndl_leaf c3_grass c4_grass shrub  lake soil ice  urban_canyon urban_roof
```

That example says: no vegetation, 30% bare soil, 40% urban canyon, 30%
urban roof, nothing else. **You have to supply these numbers yourself** —
from a land-cover dataset, a site survey, or a reasonable estimate; this
script doesn't look anything up, it just packages numbers you already have
into the file format JULES wants.

The order of the 10 numbers matters and must match `jules_surface_types.nml`
— the script prints back what it wrote so you can sanity-check it.

## `download_era5.py` — "what was the weather here?"

Pulls real hourly weather (temperature, wind, rain, radiation...) for your
point from the Copernicus Climate Data Store (ERA5 reanalysis — think of
it as a global weather record built by blending observations with a
model), and reshapes it into the 7 variables `drive.nml` expects
(`Tair`/`Qair`/`Wind`/`Pstar`/`SwDown`/`LwDown`/`Precip`).

One-time setup (free, no institutional account needed):

```text
1. Register at https://cds.climate.copernicus.eu/
2. Get an API key: https://cds.climate.copernicus.eu/how-to-api
3. pip install cdsapi
```

Then:

```bash
python download_era5.py --lat 53.4808 --lon -2.2426 \
    --start 2023-02-01 --end 2023-07-31 --out my_site_forcing.nc
```

Two things happen behind the scenes, in order:

1. **Download a small box**, not a single point — the CDS API can't hand
   back one exact coordinate, only a rectangular area, so the script
   requests a small ~0.25° box around your point (a few tens of MB for a
   few months, not the multi-GB size of a full-country request).
2. **Pick the nearest grid cell** inside that box, and convert ERA5's raw
   variable names/units into what JULES wants — e.g. accumulated radiation
   totals get turned into hourly rates, dewpoint temperature gets turned
   into specific humidity.

The download step can take a few minutes (CDS queues requests); the
processing step is instant once the raw file lands.

## Then what?

Once you have `my_site_frac.nc` and `my_site_forcing.nc`, point a copied
run directory at them — see the "Making your own site" section of
[`namelists/README.md`](../../namelists/README.md).
