# Example tile-fraction data

`London_StJamesPark_frac.nc` — real land-cover tile fractions for
London_StJamesPark (lat 51.5081, lon -0.1338), extracted from the UKV
10-tile fraction ancillary at the nearest grid cell. Tile order matches
`namelists_templates/urban_default/jules_surface_types.nml`
(1–5 PFT, 6 lake, 7 bare soil, 8 ice, 9 urban_canyon, 10 urban_roof):

```
0.0, 0.0, 0.0377, 0.0, 0.0, 0.0083, 0.0137, 0.0, 0.2052, 0.7351
```

canyon=0.2052, roof=0.7351 — 94% of this point is "urban," among the
highest urban fractions in the group's labmate9 site set.

Committed directly (only ~8KB) so the tutorial works with **no
`build_frac_file.py` step needed** — just point `ancillaries.nml`'s
`&jules_frac` block at this file and go.

**For a different site**, build your own with
`scripts/preprocessing/build_frac_file.py` — see
[`scripts/preprocessing/README.md`](../../scripts/preprocessing/README.md).
