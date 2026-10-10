---
name: browser-testing
description: Use when checking a UI change, reproducing a UI bug, or walking through a user flow in the running Flutter web app with browser tools, including when a page reads as empty or as one "Enable accessibility" button, typed text goes missing, or a click lands on the wrong element.
---

# Browser testing the Flutter web app

Flutter web paints on a canvas, so browser tools can read the app only when it runs with `ENABLE_SEMANTICS=true`. Not for logic that `flutter test` covers.

## 1. Check the backend

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST http://localhost:8888/v1/login \
  -H 'Content-Type: application/json' -d '{}'
```

`400` means `taka-api` is up. Otherwise run the app on the fake backend (step 2) and say so in your report. It answers every request from memory, so a check that needs real data, like a real photo solve, still needs `taka-api`: ask the user to start it.

## 2. Start the app in the background

```bash
flutter run -d web-server --web-hostname localhost --web-port 62299 \
  --dart-define=API_BASE_URL=http://localhost:8888 \
  --dart-define=ENABLE_SEMANTICS=true
```

On the fake backend, also pass `-t lib/main_fake_backend.dart`.

Ready when it prints `is being served at` (about 30 s). Port taken? Use another everywhere. After code changes, restart it and reload the page.

## 3. Pick the browser tools

In VS Code, use its built-in browser tools. Elsewhere, use Playwright MCP from `.mcp.json`; Copilot CLI loads it only in a trusted folder. Neither? Say so and stop.

| Action | VS Code | Playwright MCP |
|---|---|---|
| Open a URL | `openBrowserPage` | `browser_navigate` |
| Read the page | `readPage` | `browser_snapshot` |
| Click | `clickElement` | `browser_click` |
| Type | `clickElement` on the field, then `runPlaywrightCode`: `await page.waitForTimeout(500); await page.keyboard.type('text', { delay: 25 })` | `browser_type` with `slowly: true` |
| Click by position | `runPlaywrightCode`: `await page.mouse.click(x, y)` | `browser_mouse_click_xy` |
| Screenshot | `screenshotPage` | `browser_take_screenshot`, no `filename` or one in `.playwright-mcp/` |
| Console errors | `runPlaywrightCode`: `return (await page.consoleMessages()).filter(m => m.type() === 'error').map(m => m.text())` | `browser_console_messages` with `level: "error"` |

## 4. Need a signed-in user?

Sign up a throwaway account at `/auth/signup`: `agent+<current time in ms>@example.com` (digits only; no hyphens), any password of 6+ characters. You land on `/auth/registration`. Never use a real account. On the fake backend, any email and password signs in, as a registered student with quarks, cards and saved questions; sign up to see registration instead. Google sign-in can't be automated.

## 5. Flutter rules

- A just-opened page can read as empty while the app loads: wait a few seconds, then read again.
- Only `button "Enable accessibility"` once loaded? The flag is missing: restart with it, or else click that button and move the mouse over the page.
- Playwright MCP: type with `browser_type` and `slowly: true`, not run code. VS Code: use the Type row. `browser_fill_form` and `typeInPage` lose text. Then read the page: each `textbox` shows its text.
- Read the page after every click to see where you landed. Let entrance animations finish first (reduced-motion emulation won't stop them): clicking a moving item can open the wrong one.
- Text boxes have no names: pick them by order, after their label.
- Icon-only buttons, like the back arrow, aren't listed: click by position from a screenshot, or go by URL.
- Open routes by URL; they are in `lib/src/core/routes/`. Pages that call the API need a signed-in session.
- Check console errors after each flow.

## 6. Known limits

- The camera can't be tested headless.
- "Choose from gallery" opens a file chooser. Playwright MCP: `browser_file_upload` with absolute `paths`; no `paths` cancels. VS Code: `handleDialog` with absolute `selectFiles`; empty cancels. A picked photo starts a real solve; on the fake backend, it comes back as the same worked solution after about 3 s.
- Judge visuals from screenshots only.

## 7. Finish

Always stop the dev server (lost its process? `kill $(lsof -tiTCP:62299 -sTCP:LISTEN)`). Report the steps, what happened, console errors and screenshot paths.
