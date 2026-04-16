# Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single-page marketing site for AI Mail Composer hosted on GitHub Pages.

**Architecture:** One self-contained `docs/index.html` with inline CSS and vanilla JS. No build step, no dependencies. Assets (logo, laurel SVG) copied into `docs/`. GitHub API fetches the latest release URL at page load.

**Tech Stack:** HTML, CSS (custom properties, keyframes, Intersection Observer), vanilla JavaScript

---

### Task 1: Set up docs/ directory and copy assets

**Files:**
- Create: `docs/index.html`
- Copy: `logo.png` → `docs/logo.png`
- Copy: `laurel.svg` → `docs/laurel.svg`

- [ ] **Step 1: Copy assets into docs/**

```bash
cp logo.png docs/logo.png
cp laurel.svg docs/laurel.svg
```

- [ ] **Step 2: Create the base HTML skeleton**

Create `docs/index.html` with the full `<head>`, CSS custom properties, and the empty `<body>` structure. This is the foundation everything else builds on.

The CSS establishes:
- System font stack, light background, centered max-width container
- CSS custom properties for colors, spacing, shadows
- macOS window component styles (reused across hero mock + 3 feature mocks)
- Responsive breakpoint at 640px
- Scroll-reveal animation classes (`fade-up` + `visible`)
- Blinking cursor keyframe
- Shimmer keyframe for the generate button

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AI Mail Composer — AI-powered email replies for Apple Mail</title>
  <meta name="description" content="A native macOS menu bar app that uses AI to help you write email replies in Apple Mail. Open source, bring your own API key.">
  <meta property="og:title" content="AI Mail Composer">
  <meta property="og:description" content="Type your thoughts. AI writes the email.">
  <meta property="og:image" content="https://jpwahle.github.io/ai-apple-mail/logo.png">
  <link rel="icon" href="logo.png" type="image/png">
  <style>
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

    :root {
      --font: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      --bg: #ffffff;
      --bg-soft: #f8f8fa;
      --text: #111111;
      --text-secondary: #666666;
      --text-muted: #999999;
      --border: #e5e5e5;
      --shadow: 0 2px 24px rgba(0, 0, 0, 0.08);
      --shadow-lg: 0 8px 40px rgba(0, 0, 0, 0.12);
      --radius: 12px;
      --blue: #4a9eff;
      --green: #28c840;
      --gold: #f5a623;
      --max-width: 900px;
      --traffic-red: #ff5f57;
      --traffic-yellow: #febc2e;
      --traffic-green: #28c840;
    }

    html { scroll-behavior: smooth; }

    body {
      font-family: var(--font);
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }

    /* ---- Layout ---- */
    .container {
      max-width: var(--max-width);
      margin: 0 auto;
      padding: 0 24px;
    }

    /* ---- macOS Window Component ---- */
    .mac-window {
      background: #fff;
      border-radius: var(--radius);
      box-shadow: var(--shadow-lg);
      overflow: hidden;
      border: 1px solid var(--border);
    }

    .mac-titlebar {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      background: #f9f9f9;
      border-bottom: 1px solid var(--border);
    }

    .mac-dots {
      display: flex;
      gap: 6px;
    }

    .mac-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }

    .mac-dot--red { background: var(--traffic-red); }
    .mac-dot--yellow { background: var(--traffic-yellow); }
    .mac-dot--green { background: var(--traffic-green); }

    .mac-title {
      font-size: 13px;
      color: var(--text-muted);
      font-weight: 500;
      flex: 1;
      text-align: center;
      margin-right: 44px; /* offset for dots to center text */
    }

    .mac-body {
      padding: 24px;
    }

    /* ---- Scroll Reveal ---- */
    .fade-up {
      opacity: 0;
      transform: translateY(30px);
      transition: opacity 0.6s ease-out, transform 0.6s ease-out;
    }

    .fade-up.visible {
      opacity: 1;
      transform: translateY(0);
    }

    /* ---- Keyframes ---- */
    @keyframes blink {
      0%, 100% { opacity: 1; }
      50% { opacity: 0; }
    }

    @keyframes shimmer {
      0% { background-position: -200% 0; }
      100% { background-position: 200% 0; }
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    @keyframes fadeOut {
      from { opacity: 1; }
      to { opacity: 0; }
    }

    /* ---- Responsive ---- */
    @media (max-width: 640px) {
      .container { padding: 0 16px; }
      .mac-body { padding: 16px; }
      .mac-titlebar { padding: 10px 12px; }
      .mac-dot { width: 10px; height: 10px; }
    }
  </style>
</head>
<body>

  <!-- Content will be added in subsequent tasks -->

  <script>
    // JS will be added in subsequent tasks
  </script>
</body>
</html>
```

- [ ] **Step 3: Verify the skeleton loads**

```bash
open docs/index.html
```

Verify: blank white page loads with no console errors.

- [ ] **Step 4: Commit**

```bash
git add docs/
git commit -m "feat: scaffold landing page with base CSS and assets"
```

---

### Task 2: Add laurel badge and hero section

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Add the laurel badge and hero HTML**

Insert the following as the first child inside `<body>`, before the `<script>` tag:

```html
  <!-- Laurel Badge -->
  <section class="laurel" aria-label="Award badge">
    <div class="laurel-inner">
      <img src="laurel.svg" class="laurel-left" alt="" aria-hidden="true" width="80" height="25">
      <div class="laurel-text">
        <span class="laurel-title">#1 Apple Mail AI Integration</span>
        <span class="laurel-stars" aria-label="5 stars">★★★★★</span>
      </div>
      <img src="laurel.svg" class="laurel-right" alt="" aria-hidden="true" width="80" height="25">
    </div>
  </section>

  <!-- Hero -->
  <section class="hero">
    <div class="container">
      <img src="logo.png" class="hero-logo" alt="AI Mail Composer icon" width="80" height="80">
      <h1 class="hero-title">AI Mail Composer</h1>
      <p class="hero-tagline">Type your thoughts. AI writes the email.</p>
      <div class="hero-buttons">
        <a id="download-btn" href="https://github.com/jpwahle/ai-apple-mail/releases" class="btn btn-primary">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v8m0 0l-3-3m3 3l3-3M3 13h10"/></svg>
          Download Latest
        </a>
        <a href="https://github.com/jpwahle/ai-apple-mail" class="btn btn-secondary" target="_blank" rel="noopener">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0016 8c0-4.42-3.58-8-8-8z"/></svg>
          GitHub
        </a>
      </div>
      <p class="hero-meta">Open source · MIT License · macOS 14+</p>
    </div>
  </section>
```

- [ ] **Step 2: Add the laurel and hero CSS**

Insert inside the `<style>` tag, before the `@media` responsive block:

```css
    /* ---- Laurel Badge ---- */
    .laurel {
      padding: 40px 24px 0;
      text-align: center;
    }

    .laurel-inner {
      display: inline-flex;
      align-items: center;
      gap: 12px;
    }

    .laurel-left, .laurel-right {
      opacity: 0.8;
    }

    .laurel-right {
      transform: scaleX(-1);
    }

    .laurel-text {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 2px;
    }

    .laurel-title {
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.2px;
    }

    .laurel-stars {
      font-size: 16px;
      color: var(--gold);
      letter-spacing: 2px;
    }

    /* ---- Hero ---- */
    .hero {
      text-align: center;
      padding: 32px 0 48px;
    }

    .hero-logo {
      border-radius: 18px;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
    }

    .hero-title {
      font-size: 48px;
      font-weight: 800;
      letter-spacing: -1.5px;
      margin-top: 20px;
      line-height: 1.1;
    }

    .hero-tagline {
      font-size: 20px;
      color: var(--text-secondary);
      margin-top: 12px;
      font-weight: 400;
    }

    .hero-buttons {
      display: flex;
      gap: 12px;
      justify-content: center;
      margin-top: 28px;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 12px 24px;
      border-radius: 10px;
      font-size: 15px;
      font-weight: 600;
      text-decoration: none;
      transition: transform 0.15s ease, box-shadow 0.15s ease;
    }

    .btn:hover {
      transform: translateY(-1px);
    }

    .btn:active {
      transform: translateY(0);
    }

    .btn-primary {
      background: var(--text);
      color: #fff;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    }

    .btn-primary:hover {
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
    }

    .btn-secondary {
      background: #fff;
      color: var(--text);
      border: 1px solid var(--border);
      box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
    }

    .btn-secondary:hover {
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      border-color: #ccc;
    }

    .hero-meta {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 16px;
    }
```

Add responsive overrides inside the existing `@media (max-width: 640px)` block:

```css
      .hero-title { font-size: 32px; }
      .hero-tagline { font-size: 17px; }
      .hero-buttons { flex-direction: column; align-items: center; }
      .laurel-left, .laurel-right { width: 60px; height: 19px; }
      .laurel-title { font-size: 12px; }
```

- [ ] **Step 3: Verify in browser**

```bash
open docs/index.html
```

Verify: laurel badge centered at top with gold stars, logo below, "AI Mail Composer" heading, tagline, two buttons, meta text. Buttons should have hover effects (lift + shadow).

- [ ] **Step 4: Commit**

```bash
git add docs/index.html
git commit -m "feat: add laurel badge and hero section"
```

---

### Task 3: Build the hero animation mock window (static structure)

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Add the hero mock HTML**

Insert after the closing `</section>` of the hero section, before the `<script>` tag:

```html
  <!-- Hero Animation Mock -->
  <section class="hero-demo">
    <div class="container">
      <div class="mac-window hero-window">
        <div class="mac-titlebar">
          <div class="mac-dots">
            <span class="mac-dot mac-dot--red"></span>
            <span class="mac-dot mac-dot--yellow"></span>
            <span class="mac-dot mac-dot--green"></span>
          </div>
          <span class="mac-title">AI Mail Composer</span>
        </div>
        <div class="mac-body hero-mock-body">
          <div class="mock-input-area">
            <label class="mock-label">Your instructions</label>
            <div class="mock-textarea" id="mock-input">
              <span id="typed-text"></span><span id="cursor" class="cursor">|</span>
            </div>
          </div>
          <div class="mock-actions">
            <div class="mock-model-pill">
              <span class="mock-model-dot"></span>
              Claude Sonnet 4
            </div>
            <button class="mock-generate-btn" id="generate-btn">
              <span class="generate-label">Generate</span>
            </button>
          </div>
          <div class="mock-output-area" id="mock-output">
            <label class="mock-label">Reply</label>
            <div class="mock-reply" id="reply-text"></div>
          </div>
        </div>
      </div>
    </div>
  </section>
```

- [ ] **Step 2: Add the hero mock CSS**

Insert in the `<style>` tag before the responsive `@media` block:

```css
    /* ---- Hero Demo ---- */
    .hero-demo {
      padding: 0 0 80px;
    }

    .hero-window {
      max-width: 620px;
      margin: 0 auto;
    }

    .hero-mock-body {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .mock-label {
      display: block;
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 6px;
    }

    .mock-textarea {
      background: var(--bg-soft);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 14px 16px;
      font-size: 15px;
      line-height: 1.5;
      color: #888;
      font-style: italic;
      min-height: 52px;
    }

    .cursor {
      animation: blink 1s step-end infinite;
      color: var(--blue);
      font-style: normal;
      font-weight: 300;
    }

    .mock-actions {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .mock-model-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 13px;
      color: var(--text-secondary);
      background: var(--bg-soft);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 6px 14px;
    }

    .mock-model-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #D97706;
    }

    .mock-generate-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 10px 24px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: default;
      color: #fff;
      background: var(--blue);
      box-shadow: 0 2px 8px rgba(74, 158, 255, 0.3);
      transition: transform 0.15s ease, box-shadow 0.15s ease;
    }

    .mock-generate-btn.pressed {
      transform: scale(0.96);
      box-shadow: 0 1px 4px rgba(74, 158, 255, 0.2);
    }

    .mock-generate-btn.loading .generate-label {
      background: linear-gradient(90deg, #fff 0%, rgba(255,255,255,0.4) 50%, #fff 100%);
      background-size: 200% 100%;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      animation: shimmer 1.5s ease-in-out infinite;
    }

    .mock-output-area {
      opacity: 0;
      max-height: 0;
      overflow: hidden;
      transition: opacity 0.4s ease, max-height 0.5s ease;
    }

    .mock-output-area.show {
      opacity: 1;
      max-height: 400px;
    }

    .mock-reply {
      background: #f0f7ff;
      border: 1px solid #d4e5ff;
      border-radius: 8px;
      padding: 16px 18px;
      font-size: 15px;
      line-height: 1.7;
      color: var(--text);
    }
```

Add to the responsive `@media (max-width: 640px)` block:

```css
      .hero-window { margin: 0 -8px; }
      .mock-textarea, .mock-reply { font-size: 14px; padding: 12px; }
      .mock-actions { flex-direction: column; gap: 10px; align-items: stretch; }
      .mock-generate-btn { justify-content: center; }
```

- [ ] **Step 3: Verify in browser**

```bash
open docs/index.html
```

Verify: macOS window appears below hero with traffic lights, empty textarea with blinking cursor, model pill showing "Claude Sonnet 4", generate button. Output area is hidden.

- [ ] **Step 4: Commit**

```bash
git add docs/index.html
git commit -m "feat: add hero animation mock window structure"
```

---

### Task 4: Implement the hero typing and streaming animation

This is the centerpiece — the animation must be top-notch. Variable typing speed, human-like rhythm, smooth streaming.

**Files:**
- Modify: `docs/index.html` (the `<script>` section)

- [ ] **Step 1: Write the animation JavaScript**

Replace the `<script>` section in `docs/index.html` with:

```html
  <script>
    // ---- Hero Animation ----
    (function () {
      const INPUT_TEXT = 'ya sounds good lets do thurs, also tell them we need the budget thing sorted';
      const REPLY_HTML = 'Hi Sarah,<br><br>Thursday works great for me. Looking forward to it.<br><br>One more thing — could we get the budget finalized before then? That way we\'ll be ready to move forward at the meeting.<br><br>Best,<br>Jan';

      const typedEl = document.getElementById('typed-text');
      const cursorEl = document.getElementById('cursor');
      const generateBtn = document.getElementById('generate-btn');
      const outputArea = document.getElementById('mock-output');
      const replyEl = document.getElementById('reply-text');

      // Variable delay per character for human-like rhythm
      function typingDelay(char, i) {
        const base = 45;
        // Slow down at punctuation and spaces
        if (char === ',' || char === '.') return base + 120 + Math.random() * 80;
        if (char === ' ') return base + 20 + Math.random() * 40;
        // Occasional slight hesitation
        if (i > 0 && i % 12 === 0) return base + 60 + Math.random() * 60;
        // Normal variation
        return base + Math.random() * 35;
      }

      function typeText(text) {
        return new Promise((resolve) => {
          let i = 0;
          function tick() {
            if (i < text.length) {
              typedEl.textContent += text[i];
              i++;
              setTimeout(tick, typingDelay(text[i - 1], i));
            } else {
              resolve();
            }
          }
          tick();
        });
      }

      function streamReply(html) {
        return new Promise((resolve) => {
          // Split by tags and words, preserving HTML tags as atomic units
          const tokens = [];
          let current = '';
          let inTag = false;
          for (let i = 0; i < html.length; i++) {
            const ch = html[i];
            if (ch === '<') {
              if (current) tokens.push(current);
              current = '<';
              inTag = true;
            } else if (ch === '>' && inTag) {
              current += '>';
              tokens.push(current);
              current = '';
              inTag = false;
            } else if (inTag) {
              current += ch;
            } else if (ch === ' ') {
              if (current) tokens.push(current);
              tokens.push(' ');
              current = '';
            } else {
              current += ch;
            }
          }
          if (current) tokens.push(current);

          let i = 0;
          let displayed = '';
          function tick() {
            if (i < tokens.length) {
              displayed += tokens[i];
              replyEl.innerHTML = displayed;
              i++;
              const token = tokens[i - 1];
              // Tags appear instantly
              if (token.startsWith('<')) {
                tick();
                return;
              }
              // Variable streaming speed
              const delay = 30 + Math.random() * 40;
              setTimeout(tick, delay);
            } else {
              resolve();
            }
          }
          tick();
        });
      }

      async function runAnimation() {
        // Reset state
        typedEl.textContent = '';
        replyEl.innerHTML = '';
        outputArea.classList.remove('show');
        generateBtn.classList.remove('pressed', 'loading');
        cursorEl.style.display = '';

        // Pause before typing starts
        await sleep(800);

        // Step 1: Type the messy input
        await typeText(INPUT_TEXT);

        // Pause after typing
        await sleep(600);

        // Step 2: Press generate button
        cursorEl.style.display = 'none';
        generateBtn.classList.add('pressed');
        await sleep(150);
        generateBtn.classList.remove('pressed');
        generateBtn.classList.add('loading');

        await sleep(1000);
        generateBtn.classList.remove('loading');

        // Step 3: Show output area and stream reply
        outputArea.classList.add('show');
        await sleep(300);
        await streamReply(REPLY_HTML);

        // Step 4: Hold the result
        await sleep(3500);

        // Step 5: Fade out and reset
        outputArea.style.transition = 'opacity 0.5s ease';
        outputArea.style.opacity = '0';
        await sleep(200);
        typedEl.style.transition = 'opacity 0.4s ease';
        typedEl.style.opacity = '0';
        await sleep(500);

        // Hard reset
        typedEl.style.transition = '';
        typedEl.style.opacity = '';
        outputArea.style.transition = '';
        outputArea.style.opacity = '';
        outputArea.classList.remove('show');

        // Loop
        runAnimation();
      }

      function sleep(ms) {
        return new Promise((r) => setTimeout(r, ms));
      }

      // Start when the mock is visible
      const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            observer.disconnect();
            runAnimation();
          }
        });
      }, { threshold: 0.3 });

      observer.observe(document.querySelector('.hero-demo'));
    })();
  </script>
