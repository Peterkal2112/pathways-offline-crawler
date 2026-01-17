# 🛡️ Pathways Offline Crawler & Local Host 🛡️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Educational Purpose](https://img.shields.io/badge/Purpose-Educational-blue.svg)](#)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20|%20Debian-orange.svg)](#)

An automated tool designed to archive and host the **Pathways Interactive Learning Package** (originally by Shout Out UK) for offline educational use, resilience research, and accessibility in low-connectivity environments.

---
## 📑 Table of Contents
1. [⚠️ Legal Disclaimer & ToS Warning](#️-legal-disclaimer--tos-warning)
2. [🚀 How It Works (Step-by-Step)](#-how-it-works-step-by-step)
3. [📦 Installation & Usage](#-installation--usage)
    - [Option A: Standard (Automatic)](#option-a-standard-automatic)
    - [Option B: Expert (Manual)](#option-b-expert-manual)
4. [📖 Included Materials](#-included-materials)
5. [🖥️ Hosting Alternatives](#️-hosting-alternatives)
6. [📜 Quote of the Day](#-quote-of-the-day)

---

## ⚠️ Legal Disclaimer & ToS Warning

**READ CAREFULLY BEFORE PROCEEDING:**
- **Violation of Terms:** This script interacts with Shout Out UK's servers. Using this tool to mirror their content may violate their **Terms of Service (ToS)** and the **Prevent duty** framework.
- **Educational Use Only:** This project is intended strictly for educational resilience, archiving, and research purposes.
- **At Your Own Risk:** The author assumes **no liability** for how this tool is used, for any data loss, or for potential legal repercussions. 
- **Ownership:** All rights to the content, videos, and logic belong to the original copyright holders.

---

## 🚀 How It Works (Step-by-Step)

The crawler executes a precision-engineered retrieval and mirroring process:

1. **Environment Targeting:** You define the local installation directory (Default: `/opt/Pathways`). The script validates root permissions and prepares the local filesystem.
2. **Resource Fetching:** It pulls the latest **Teacher’s Guide PDF** and core documentation directly into the root directory for offline reference.
3. **Engine Bootstrapping:** The script manually "bootstraps" the core game engine. It downloads the primary logic files (`data.js`, `paths.js`, and `story.html`) and injects them into the specific Articulate Storyline directory tree (`html5/data/js/`) to ensure the game "brain" is correctly placed.
4. **Recursive Deep Scan:** A Python-powered Docker container scans the core engine files. It uses advanced regex pattern matching to identify obfuscated media links and internal script calls hidden within the `.js` and `.css` files.
5. **Structure Mirroring:** Unlike standard downloaders, this tool preserves **Path Integrity**. It tests multiple server-side directory prefixes to locate assets and recreates that exact directory structure locally (e.g., `story_content/`, `mobile/`, `html5/lib/`).
6. **Local Deployment:** Offers an optional instant-start Python HTTP server, making the game accessible to any device on your local network (LAN) via port `8080` at the `/story.html` endpoint.

---

## 📦 Installation & Usage

### Option A: Standard (Automatic)
**Ideal for Ubuntu/Debian users.** This script checks for dependencies, installs Docker if missing (using `apt`), and configures the environment automatically.

```bash
curl -sSL https://raw.githubusercontent.com/Peterkal2112/pathways-offline-crawler/main/pathways-crawler.sh | sudo bash
```

### Option B: Expert (Manual)
For advanced users who already have Docker running. This script skips all system checks and gets straight to work. 

**Prerequisites:**
* `docker.io`
* `curl`
* `python3`
* `bash` (POSIX compliant)

```bash
sudo apt update && sudo apt install -y docker.io curl python3
```
```
curl -sSL https://raw.githubusercontent.com/Peterkal2112/pathways-offline-crawler/main/pathways-crawler-expert.sh | sudo bash
```

## 📖 Included Materials
By running this crawler, you will obtain:

* ✅ **The Interactive Game:** Full offline version accessible via `story.html`.
* ✅ **Teaching Guide:** `Teaching_Guide.pdf` – An interactive learning package on extremism for 11-18-year-olds.
* ✅ **Media Assets:** All localized videos and audio files for zero-latency gameplay.

## 🖥️ Hosting Alternatives
Once the files are downloaded to your SSD/Server, you can:

* **Local Server:** Use the built-in option in the script (Python HTTP Server).
* **Professional Hosting:** Point an **Nginx** or **Apache** root to the folder for better performance.
* **Static Access:** Simply open `story.html` directly in a modern web browser (note: some browsers may block certain scripts due to CORS when running from `file://` protocol).

---

## 📜 Quote of the Day
> "He who saves his Country does not violate any Law."
> — **Donald J. Trump**

**I am doing my part.** 🫡  
*Archiving for the future. Supporting the narrative. Ensuring accessibility. (Even Amelia knows that based educational tools deserve to be offline!)*
