# Example forcing data

`London_StJamesPark_era5_2022_10-2023_12.nc` — real ERA5 point forcing for
London_StJamesPark (one of the group's labmate9 sites, lat 51.5081, lon
-0.1338), October 2022 through December 2023, already in the layout
`drive.nml` expects (`Tair`/`SwDown`/`LwDown`/`Pstar`/`Qair`/`Precip`/`Wind`).

Committed directly (only ~320KB) so the tutorial works with **no CDS
account, no download step** — just point `drive.nml` at this file and go.
The tutorial's example period (Feb–Jul 2023) is a sub-range within it;
`data_start`/`data_end` don't need to cover the file's full extent.