```

- [ ] **Step 2: Verify the animation in browser**

```bash
open docs/index.html
```

Verify:
- Cursor blinks in the empty textarea
- Characters appear one by one with variable speed (commas and spaces are slower)
- After typing finishes, the Generate button presses (scales down), then shows shimmer loading
- Output area slides open, reply text streams word-by-word
- Holds for ~3 seconds, then fades out and loops
- Animation is smooth — no jank or flicker

- [ ] **Step 3: Commit**

```bash
git add docs/index.html
git commit -m "feat: implement hero typing and streaming animation"
```

---

### Task 5: Add the three scroll feature sections

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Add the feature sections HTML**

Insert after the closing `</section>` of the hero-demo section, before the `<script>` tag:

```html
  <!-- Feature Sections -->
  <section class="features">
    <div class="container">

      <!-- Feature 1: Conversation Context -->
      <div class="feature fade-up">
        <div class="feature-text">
          <h2 class="feature-title">Reads the whole thread</h2>
          <p class="feature-subtitle">The AI sees every message in the conversation — not just the last one</p>
        </div>
        <div class="mac-window feature-window">
          <div class="mac-titlebar">
            <div class="mac-dots">
              <span class="mac-dot mac-dot--red"></span>
              <span class="mac-dot mac-dot--yellow"></span>
              <span class="mac-dot mac-dot--green"></span>
            </div>
            <span class="mac-title">Mail — Re: Thursday Meeting</span>
          </div>
          <div class="mac-body">
            <div class="thread">
              <div class="thread-msg thread-msg--context">
                <div class="thread-meta"><strong>Sarah</strong> · 10:32 AM</div>
                <div class="thread-body">Can we meet Thursday? Also need to discuss the Q3 budget before the board review next week.</div>
              </div>
              <div class="thread-msg thread-msg--context">
                <div class="thread-meta"><strong>Mike</strong> · 11:15 AM</div>
                <div class="thread-body">Thursday works for me. Budget spreadsheet is attached — I flagged a few line items we should revisit.</div>
              </div>
              <div class="thread-msg thread-msg--context">
                <div class="thread-meta"><strong>Sarah</strong> · 2:45 PM</div>
                <div class="thread-body">Great. Jan, can you confirm? We need your sign-off on the numbers before Thursday.</div>
              </div>
              <div class="thread-divider"><span>AI reads all of this ↑</span></div>
              <div class="thread-msg thread-msg--reply">
                <div class="thread-meta"><strong>Your reply</strong></div>
                <div class="thread-body">Hi Sarah, Thursday works for me. I've reviewed Mike's spreadsheet and the flagged items look reasonable — happy to sign off. See you Thursday.</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Feature 2: Any Model -->
      <div class="feature fade-up">
        <div class="feature-text">
          <h2 class="feature-title">Pick your favorite model</h2>
          <p class="feature-subtitle">GPT, Claude, Gemini, or anything on OpenRouter</p>
        </div>
        <div class="mac-window feature-window">
          <div class="mac-titlebar">
            <div class="mac-dots">
              <span class="mac-dot mac-dot--red"></span>
              <span class="mac-dot mac-dot--yellow"></span>
              <span class="mac-dot mac-dot--green"></span>
            </div>
            <span class="mac-title">AI Mail Composer — Settings</span>
          </div>
          <div class="mac-body">
            <div class="model-selector">
              <div class="model-selector-label">Model</div>
              <div class="model-dropdown">
                <div class="model-option model-option--selected">
                  <span class="model-badge" style="background: #D97706;">C</span>
                  <span class="model-name">Claude Sonnet 4</span>
                  <svg class="model-check" width="16" height="16" viewBox="0 0 16 16" fill="var(--blue)"><path d="M6.5 12.5l-4-4 1.4-1.4 2.6 2.6 5.6-5.6 1.4 1.4z"/></svg>
                </div>
                <div class="model-option">
                  <span class="model-badge" style="background: #10A37F;">G</span>
                  <span class="model-name">GPT-4o</span>
                </div>
                <div class="model-option">
                  <span class="model-badge" style="background: #4285F4;">G</span>
                  <span class="model-name">Gemini 2.5 Pro</span>
                </div>
                <div class="model-option model-option--last">
                  <span class="model-badge" style="background: #6366F1;">R</span>
                  <span class="model-name">OpenRouter · 100+ models</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Feature 3: Bring Your Own Key -->
      <div class="feature fade-up">
        <div class="feature-text">
          <h2 class="feature-title">Your key, your control</h2>
          <p class="feature-subtitle">No accounts. No subscriptions. Stored in macOS Keychain.</p>
        </div>
        <div class="mac-window feature-window">
          <div class="mac-titlebar">
            <div class="mac-dots">
              <span class="mac-dot mac-dot--red"></span>
              <span class="mac-dot mac-dot--yellow"></span>
              <span class="mac-dot mac-dot--green"></span>
            </div>
            <span class="mac-title">Settings — API Keys</span>
          </div>
          <div class="mac-body">
            <div class="key-fields">
              <div class="key-field">
                <div class="key-field-label">Anthropic</div>
                <div class="key-field-input key-field-input--filled">
                  <span class="key-field-value">sk-ant-••••••••••••7xQ</span>
                  <span class="key-field-status key-field-status--valid">✓ Valid</span>
                </div>
              </div>
              <div class="key-field">
                <div class="key-field-label">OpenAI</div>
                <div class="key-field-input key-field-input--filled">
                  <span class="key-field-value">sk-proj-••••••••••••mK2</span>
                  <span class="key-field-status key-field-status--valid">✓ Valid</span>
                </div>
              </div>
              <div class="key-field">
                <div class="key-field-label">Google Gemini</div>
                <div class="key-field-input key-field-input--empty">
                  <span class="key-field-placeholder">Paste your API key…</span>
                </div>
              </div>
            </div>
            <div class="keychain-badge">
              <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="7" width="10" height="7" rx="1.5"/><path d="M5 7V5a3 3 0 016 0v2"/></svg>
              Stored in macOS Keychain
            </div>
          </div>
        </div>
      </div>

    </div>
  </section>
