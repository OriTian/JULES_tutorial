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
# Chapter 1. Connect to EC2

## Learning objective

Connect from your local computer to a remote EC2 Linux server over SSH.

```text
Local computer
      ↓
     SSH
      ↓
EC2 instance
```

## Step 1. Get your connection details

You need three things — ask in the group chat for the current instance IP
and the shared `.pem` key file if you don't have them yet:

```text
Public IP address   e.g. 54.xx.xx.xx
Username             ec2-user
Private key (.pem)   e.g. jules.pem
```

Put the `.pem` file somewhere on your **local machine** (not on EC2), e.g.
`~/Desktop/jules.pem`. On macOS/Linux, fix its permissions once:

```bash
chmod 400 ~/Desktop/jules.pem
```

## Step 2. Connect

Open a terminal on your **local machine** (Terminal.app, iTerm, Windows
Terminal + WSL, etc.) and run:

```bash
ssh -i ~/Desktop/jules.pem ec2-user@54.xx.xx.xx
```

### Command breakdown

```text
ssh          Secure Shell — opens an encrypted remote session
-i           "identity file" — which private key to authenticate with
jules.pem    the shared private key for this instance
ec2-user     the login account on the EC2 instance
54.xx.xx.xx  the instance's public IP
```

### Success indicator

The first time you connect to a given instance you'll be asked to confirm
its fingerprint — type `yes`. You'll know it worked when the prompt changes
to `[ec2-user@ip-... ~]$`:

```text
❯ ssh -i "jules.pem" ec2-user@ec2-18-130-30-147.eu-west-2.compute.amazonaws.com
The authenticity of host 'ec2-18-130-30-147.eu-west-2.compute.amazonaws.com (18.130.30.147)' can't be established.
ED25519 key fingerprint is: SHA256:5NZ8f8ZXknpalfUBdCbjI+Wh0jV9HTNF2QwMLeUgaSU
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ec2-18-130-30-147.eu-west-2.compute.amazonaws.com' (ED25519) to the list of known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
[ec2-user@ip-172-31-46-208 ~]$
```

**Everything from here on happens inside this one SSH session** — no need
to go back to your local machine until Chapter 14 (plotting).

---

# Chapter 2. Understand the JULES workflow

## What is JULES?

```text
Joint UK Land Environment Simulator
```

A land-surface model that simulates the exchange of energy, water and
carbon between the land surface and the atmosphere:

```
Meteorology
    ↓
  JULES
 ┌─────────────┐
 │ Radiation   │
 │ Heat flux   │
 │ Soil water  │
 │ Carbon      │
 └─────────────┘
    ↓
Air temperature, surface temperature,
sensible heat, latent heat
```

## What is MORUSES?

```text
Met Office - Reading Urban Surface Exchange Scheme
```

JULES's two-tile representation of a city: instead of one blended "urban"
surface, a city point is split into a **canyon** tile (streets + walls) and
a **roof** tile, each with its own energy balance:

```text
       roof
-------|    |-------
       |    |
       |canyon|
       |------|
```

## The workflow at a glance

```text
Set up the environment  →  Build JULES  →  Get a run directory  →  Run  →  Plot
     (once)                  (once)         (per site)          (per run)
```

Everything you do after the first two steps is just editing small text
config files ("namelists") and re-running — no need to touch the source
code again.

---

# Chapter 3. Prepare swap memory

## Why

This group's EC2 instances are small (~900MB–1GB RAM). Compiling JULES
without extra swap space reliably runs out of memory partway through.

## Step 3. Check current memory

```bash
free -h
```

Look at the `Mem` and `Swap` rows:

```text
               total        used        free      shared  buff/cache   available
Mem:           957Mi       161Mi       552Mi       0.0Ki       243Mi       663Mi
Swap:             0B          0B          0B
```

If `Swap` is `0B`, you need the next two steps.

## Step 4. Create a 2GB swap file

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
```

```text
Input:  /dev/zero          (an endless stream of zero bytes)
Output: /swapfile           (the file being created)
Size:   2048 × 1MB = 2GB
```

## Step 5. Enable the swap file

```bash
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Verify:

