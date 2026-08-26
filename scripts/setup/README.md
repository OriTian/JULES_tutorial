# Setting up and building JULES on EC2 — a beginner's guide

No JASMIN account needed for this part. The group has a small AWS EC2
instance (Amazon Linux 2023, t3.micro) set up for this — ask in the group
for the `.pem` key and the instance's public DNS name.

## The four steps, in order

```text
1. Connect          SSH into the instance
2. Set up           install everything JULES needs to compile
3. Build             compile jules.exe (~1 minute)
4. Get a run dir     fetch the tutorial's example namelists + data
```

Each one depends on the last — don't skip ahead. Steps 2 and 3 are
one-time (re-running them just confirms nothing's missing); step 4 you
might redo for a different site later.

## 1. Connect

An EC2 instance is just a remote Linux computer. You reach it over SSH
using a private key file (the `.pem`) instead of a password:

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ec2-user@<instance-public-dns>
```

`chmod 400` makes the key file readable only by you — SSH refuses to use
a key that other users could also read.

## 2. One-time environment setup

Ready-to-paste block: `scripts/README.md` step 1 (this file's version below
is the same script, shown here for the "why" — copy from `scripts/README.md`
if you just want the paste block):

```bash
cat > ~/setup_ec2.sh << 'EOF'
#!/bin/bash
set -e
swapon --show | grep -q swapfile || {
  sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile; sudo mkswap /swapfile; sudo swapon /swapfile
}
sudo dnf install -y git make gcc gcc-gfortran \
  perl-FindBin perl-File-Copy perl-File-Compare perl-Sys-Hostname \
  perl-IO-Compress perl-Digest-SHA perl-Text-Balanced perl-Time-Piece perl-filetest
[ -d "$HOME/miniforge3" ] || {
  curl -sL -o /tmp/miniforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
  bash /tmp/miniforge.sh -b -p "$HOME/miniforge3"
}
source "$HOME/miniforge3/bin/activate"
conda install -y -c conda-forge netcdf-fortran
[ -d "$HOME/fcm" ] || git clone -q https://github.com/metomi/fcm.git "$HOME/fcm"
[ -d "$HOME/jules_source" ] || git clone -q --depth 1 https://github.com/MetOffice/jules.git "$HOME/jules_source"
pip install --quiet matplotlib pandas netCDF4 xarray
echo "Setup complete."
EOF
bash ~/setup_ec2.sh
```

What each piece is actually for, in plain terms:

```text
swap              a t3.micro only has ~900MB RAM; 2GB of swap (disk
                   pretending to be RAM) keeps the build from getting
                   killed when it briefly needs more memory than that
gfortran/git/make  the Fortran compiler and the tools FCM (JULES's build
                   system) drives it with
+ perl modules     FCM itself is written in Perl and needs these
Miniforge/conda    a self-contained Python+package manager, used here
                   just to install netcdf-fortran -- Amazon Linux's own
                   package repos (dnf) don't have it
FCM                Met Office's build tool -- reads JULES's build config
                   and calls gfortran on the right files in the right order
JULES source       git clone of the actual JULES Fortran source code --
                   the one genuine external dependency here, not part of
                   this repo
matplotlib/pandas/ the Python packages the postprocessing scripts need,
netCDF4/xarray     installed via pip, NOT conda -- see the warning below
```

**Why `pip install`, not `conda install`, for the Python packages**: conda's
dependency solver has been observed to get OOM-killed on this instance even
with swap enabled. `pip` installs prebuilt wheels without doing that kind
of solving, and just works. If you ever need another Python package on
this instance, `pip install` it — don't reach for `conda install`.

Safe to re-run — every step skips work that's already done (that's what
the `[ -d ... ] ||` checks are doing: "if this is already installed, don't
redo it"). **Verified end-to-end**, including the full build below.

## 3. Build

```bash
cat > ~/build_jules.sh << 'EOF'
# ...paste build_jules.sh here...
EOF
bash ~/build_jules.sh
```

"Building" here just means: turn JULES's Fortran source code into one
executable file, `jules.exe`. A few environment variables tell FCM *how*
to do that on this particular machine:

```text
JULES_PLATFORM=custom   JULES ships ready-made configs for JASMIN/Met
                         Office clusters, but not a plain EC2 box -- "custom"
                         tells FCM to read the rest of these variables
                         instead of assuming a specific cluster's setup
JULES_COMPILER=gfortran which Fortran compiler to call
JULES_NETCDF_PATH       where the netcdf-fortran library from step 2 lives
JULES_MPI=nompi         single-point runs don't need MPI (parallel
                         computing across multiple machines), so it's
                         switched off
JULES_FFLAGS_EXTRA=...  see below
```

**Why `JULES_FFLAGS_EXTRA="-fallow-argument-mismatch -Wno-error"`**:
gfortran 11 (the version on this instance) is stricter than older versions
about function-argument consistency, and flags JULES's dummy-MPI stub
(deliberately written without a strict interface, since it's never
actually used here) as a hard compile error. These two flags just
downgrade that specific check back to a warning — harmless in practice.
**Verified**: the build completes cleanly and produces a working
`jules.exe`.

`-j 1` (not `-j 4`) means "compile one file at a time" — this instance
doesn't have enough RAM to compile several files in parallel. Still only
takes about a minute for all 617 source files, since each file is small.

**Success indicator**: the script's last line lists the built executable —
```text
-rwxr-xr-x 1 ec2-user ec2-user 55123456 ... /home/ec2-user/jules_build/build/bin/jules.exe
```
If you see that, the build worked. If instead you see a Fortran compiler
error, re-check that `setup_ec2.sh` completed without errors first.

## 4. Get a run directory

```bash
cat > ~/get_run_directory.sh << 'EOF'
# ...paste get_run_directory.sh here...
EOF
bash ~/get_run_directory.sh
```

A "run directory" is just a folder containing everything one JULES
simulation needs: a `namelists/` folder (config) and an empty `output/`
folder (JULES writes results there, but doesn't create the folder itself).
This script:

```text
1. downloads this whole tutorial repo (a wget of a GitHub archive, not a
   git clone -- no git metadata needed, just the files)
2. copies the London_StJamesPark example's ~41 namelist files into your
   new run directory
3. finds the tile-fraction (*frac*.nc) and weather (*era5*.nc) files it
   just downloaded, and rewrites the placeholder file= paths inside
   ancillaries.nml/drive.nml to point at wherever they actually landed
```

That last step matters: **without it, JULES fails at startup** with a
file-not-found error, because the namelists as copied still contain the
generic path they were written with, not this instance's actual paths.

Set `RUN_DIR` to change the destination (default `~/my_first_run`):

```bash
RUN_DIR=~/my_second_run bash ~/get_run_directory.sh
```

**Success indicator**: the script prints a namelist file count that should
read "~41". If it's much lower, the download or copy step silently failed
partway through.

## What's next

Once you have a build and a run directory, see
[`scripts/run/README.md`](../run/README.md) to actually run JULES.

---

[Back to main tutorial](../../README.md)