```

- [ ] **Step 2: Add feature section CSS**

Insert in the `<style>` tag before the responsive `@media` block:

```css
    /* ---- Feature Sections ---- */
    .features {
      padding: 0 0 80px;
    }

    .feature {
      margin-bottom: 80px;
    }

    .feature:last-child {
      margin-bottom: 0;
    }

    .feature-text {
      text-align: center;
      margin-bottom: 32px;
    }

    .feature-title {
      font-size: 32px;
      font-weight: 700;
      letter-spacing: -0.8px;
    }

    .feature-subtitle {
      font-size: 17px;
      color: var(--text-secondary);
      margin-top: 8px;
    }

    .feature-window {
      max-width: 520px;
      margin: 0 auto;
    }

    /* Thread mock */
    .thread {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }

    .thread-msg {
      padding: 10px 14px;
      border-radius: 0 8px 8px 0;
    }

    .thread-msg--context {
      border-left: 3px solid var(--blue);
      background: #f0f7ff;
    }

    .thread-msg--reply {
      border-left: 3px solid var(--green);
      background: #f0fff4;
    }

    .thread-meta {
      font-size: 12px;
      color: var(--text-muted);
      margin-bottom: 3px;
    }

    .thread-meta strong {
      color: var(--text-secondary);
    }

    .thread-msg--context .thread-meta strong {
      color: var(--blue);
    }

    .thread-msg--reply .thread-meta strong {
      color: var(--green);
    }

    .thread-body {
      font-size: 14px;
      color: var(--text);
      line-height: 1.5;
    }

    .thread-divider {
      text-align: center;
      padding: 4px 0;
    }

    .thread-divider span {
      font-size: 11px;
      color: var(--text-muted);
      background: #f5f5f5;
      padding: 3px 12px;
      border-radius: 12px;
    }

    /* Model selector mock */
    .model-selector-label {
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }

    .model-dropdown {
      border: 1px solid var(--border);
      border-radius: 10px;
      overflow: hidden;
    }

    .model-option {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 14px;
      border-bottom: 1px solid #f0f0f0;
      font-size: 14px;
    }

    .model-option--last {
      border-bottom: none;
    }

    .model-option--selected {
      background: #f0f7ff;
    }

    .model-badge {
      width: 22px;
      height: 22px;
      border-radius: 5px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      font-weight: 700;
      color: #fff;
      flex-shrink: 0;
    }

    .model-name {
      color: var(--text);
      font-weight: 500;
    }

    .model-option:not(.model-option--selected) .model-name {
      color: var(--text-secondary);
      font-weight: 400;
    }

    .model-check {
      margin-left: auto;
      flex-shrink: 0;
    }

    /* Key fields mock */
    .key-fields {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }

    .key-field-label {
      font-size: 13px;
      font-weight: 500;
      color: var(--text);
      margin-bottom: 5px;
    }

    .key-field-input {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 10px 14px;
      border-radius: 8px;
      font-size: 13px;
    }

    .key-field-input--filled {
      background: var(--bg-soft);
      border: 1px solid var(--border);
    }

    .key-field-input--empty {
      background: #fff;
      border: 1px dashed #ccc;
    }

    .key-field-value {
      color: var(--text-muted);
      font-family: 'SF Mono', 'Menlo', monospace;
      font-size: 12px;
    }

    .key-field-placeholder {
      color: #ccc;
    }

    .key-field-status--valid {
      color: var(--green);
      font-size: 12px;
      font-weight: 500;
    }

    .keychain-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      color: var(--text-muted);
      background: var(--bg-soft);
      padding: 6px 14px;
      border-radius: 20px;
      margin-top: 18px;
    }
