# 🎬 TubeTrail

A lightweight, Windows-friendly local web application designed to fetch, display, and export subtitles/captions directly from YouTube videos into clean `.txt` files.

Unlike web scrapers or browser automation tools, TubeTrail queries YouTube's caption endpoints directly via Python's `youtube-transcript-api` and pairs it with a native Node.js interface.

---

## ✨ Features

- ⚡ **Direct Caption Retrieval:** Directly fetches manual and auto-generated transcripts without browser automation or ad-heavy third-party websites.
- 📋 **Batch Processing:** Paste multiple YouTube video URLs (standard, shortened `youtu.be`, shorts, or embed links) and process them all in one click.
- 🏷️ **Custom Filenaming:**
  - Auto-prompting for file names upon extraction.
  - Or predefine names directly in the input box using `#name Your Filename` tags below each URL.
- 📁 **Native Windows Folder Selection:** Integrated Windows Folder Picker dialog ensures files are saved directly to your target directory without browser sandbox limitations.
- 🔒 **Private & Local:** Runs entirely locally on `127.0.0.1`. No video links, transcripts, or user data are sent to external servers or logged.

---

## 📋 Prerequisites

Before running TubeTrail, ensure you have:

1. **[Node.js](https://nodejs.org/)** (LTS version recommended)
2. **[Python 3.11](https://www.python.org/downloads/)**
   > ⚠️ **Important:** During Python setup, ensure **"Add Python to PATH"** and **"Install Python Launcher (py)"** are checked.

---

## 🚀 Quick Start (Windows)

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Krs-Krish-108/TubeTrail.git
   cd TubeTrail
   ```
2. **Run One-Time Setup:**
   - Double-click **`Setup Agent.bat`**.
   - This automatically installs the required Python dependencies (`youtube-transcript-api`).
3. **Launch the Agent:**
   - Double-click **`Start Agent.bat`**.
   - Keep the command prompt window open while using the app.
   - The UI will open automatically in your browser at `http://127.0.0.1:4173`.

---

## 💡 How to Use

1. **Choose Save Location:** Click **"Choose save folder"** to select where your `.txt` files should be stored.
2. **Add Video URLs:** Paste your links into the text area. You can specify custom filenames ahead of time:
   ```text
   https://www.youtube.com/watch?v=dQw4w9WgXcQ
   #name Rick Astley - Never Gonna Give You Up

   https://youtu.be/example123
   #name Research Notes
   ```
   *(If you omit `#name`, the app will prompt you for a filename after the transcript is retrieved).*
3. **Fetch & Save:** Click **"Get transcripts"**. The agent retrieves the text, formats it, and writes the `.txt` file directly into your selected folder.

---

## 📂 File Output Format

Each saved transcript contains:
- The source YouTube video URL.
- 10 line breaks for clear visual separation.
- The full, continuous transcript text without broken mid-sentence line wraps.

---

## 🛠️ Tech Stack

- **Frontend:** Vanilla HTML5, CSS3, JavaScript
- **Backend Server:** Node.js (native `http`, child processes)
- **Extraction Engine:** Python 3.11 with [`youtube-transcript-api`](https://pypi.org/project/youtube-transcript-api/)
- **Native OS Dialogs:** PowerShell (`FolderBrowserDialog`)

---

## 📌 Notes & Troubleshooting

- **No Captions Available:** Videos without captions (neither manual subtitles nor YouTube auto-generated captions) cannot produce transcripts.
- **Rate Limits:** Rapid, continuous requests may temporarily cause YouTube to throttle requests. If this happens, wait a few minutes before retrying.
- **Stopping the Agent:** Simply close the terminal window launched by `Start Agent.bat`.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
