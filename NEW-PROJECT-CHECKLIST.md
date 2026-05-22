# New Project Checklist — Playwright + MCP

Reference for setting up Playwright automation with the MCP server from scratch.

---

## 1. Initialize the Project

- [ ] `npm init -y`
- [ ] Install Playwright: `npm init playwright@latest` (sets up `playwright.config.ts`, example tests, and installs browsers)
- [ ] Or manually: `npm install -D @playwright/test @types/node`
- [ ] Install browsers: `npx playwright install`

---

## 2. TypeScript Config

- [ ] Ensure `tsconfig.json` exists with at minimum:
  ```json
  {
    "compilerOptions": {
      "target": "ESNext",
      "module": "commonjs",
      "strict": true,
      "esModuleInterop": true,
      "types": ["node"]
    }
  }
  ```

---

## 3. `package.json` Scripts

- [ ] Add a `test` script:
  ```json
  "scripts": {
    "test": "playwright test"
  }
  ```

---

## 4. `playwright.config.ts` Essentials

- [ ] Set `testDir` to your tests folder
- [ ] Set `baseURL` if testing a local or fixed remote app
- [ ] Choose reporters (`html` is good for local learning)
- [ ] Configure `projects` for the browsers you need (chromium is enough to start)
- [ ] Enable `trace: 'on-first-retry'` for debugging failures

---

## 5. Register the Playwright MCP Server in Windsurf

- [ ] Open `~/.codeium/windsurf/mcp_config.json`
- [ ] Add the `playwright` entry **inside** `mcpServers`:
  ```json
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--isolated"]
    }
  }
  ```
- [ ] Reload MCP servers in Windsurf (Command Palette → "Reload MCP Servers")
- [ ] Confirm `playwright` shows as connected (green dot) in the MCP panel

> **Note:** `--isolated` gives each Windsurf session a clean browser context. Remove it if you want the browser to persist state across prompts in a session.

---

## 6. Verify Everything Works

- [ ] Run existing tests: `npm test`
- [ ] Open the HTML report: `npx playwright show-report`
- [ ] Ask Cascade in chat: *"Navigate to https://playwright.dev and take a screenshot"*
- [ ] Confirm Cascade uses the `browser_navigate` and `browser_take_screenshot` MCP tools

---

## 7. Useful MCP Tools Available via Cascade

Once the MCP server is running, Cascade can use these tools on your behalf:

| Tool | What it does |
|------|-------------|
| `browser_navigate` | Go to a URL |
| `browser_snapshot` | Capture accessibility tree (better than screenshot for interactions) |
| `browser_take_screenshot` | Capture a visual screenshot |
| `browser_click` | Click an element |
| `browser_type` | Type text into an input |
| `browser_fill_form` | Fill multiple form fields at once |
| `browser_hover` | Hover over an element |
| `browser_select_option` | Choose from a dropdown |
| `browser_press_key` | Press a keyboard key |
| `browser_wait_for` | Wait for text to appear/disappear |
| `browser_evaluate` | Run JavaScript on the page |
| `browser_network_requests` | Inspect network calls |
| `browser_console_messages` | Read browser console output |

---

## 8. Project Structure Convention

```
my-project/
  tests/
    example.spec.ts      # smoke/basic tests
    pages/               # Page Object Model classes (as you grow)
  playwright.config.ts
  tsconfig.json
  package.json
  README.md
  NEW-PROJECT-CHECKLIST.md
```

---

## Quick Reference Commands

```bash
npx playwright test                  # run all tests
npx playwright test --headed         # run with visible browser
npx playwright test --debug          # open inspector
npx playwright show-report           # open last HTML report
npx playwright codegen <url>         # record a test via UI
npx playwright install               # install/update browsers
```
