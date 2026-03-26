# fluffy-pancake

fluffy-pancake is a **personal custom operating system image** built on top of Fedora using the bootc image model.  
It is intended **exclusively for the repository owner’s private use** and reflects individual design decisions, configuration choices, and system modifications.

This project is **not affiliated with, endorsed by, or supported by Fedora, Red Hat, Universal Blue, Bluefin, or any related projects**. Fedora is used strictly as a technical base.

---

## Project Scope and Intent

fluffy-pancake exists as a **private operating system build** for experimentation and personal workflows.

The container image produced by this repository is **not publicly accessible** and **not intended for general consumption**.  
Access to the image requires explicit authentication and permission from the repository owner.

This repository does **not** provide a public distribution, installer, or upgrade path for third parties.

---

## Technical Foundation

The image is built using the **bootc container‑based operating system model**, leveraging Fedora as the underlying base system.

The build process follows a **multi‑stage OCI image architecture**, allowing modular composition and reproducible builds.  
While inspired by publicly documented techniques, the resulting image is **entirely independent and privately maintained**.

---

## Customization Model

This repository is designed for **personal customization only**.

All included components, packages, and configurations are:
- selected intentionally by the repository owner
- maintained without upstream coordination
- subject to change at any time

No guarantees are made regarding stability, compatibility, or long‑term support.

---

## Build System Overview

- Automated image builds via GitHub Actions
- Pull request validation before publishing images
- `main` branch produces a private `:stable` image tag
- Optional image signing and SBOM generation
- No public registry publication

Images are stored in a **private GitHub Container Registry namespace**.

---

## Image Usage (Private)

The following command is shown **for technical reference only**.

```bash
sudo bootc switch ghcr.io/<your-username>/fluffy-pancake:stable