```bash
free -h
```

Expected:

```text
               total        used        free      shared  buff/cache   available
Mem:           957Mi       122Mi        83Mi       0.0Ki       751Mi       702Mi
Swap:          2.0Gi          0B       2.0Gi
```

These three commands are idempotent — safe to paste again later without
creating a second swap file (the setup script in Chapter 4 skips this step
automatically if swap is already on).

---

# Chapter 4. Install build tools

## Step 6–8. Compiler, git, make, perl

JULES is written in Fortran and built with FCM (Chapter 7), which needs a
handful of Perl modules a minimal Amazon Linux image doesn't ship by
default.

```bash
sudo dnf install -y git make gcc gcc-gfortran \
  perl-FindBin perl-File-Copy perl-File-Compare perl-Sys-Hostname \
  perl-IO-Compress perl-Digest-SHA perl-Text-Balanced perl-Time-Piece perl-filetest
```

```text
git           → download source code
make          → build software from source
gcc-gfortran  → the Fortran compiler that will compile JULES
perl-*        → modules FCM's build scripts assume are present
```

Verify the Fortran compiler is there:

```bash
gfortran --version
```

---

# Chapter 5. Install Miniforge

## Why

Miniforge gives you `conda`, Python, and — critically — a working
`netcdf-fortran` library, which Amazon Linux's own package repos don't
ship at all.

## Step 9–10. Download and install

```bash
curl -sL -o /tmp/miniforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash /tmp/miniforge.sh -b -p ~/miniforge3
```

Expected tail of the output:

```text
Linking conda-26.3.2-py313h78bf25f_1
Transaction finished
installation finished.
```

## Step 11. Activate it

```bash
source ~/miniforge3/bin/activate
```

Verify:

```bash
conda --version
```

You'll need to re-run this `source` line in any new terminal session where
you want `conda` on your `PATH` — it isn't permanent by default.

---

# Chapter 6. Install NetCDF-Fortran

## Why

JULES reads its meteorological forcing from `.nc` (NetCDF) files and writes
its output as `.nc` files too — it needs the Fortran NetCDF library to do
either.

## Step 12. Install

```bash
conda install -y -c conda-forge netcdf-fortran
```

> **Only `netcdf-fortran` here — not `xarray` or other Python packages.**
> Installing more packages alongside it makes conda's dependency solver do
> much more work, and on an instance this small the solver process has been
> observed to get OOM-killed partway through. Python packages for plotting
> come later, via `pip` (Chapter 4 of the script bundle), which uses
> prebuilt wheels instead of solving a dependency graph.

## Step 13. Verify

```bash
nf-config --version
```

Expected:

```text
$ nf-config --version
4.6.4
```

---

# Chapter 7. Install FCM

## What is FCM?

```text
Flexible Configuration Management
```

The Met Office's own build tool — JULES compiles with `fcm make`, not a
plain `Makefile`.

## Step 14. Download

```bash
git clone -q https://github.com/metomi/fcm.git ~/fcm
```

## Step 15. Verify

```bash
~/fcm/bin/fcm --version
```

```text
FCM 2021.05.0-12-g3b045b3 (/home/ec2-user/fcm)
```

---

# Chapter 8. Download JULES

## Step 16. Clone the JULES source

This is the one genuine external dependency in the whole setup — everything
else so far has been generic Linux tooling.

```bash
git clone -q --depth 1 https://github.com/MetOffice/jules.git ~/jules_source
```

## Important folders inside it

```text
src/    Fortran source code
etc/    build configuration (fcm-make/make.cfg — used in Chapter 9)
docs/   JULES's own documentation
```

---

# Chapter 9. Build JULES

## Step 17. Put the tools on your PATH

```bash
source ~/miniforge3/bin/activate
export PATH=$HOME/fcm/bin:$HOME/miniforge3/bin:$PATH
```

## Step 18–21. Tell `fcm make` how to build

