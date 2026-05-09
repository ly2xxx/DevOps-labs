# UBI9 Docker Image Comparison Lab

**Location:** `C:\code\DevOps-labs\docker-dx-extension\ubi9-comparison`

## Goal
Explore the differences between the three Red Hat Universal Base Image (UBI) variants:

- `registry.access.redhat.com/ubi9` (full UBI9) 
- `registry.access.redhat.com/ubi9-minimal`
- `registry.access.redhat.com/ubi9-micro`

We will compare size, installed packages, filesystem layout, and typical use‑cases so you can decide which image fits a given workload.

---

## Prerequisites
- Docker Desktop (or Docker Engine) installed and running on Windows.
- Access to the Red Hat registry (no auth needed for the public UBI images).
- PowerShell or a Bash‑like shell (Git‑Bash, WSL, etc.) for the helper script.

---

## Steps

1. **Pull the images**
   ```bash
   docker pull registry.access.redhat.com/ubi9:latest
   docker pull registry.access.redhat.com/ubi9-minimal:latest
   docker pull registry.access.redhat.com/ubi9-micro:latest
   ```

2. **Inspect basic metadata** (size, layers)
   ```bash
   docker image inspect registry.access.redhat.com/ubi9:latest | jq .[0].Size
   docker image inspect registry.access.redhat.com/ubi9-minimal:latest | jq .[0].Size
   docker image inspect registry.access.redhat.com/ubi9-micro:latest | jq .[0].Size
   ```
   Record the byte size; you’ll see the micro image is dramatically smaller.

3. **List installed packages**
   The UBI images are RPM‑based. Run a container and query the package database:
   ```bash
   # Full UBI9
   docker run --rm registry.access.redhat.com/ubi9:latest rpm -qa | sort > full-packages.txt

   # Minimal
   docker run --rm registry.access.redhat.com/ubi9-minimal:latest rpm -qa | sort > minimal-packages.txt

    # Micro (workaround since rpm is missing in the image)
    docker create --name micro-tmp registry.access.redhat.com/ubi9-micro:latest
    docker cp micro-tmp:/var/lib/rpm ./micro-rpm-db
    docker rm micro-tmp
    docker run --rm -v "$(pwd)/micro-rpm-db:/micro-rpm-db" registry.access.redhat.com/ubi9:latest rpm --dbpath /micro-rpm-db -qa | sort > micro-packages.txt
    rm -rf ./micro-rpm-db
    ```
   Compare the three files to see which packages have been stripped away.

4. **Filesystem comparison** (optional but insightful)
   Using `docker export` is the most reliable way to list all files across all variants (since `ubi9-micro` lacks `tar` and `find`).

   ```bash
   # Full UBI9
   docker create --name tmp-full registry.access.redhat.com/ubi9:latest
   docker export tmp-full | tar -tv > full-fs.txt
   docker rm tmp-full

   # Minimal
   docker create --name tmp-min registry.access.redhat.com/ubi9-minimal:latest
   docker export tmp-min | tar -tv > minimal-fs.txt
   docker rm tmp-min

   # Micro
   docker create --name tmp-micro registry.access.redhat.com/ubi9-micro:latest
   docker export tmp-micro | tar -tv > micro-fs.txt
   docker rm tmp-micro
   ```

   Look for directories like `/usr/share` or `/var/log` that disappear in the smaller images.

5. **Run a quick sanity test**
   Verify you can start a simple command in each image:
   ```bash
   docker run --rm registry.access.redhat.com/ubi9:latest echo "full UBI works"
   docker run --rm registry.access.redhat.com/ubi9-minimal:latest echo "minimal UBI works"
   docker run --rm registry.access.redhat.com/ubi9-micro:latest echo "micro UBI works"
   ```
   The micro image may lack a shell (`/bin/sh`), but the `echo` command works via the default entry‑point.

6. **Create a helper script**
   A small Bash script (`compare.sh`) is provided in this repo to automate steps 2‑4 and print a concise diff. See the next file.

---

## When to Choose Which Variant
| Variant | Approx. size* | Typical use‑case |
|---------|----------------|-----------------|
| `ubi9` (full) | ~ 750 MB | Complex apps needing many OS utilities, compilers, or language runtimes (Node, Python, Java). |
| `ubi9‑minimal` | ~ 300 MB | Services that only need basic tools (curl, bash) and you’ll install your own runtime. |
| `ubi9‑micro` | ~ 120 MB | Tiny, static‑binary workloads (Go, Rust) where you want the smallest attack surface. |

*Sizes may vary slightly depending on Docker version and caching.

---

## Next Steps
- Build a minimal container for a Go binary using `ubi9‑micro` as the base.
- Re‑run the comparison after adding a custom package (e.g., `glibc`) to see how the size changes.
- Document the findings in `RESULTS.md`.

---

## Files in this Lab
- `README.md` – you are reading it.
- `compare.sh` – automates the size and package diff.
- `RESULTS.md` – place to paste your observations.

Happy exploring!
