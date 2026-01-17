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

The crawler executes a sophisticated retrieval process:
1. **Targeting:** You define the local directory (Default: `/root/Pathways`).
2. **Resource Fetching:** It pulls the latest **Teacher’s Guide PDF** directly into your folder.
3. **Deep Asset Scan:** Launches a Python-based Docker container that scans the core files (`story.html`, `.js`, `.css`) for remote media links.
4. **Synchronization:** Downloads and organizes over 1,000 unique assets (`.mp4`, `.mp3`, `.png`, `.json`) into the correct folder structure.
5. **Local Deployment:** Offers to launch an instant Python HTTP server to make the game available on your local network.

---

## 📦 Installation & Usage

### Option A: Standard (Automatic)
**Ideal for Ubuntu/Debian users.** This script checks for dependencies, installs Docker if missing (using `apt`), and configures the environment automatically.

```bash
curl -sSL [https://raw.githubusercontent.com/Peterkal2112/pathways-offline-crawler/main/pathways-crawler.sh](https://raw.githubusercontent.com/Peterkal2112/pathways-offline-crawler/main/pathways-crawler.sh) | sudo bash
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