```bash
export JULES_PLATFORM=custom
export JULES_COMPILER=gfortran
export JULES_BUILD=normal
export JULES_OMP=noomp
export JULES_MPI=nompi
export JULES_NETCDF=netcdf
export JULES_NETCDF_PATH=$HOME/miniforge3
export JULES_FFLAGS_EXTRA="-fallow-argument-mismatch -Wno-error"
```

```text
JULES_PLATFORM=custom   JULES ships ready-made configs for JASMIN/Met
                         Office clusters, not a plain EC2 box — this tells
                         it to use its generic path instead
JULES_COMPILER=gfortran use the GNU Fortran compiler
JULES_MPI=nompi         single-process build, no MPI
JULES_OMP=noomp         no shared-memory (OpenMP) parallelism
JULES_NETCDF=netcdf     enable NetCDF file I/O, pointed at Miniforge's copy
JULES_FFLAGS_EXTRA       gfortran 11 is strict about JULES's dummy-MPI
                         stub's implicit interface; without these two
                         flags the build fails with a hard compiler error
```

## Step 22. Compile

```bash
mkdir -p ~/jules_build && cd ~/jules_build
fcm make -f ~/jules_source/etc/fcm-make/make.cfg -j 1
```

```text
Fortran source
    ↓
Object files
    ↓
Link libraries
    ↓
jules.exe
```

Use `-j 1`, not a higher number — these instances are too small for
parallel compilation. Expect ~1 minute for all 617 source files:

```text
[info] sources: total=617, analysed=0, elapsed-time=0.1s, total-time=0.0s
[info] compile   targets: modified=7, unchanged=485, failed=0, total-time=52.0s
[info] link      targets: modified=1, unchanged=0, failed=0, total-time=0.9s
[done] make                # 55.7s
```

## Step 23. Verify

```bash
ls -la ~/jules_build/build/bin/jules.exe
```

You should see a ~55MB executable. This step only needs to be done once —
everything after this is per-run, not per-build.

---

# Chapter 10. Get a run directory

## Step 24. Download this tutorial's data

Every JULES run needs a `namelists/` folder (~41 small text config files)
plus forcing and land-cover data. Rather than assembling all of that by
hand, one script downloads a ready-made example site
(`London_StJamesPark`) and wires the paths together automatically.

```bash
RUN_DIR="${RUN_DIR:-$HOME/my_first_run}"
TMP_TAR="/tmp/jules-tutorial-data.tar.gz"
TMP_DIR="/tmp/jules-tutorial-data"

wget -q -O "$TMP_TAR" https://github.com/OriTian/JULES-tutorial/archive/refs/heads/main.tar.gz
rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"
tar -xzf "$TMP_TAR" -C "$TMP_DIR" --strip-components=1
```

```text
wget -O "$TMP_TAR"   download this tutorial repo as a .tar.gz archive
tar --strip-components=1   unpack it, dropping the repo-name folder level
```

This downloads a snapshot via `wget` (not `git clone`) — no repo history,
no git metadata, just the files this tutorial needs.

Repository layout, once unpacked:

```text
data/frac/        land-cover fraction files (.nc)
data/forcing/     meteorological forcing files (.nc)
namelists/        model configuration templates, one folder per site
```

---

# Chapter 11. Prepare the run directory

## Step 25–26. Copy the example site's config in

```bash
mkdir -p "$RUN_DIR"
cp -r "$TMP_DIR/namelists/London_StJamesPark" "$RUN_DIR/namelists"
mkdir -p "$RUN_DIR/output"   # JULES does not create this itself
```

```text
London_StJamesPark
      ↓  (copied)
~/my_first_run/namelists
```

## Step 27. Point the namelists at the real data files

The copied namelists reference the forcing and fraction files by path —
those paths need to point at the files you just downloaded, not a
placeholder. Two lines need patching:

```bash
FRAC_FILE=$(find "$TMP_DIR" -iname "*frac*.nc" | head -1)
FORCING_FILE=$(find "$TMP_DIR" -iname "*era5*.nc" | head -1)
sed -i "s|file='.*frac.*\.nc'|file='$FRAC_FILE'|" "$RUN_DIR/namelists/ancillaries.nml"
sed -i "s|file='.*era5.*\.nc'|file='$FORCING_FILE'|" "$RUN_DIR/namelists/drive.nml"
```

