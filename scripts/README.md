# Scripts

## Where to start

This folder has four subfolders plus this file. If you're new here, open
them in this order:

1. **`setup/README.md`** first — explains the EC2 build environment, why
   each package/env-var is needed, and what `setup_ec2.sh`,
   `build_jules.sh`, and `get_run_directory.sh` each do.
2. **`run/README.md`** next — explains `run_jules.sh`, i.e. actually
   running the model once you have a build and a run directory.
3. **`postprocessing/README.md`** next — explains `plot_quicklook.py` and
   `read_tile_output.py`, the sanity-check plots you make once a run has
   finished.
4. **`preprocessing/`** last, and only if you need it — `build_frac_file.py`
   and `download_era5.py` build the tile-fraction and forcing inputs for a
   *new* site. Skip this on a first pass; the tutorial's example site
   (London_StJamesPark) already ships with these files pre-built in
   `data/frac/` and `data/forcing/`.

Once you've read those and understand what each step does, come back to
**this file** — it's the fast path: the same four steps (build,
get-a-run-directory, run, plot) as ready-to-paste shell blocks, with no
detours through the explanations above.

## Copy in this order

Each block below is complete and self-contained — copy the whole block,
paste it into the EC2 terminal, done. No need to open any other file.
(The one exception is JULES's own source code, which step 1's script
fetches with `git clone` — that's a real external dependency, not part of
this repo.)

## 1. Environment setup

```bash
cat > ~/setup_ec2.sh << 'EOF'
#!/bin/bash
# One-time environment setup for building JULES on the group's EC2 instance.
# See setup/README.md in this repo for what each step does and why.
set -e

# 1. swap
swapon --show | grep -q swapfile || {
  sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
}

# 2. compiler, git, make, perl modules FCM needs
sudo dnf install -y git make gcc gcc-gfortran \
  perl-FindBin perl-File-Copy perl-File-Compare perl-Sys-Hostname \
  perl-IO-Compress perl-Digest-SHA perl-Text-Balanced perl-Time-Piece perl-filetest

# 3. Miniforge, for netcdf-fortran
[ -d "$HOME/miniforge3" ] || {
  curl -sL -o /tmp/miniforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
  bash /tmp/miniforge.sh -b -p "$HOME/miniforge3"
}
source "$HOME/miniforge3/bin/activate"
conda install -y -c conda-forge netcdf-fortran

# 4. FCM
[ -d "$HOME/fcm" ] || git clone -q https://github.com/metomi/fcm.git "$HOME/fcm"

# 5. JULES source
[ -d "$HOME/jules_source" ] || git clone -q --depth 1 https://github.com/MetOffice/jules.git "$HOME/jules_source"

# 6. Python plotting/analysis stack -- pip, not conda (see setup/README.md)
pip install --quiet matplotlib pandas netCDF4 xarray

echo "Setup complete. Next: build_jules.sh"
EOF
bash ~/setup_ec2.sh
```

## 2. Build JULES

```bash
cat > ~/build_jules.sh << 'EOF'
#!/bin/bash
# Builds JULES after setup_ec2.sh has been run once.
# See setup/README.md in this repo for what each variable/flag does and why.
set -e

source ~/miniforge3/bin/activate
export PATH=$HOME/fcm/bin:$HOME/miniforge3/bin:$PATH
export JULES_PLATFORM=custom
export JULES_COMPILER=gfortran
export JULES_BUILD=normal
export JULES_OMP=noomp
export JULES_NETCDF=netcdf
export JULES_NETCDF_PATH=$HOME/miniforge3
export JULES_MPI=nompi
export JULES_FFLAGS_EXTRA="-fallow-argument-mismatch -Wno-error"

mkdir -p ~/jules_build && cd ~/jules_build
fcm make -f ~/jules_source/etc/fcm-make/make.cfg -j 1

ls -la ~/jules_build/build/bin/jules.exe
EOF
bash ~/build_jules.sh
```

## 3. Get a run directory