```

Add to the responsive `@media (max-width: 640px)` block:

```css
      .feature-title { font-size: 24px; }
      .feature-subtitle { font-size: 15px; }
      .feature-window { margin: 0 -8px; }
      .feature { margin-bottom: 60px; }
```

- [ ] **Step 3: Verify in browser**

```bash
open docs/index.html
```

Verify: all three feature sections render below the hero mock — thread view, model dropdown, API key fields. Scroll down to see them (they won't animate yet — that's next task).

- [ ] **Step 4: Commit**

```bash
git add docs/index.html
git commit -m "feat: add three scroll feature sections"
```

---

### Task 6: Add scroll animations, dynamic release link, and footer

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Add the footer HTML**

Insert after the closing `</section>` of the features section, before the `<script>` tag:

```html
  <!-- Footer -->
  <footer class="footer">
    <div class="container">
      <p class="footer-text">
        Open source · <a href="https://github.com/jpwahle/ai-apple-mail/blob/main/LICENSE" target="_blank" rel="noopener">MIT License</a> · Made for Apple Mail
      </p>
      <p class="footer-links">
        <a href="https://github.com/jpwahle/ai-apple-mail" target="_blank" rel="noopener">GitHub</a>
      </p>
    </div>
  </footer>
```

- [ ] **Step 2: Add footer CSS**

Insert in the `<style>` tag before the responsive `@media` block:

```css
    /* ---- Footer ---- */
    .footer {
      text-align: center;
      padding: 48px 0;
      border-top: 1px solid var(--border);
    }

    .footer-text {
      font-size: 13px;
      color: var(--text-muted);
    }

    .footer-text a {
      color: var(--text-muted);
      text-decoration: underline;
      text-underline-offset: 2px;
    }

    .footer-text a:hover {
      color: var(--text-secondary);
    }

    .footer-links {
      margin-top: 8px;
    }

    .footer-links a {
      font-size: 13px;
      color: var(--text-muted);
      text-decoration: none;
    }

    .footer-links a:hover {
      color: var(--text);
    }