> **Don't skip this step.** Without it, `ancillaries.nml`'s `&jules_frac`
> block and `drive.nml`'s `&jules_drive` block still contain the
> generic path the file was written with, and JULES fails at startup with
> a file-not-found error the first time it tries to open the forcing file.

Verify the count of namelist files (should be ~41 — JULES opens a fixed set
of files by name at startup, so all of them need to be present even though
you'll only ever edit a handful):

```bash
ls "$RUN_DIR/namelists" | wc -l
```

---

# Chapter 12. Run JULES

## Step 28. Start the model

```bash
RUN_DIR="${RUN_DIR:-$HOME/my_first_run}"
cd "$RUN_DIR"
mkdir -p output
${JULES_EXE:-$HOME/jules_build/build/bin/jules.exe} namelists/
```

This is safe to paste from anywhere in your home directory — it `cd`s into
`RUN_DIR` itself first, rather than assuming you're already there.

## What happens internally

```text
Read namelists
    ↓
Read forcing
    ↓
Initialise state variables
    ↓
Time integration
    ↓
Write NetCDF output
```

No job scheduler needed — a single-point, few-month run finishes in well
under an hour on this small instance, directly in your terminal.

## Success indicator

The run prints progress and ends by closing its output files, with no
`[FATAL ERROR]` line:

```text
[INFO] WRITE_DUMP: albsoil
[INFO] file_ncdf_close: Closing file output/my_first_run.dump.20230731.82800.nc
[INFO] file_ncdf_close: Closing file /tmp/jules-tutorial-data/data/forcing/London_StJamesPark_era5_2022_10-2023_12.nc
[INFO] file_ncdf_close: Closing file output/my_first_run.hourly_output.nc
```

**Worried about your SSH connection dropping mid-run?** Start it inside
`tmux` so it keeps going even if you disconnect: `tmux new -s jules_run`,
run the command above inside that session, detach with `Ctrl-b` then `d`,
reconnect later with `tmux attach -t jules_run`.

---

# Chapter 13. Verify the output

## Step 29. List the output files

```bash
ls output
```

```text
my_first_run.dump.20230301.0.nc  my_first_run.dump.20230731.82800.nc  my_first_run.hourly_output.nc
```

The `dump.*` files are restart/state snapshots; `hourly_output.nc` is the
one with the variables you actually asked for in `output.nml`.

## Step 30. Inspect its structure

```bash
ncdump -h output/my_first_run.hourly_output.nc
```

Look for `dimensions`, `variables`, `units`, and `time` in the header —
this tells you what's inside without opening it in Python.

---

# Chapter 14. Read model output in Python

## Step 31. Install the plotting stack

```bash
pip install --quiet matplotlib pandas netCDF4 xarray
```

`pip`, not `conda`/`mamba install` — see the callout in Chapter 6. Verified
on this instance: conda's solver gets OOM-killed; pip's prebuilt wheels
install cleanly.

## Step 32. Open the file

```python
import xarray as xr
ds = xr.open_dataset("output/my_first_run.hourly_output.nc")
print(ds)
```

Look at the `Dimensions`, `Coordinates`, and `Data variables` sections of
the printout to see what's available.

---

# Chapter 15. Plot air temperature

## Step 33. Plot `t1p5m_gb`

```python
(ds["t1p5m_gb"] - 273.15).plot()
```

```text
t1p5m_gb   1.5m air temperature, gridbox mean (Kelvin in the file)
- 273.15   convert Kelvin to Celsius before plotting
```

Or from the command line, without opening a Python shell, using the
ready-made script in this repo:

```bash
python3 scripts/postprocessing/plot_quicklook.py output/my_first_run.hourly_output.nc --var t1p5m_gb --out quicklook.png
```

**Expected shape:** a wiggly line with a clear daily up-down cycle (warmer
afternoons, cooler nights) over the run period — not a flat line or a
single spike, which would signal a units or indexing mistake.

---

# Chapter 16. Your tasks

Use **AI** to help, and **save the prompts you used**.

## Task 1 — Explore output variables

```bash
source ~/miniforge3/bin/activate
python3
```

```python
import xarray as xr
ds = xr.open_dataset("output/my_first_run.hourly_output.nc")
```

- **Q1.** How many variables are in the output file?
- **Q2.** How many time steps (hours) are in the output?

## Task 2 — Plot radiation components

Plot and compare these three variables from the same file:

```text
sw_down    lw_down    rad_net
```

## Task 3 — Modify urban emissivity

Edit `namelists/ancillaries.nml`'s `&urban_properties` block: change
`emisw` and `emisr` from `0.90, 0.95` to `0.98, 0.98`.

```text
&urban_properties
  nvars=7
  use_file=7*.false.
  var='wrr','hwr','hgt','albwl','albrd','emisw','emisr'
  const_val=0, 0, 0, 0.25, 0.08, 0.98, 0.98
/
```

Re-run the model (Chapter 12) and re-plot temperature and radiation.

**Before you run it — predict:** with urban emissivity raised from 0.95 to
0.98, do you expect:

```text
A) Higher roof temperature
B) Lower roof temperature
C) No change
```

## Download your plots

From your **local machine**:

```bash
scp -i jules.pem ec2-user@<your-ec2-ip>:~/my_first_run/*.png ~/Downloads/
```

Run this on your laptop's terminal, not inside the SSH session — it's
copying files *from* EC2 *to* your machine.

You may do further experiments beyond these three tasks.

---

# Chapter 17. Common errors

| Symptom | Cause | Fix |
|---|---|---|
| `Permission denied` on `ssh` | wrong username, key, or IP | double-check all three against Step 1 |
| `gfortran: command not found` | compiler not installed | `sudo dnf install gcc-gfortran` |
| `fcm: command not found` | FCM not on `PATH` | `export PATH=$HOME/fcm/bin:$PATH` |
| build fails with an MPI-interface compiler error | missing `JULES_FFLAGS_EXTRA` | re-export the full variable list in Chapter 9, Step 18–21, before rebuilding |
| `nf-config: command not found` | NetCDF-Fortran not installed / conda not activated | `source ~/miniforge3/bin/activate`, then Chapter 6 |
| `Cannot open file '.../ancillaries.nml'`-adjacent file errors at startup | Chapter 11 Step 27 (the `sed` path patch) was skipped | re-run that step, or delete `$RUN_DIR` and redo Chapter 10–11 |
| conda hangs or gets killed while installing | too many packages requested via `conda install` at once on a small instance | only ever `conda install` `netcdf-fortran` alone; get Python plotting packages via `pip` |
| out-of-memory during compile | no swap configured | Chapter 3 |

Check current memory/swap state any time with:

```bash
free -h
swapon --show
```

---

# Chapter 18. Checklist

After completing this lab, you should be able to:

- [ ] Explain what JULES is and what MORUSES adds to it
- [ ] Connect to the EC2 instance over SSH
- [ ] Create and verify swap memory
- [ ] Install NetCDF-Fortran without triggering the conda OOM issue
- [ ] Install FCM and build JULES from source
- [ ] Explain what each `JULES_*` build environment variable does
- [ ] Prepare a run directory for a new site, including the `sed` path patch
- [ ] Run the London St James's Park example end-to-end
- [ ] Inspect NetCDF output with `ncdump` and `xarray`
- [ ] Plot `t1p5m_gb` and get a sensible-looking diurnal cycle
- [ ] Diagnose the common failures in Chapter 17 without help

---

## Where the rest of this repo lives

```text
scripts/README.md        the same commands above, as copy-paste blocks in order
scripts/setup/           setup_ec2.sh, build_jules.sh
scripts/run/              run_jules.sh
scripts/postprocessing/   plot_quicklook.py, download_era5.py
docs/tutorial.md          longer-form walkthrough of every namelist you might edit
docs/running_on_ec2.md    this same lab, with every script fully inlined
```

Full JULES documentation: [jules-lsm.github.io](https://jules-lsm.github.io/)
— the namelist reference there covers every option this lab didn't.

```text
enjoy your life and use AI
```
