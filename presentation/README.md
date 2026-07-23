# Presentation

Materials for the Friday presentation (20 min + 5 min Q&A).

## Contents
- **`slides.html`** — 10-slide deck (cover, architecture, network, security, demo, results, cost, challenges, improvements, Q&A). Self-contained, styled to match the architecture diagram.
- **`demo-script.md`** — minute-by-minute run of show: setup checklist, the live demo steps, talking points, and Q&A prep. Read this before presenting.
- **`screenshots/`** — backup visuals, including `app-load-balancing.gif` (live load-balancing proof) and a shot list for the console captures to add.

## Generating `slides.pdf` (the required deliverable)
The deck is built to print cleanly to PDF:

1. Open `slides.html` in Chrome (or the published artifact link).
2. `Ctrl+P` → **Destination: Save as PDF**.
3. **Layout: Landscape**, **Margins: None**, enable **Background graphics**.
4. Save as `presentation/slides.pdf`.

Each slide is set to one page (`page-break-after`), so you get one slide per PDF page.