```

- [ ] **Step 3: Add Intersection Observer and release link JS**

Insert the following inside the `<script>` tag, **after** the hero animation IIFE's closing `})();`:

```javascript
    // ---- Scroll Reveal ----
    (function () {
      const fadeEls = document.querySelectorAll('.fade-up');
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              entry.target.classList.add('visible');
              observer.unobserve(entry.target);
            }
          });
        },
        { threshold: 0.2 }
      );
      fadeEls.forEach((el) => observer.observe(el));
    })();

    // ---- Dynamic Release Link ----
    (function () {
      const btn = document.getElementById('download-btn');
      fetch('https://api.github.com/repos/jpwahle/ai-apple-mail/releases/latest')
        .then((r) => r.json())
        .then((data) => {
          if (data.assets && data.assets.length > 0) {
            btn.href = data.assets[0].browser_download_url;
          } else if (data.html_url) {
            btn.href = data.html_url;
          }
        })
        .catch(() => {
          // Keep fallback URL
        });
    })();
```

- [ ] **Step 4: Verify everything in browser**

```bash
open docs/index.html
```

Verify:
- Scroll down: feature sections fade in as they enter the viewport
- Each section animates independently (not all at once)
- Footer shows at the bottom with links
- Open browser DevTools Network tab: GitHub API call fires on load
- Animation loop still works correctly in the hero

- [ ] **Step 5: Commit**

```bash
git add docs/index.html
git commit -m "feat: add scroll animations, dynamic release link, and footer"
```

---

### Task 7: Final polish and responsive verification

**Files:**
- Modify: `docs/index.html`

- [ ] **Step 1: Test mobile responsive layout**

Open `docs/index.html` in Chrome, open DevTools (Cmd+Opt+I), toggle device toolbar (Cmd+Shift+M), test at 375px width (iPhone).

Verify:
- Laurel badge scales down, text still readable
- Hero title wraps cleanly at 32px
- CTA buttons stack vertically
- Mock windows stretch nearly full width
- Feature section headings fit single screen
- No horizontal overflow

- [ ] **Step 2: Test the full animation cycle end-to-end**

Watch the hero animation loop 2-3 times:
- Typing speed feels natural (not mechanical/uniform)
- Generate button press is visible
- Streaming reply appears word-by-word
- Fade-out transition is smooth
- No visual glitches between loops

- [ ] **Step 3: Commit final state**

```bash
git add docs/index.html
git commit -m "feat: complete landing page with polish and responsive layout"
```