```bash
cat > ~/get_run_directory.sh << 'EOF'
#!/bin/bash
# Sets up a run directory using the tutorial's example site
# (London_StJamesPark) namelists, forcing, and tile-fraction data.
# Self-contained -- downloads what it needs via wget, no git clone of this
# tutorial repo required. Run after build_jules.sh.
set -e

RUN_DIR="${RUN_DIR:-$HOME/my_first_run}"
TMP_TAR="/tmp/jules-tutorial-data.tar.gz"
TMP_DIR="/tmp/jules-tutorial-data"

wget -q -O "$TMP_TAR" https://github.com/OriTian/JULES-tutorial/archive/refs/heads/main.tar.gz
rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"
tar -xzf "$TMP_TAR" -C "$TMP_DIR" --strip-components=1

mkdir -p "$RUN_DIR"
cp -r "$TMP_DIR/namelists/London_StJamesPark" "$RUN_DIR/namelists"
mkdir -p "$RUN_DIR/output"   # JULES does not create this itself

FRAC_FILE=$(find "$TMP_DIR" -iname "*frac*.nc" | head -1)
FORCING_FILE=$(find "$TMP_DIR" -iname "*era5*.nc" | head -1)
sed -i "s|file='.*frac.*\.nc'|file='$FRAC_FILE'|" "$RUN_DIR/namelists/ancillaries.nml"
sed -i "s|file='.*era5.*\.nc'|file='$FORCING_FILE'|" "$RUN_DIR/namelists/drive.nml"

echo "Run directory ready: $RUN_DIR"
echo "Namelist file count (should be ~41):"
ls "$RUN_DIR/namelists" | wc -l
EOF
bash ~/get_run_directory.sh
```

## 4. Run JULES

```bash
cat > ~/run_jules.sh << 'EOF'
#!/bin/bash
# Run JULES -- no scheduler needed, a single-point/few-month run finishes
# in minutes. Safe to run from anywhere -- cds into RUN_DIR itself, does
# not rely on you having cd'd there first.
set -e

RUN_DIR="${RUN_DIR:-$HOME/my_first_run}"
cd "$RUN_DIR"
mkdir -p output   # JULES does not create this itself
${JULES_EXE:-$HOME/jules_build/build/bin/jules.exe} namelists/
EOF
bash ~/run_jules.sh
```

## 5. Plot a quicklook

```bash
cat > ~/plot_quicklook.py << 'EOF'
"""
Quick single-variable timeseries plot from a JULES output file -- sanity
check that a run produced sensible-looking output before deeper analysis.

Usage:
  python plot_quicklook.py output/my_run.hourly_output.nc --var t1p5m_gb --out quicklook.png
"""
import argparse

import matplotlib

matplotlib.use("Agg")  # no display on a headless machine (e.g. EC2)
import matplotlib.pyplot as plt
import netCDF4 as nc
import pandas as pd

KELVIN_VARS = {"t1p5m_gb", "tstar_gb", "t1p5m", "tstar"}


def plot_quicklook(nc_path, var, out_path):
    ds = nc.Dataset(nc_path)
    t = pd.to_datetime(
        nc.num2date(
            ds.variables["time"][:],
            ds.variables["time"].units,
            only_use_cftime_datetimes=False,
        )
    )
    values = ds.variables[var][:, 0, 0]
    ylabel = var
    if var in KELVIN_VARS:
        values = values - 273.15
        ylabel = f"{var} (\N{DEGREE SIGN}C)"

    plt.figure(figsize=(10, 4))
    plt.plot(t, values)
    plt.ylabel(ylabel)
    plt.tight_layout()
    plt.savefig(out_path, dpi=120)
    print(f"Saved: {out_path}")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("nc_path", help="JULES output NetCDF file")
    p.add_argument("--var", default="t1p5m_gb", help="Variable to plot (default: t1p5m_gb)")
    p.add_argument("--out", default="quicklook.png", help="Output PNG path")
    args = p.parse_args()
    plot_quicklook(args.nc_path, args.var, args.out)
EOF
source ~/miniforge3/bin/activate
python3 ~/plot_quicklook.py ~/my_first_run/output/*.hourly_output.nc --var t1p5m_gb --out ~/my_first_run/quicklook.png
```

See `setup/README.md`, `run/README.md`, `postprocessing/README.md` for
what each step does and why — this file is just the copy-paste blocks in
order.
