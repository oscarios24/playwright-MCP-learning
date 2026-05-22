# Playwright Testing Guide

A reference for automating web pages with Playwright, based on the TodoMVC automation workflow.

---

## Workflow to Automate a Page

1. **Explore the page** using the Playwright MCP (`browser_navigate` + `browser_snapshot`) to understand the DOM structure and available selectors.
2. **Identify selectors** — check for `data-testid`, roles, labels, placeholders, and class names.
3. **Create the spec file** in `tests/` following the structure below.
4. **Run the tests** to verify everything passes.

---

## Test File Structure

```ts
import { test, expect, type Page } from '@playwright/test';

// Reusable helpers
async function doSomething(page: Page, value: string) {
  await page.getByPlaceholder('...').fill(value);
  await page.getByPlaceholder('...').press('Enter');
}

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('https://your-url.com');
  });

  test('should do something', async ({ page }) => {
    // arrange → act → assert
  });
});
```

---

## Locators (How to Find Elements)

| Method | Example | Use when |
|---|---|---|
| `getByPlaceholder` | `page.getByPlaceholder('What needs to be done?')` | Input fields with placeholder text |
| `getByRole` | `page.getByRole('button', { name: 'Submit' })` | Buttons, links, checkboxes, headings |
| `getByTestId` | `page.getByTestId('todo-item')` | Elements with `data-testid` attribute |
| `getByText` | `page.getByText('Buy groceries')` | Any element by visible text |
| `getByLabel` | `page.getByLabel('Mark all as complete')` | Inputs associated with a `<label>` |
| `locator` | `page.locator('.todo-list li')` | CSS selectors as fallback |

### Chaining Locators

```ts
// Find a checkbox inside the first todo item
page.getByTestId('todo-item').first().getByRole('checkbox')

// Find the title label inside a specific item
page.getByTestId('todo-item').first().getByTestId('todo-title')

// nth() for a specific index
page.getByTestId('todo-item').nth(2)
```

---

## Actions (How to Interact)

```ts
await locator.click()                  // single click
await locator.dblclick()               // double-click (e.g. to edit)
await locator.hover()                  // hover (reveals hidden buttons)
await locator.fill('text')             // clear + type text
await locator.press('Enter')           // keyboard key
await locator.check()                  // check a checkbox
await locator.uncheck()                // uncheck a checkbox
await locator.clear()                  // clear input value
await locator.selectOption('value')    // select dropdown option
```

---

## Assertions (What to Verify)

```ts
await expect(page).toHaveTitle(/TodoMVC/)
await expect(page).toHaveURL('https://...')

await expect(locator).toBeVisible()
await expect(locator).toBeHidden()
await expect(locator).toBeEmpty()
await expect(locator).toBeEnabled()
await expect(locator).toBeDisabled()
await expect(locator).toBeChecked()

await expect(locator).toHaveText('exact text')
await expect(locator).toContainText('partial text')
await expect(locator).toHaveValue('input value')
await expect(locator).toHaveClass(/class-name/)
await expect(locator).toHaveCount(3)
await expect(locator).toHaveAttribute('data-testid', 'todo-item')
```

---

## Test Organization

```ts
test.describe('Group name', () => { ... })   // group related tests
test.beforeEach(async ({ page }) => { ... }) // runs before every test in the group
test.afterEach(async ({ page }) => { ... })  // runs after every test
test.only('...', ...)                        // run only this test (debug)
test.skip('...', ...)                        // skip this test
```

---

## CLI Commands

```bash
# Run all tests
npx playwright test

# Run a specific file
npx playwright test tests/todomvc.spec.ts

# Run on a specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit

# Run in headed mode (see the browser)
npx playwright test --headed

# Open interactive UI mode
npx playwright test --ui

# Run a specific test by title
npx playwright test -g "should add a single todo item"

# Run in debug mode (step through)
npx playwright test --debug

# Open the last HTML report
npx playwright show-report

# Generate tests by recording your actions (codegen)
npx playwright codegen https://demo.playwright.dev/todomvc
```

---

## Config (`playwright.config.ts`)

Key settings to know:

```ts
export default defineConfig({
  testDir: './tests',         // where test files live
  fullyParallel: true,        // run tests in parallel
  retries: 2,                 // retry on failure (useful in CI)
  reporter: 'html',           // generates an HTML report

  use: {
    baseURL: 'https://...',   // lets you use page.goto('/path') instead of full URL
    trace: 'on-first-retry',  // records a trace on failure for debugging
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit',   use: { ...devices['Desktop Safari'] } },
  ],
});
```

---

## Playwright MCP (AI-assisted exploration)

The **Playwright MCP server** lets an AI agent control the browser to explore pages before writing tests.

Useful MCP actions used in this workflow:
- `browser_navigate` — go to a URL
- `browser_snapshot` — get an accessibility snapshot of the current page (best for finding selectors)
- `browser_evaluate` — run JavaScript in the page to inspect the DOM
- `browser_type` — type text into an element
- `browser_click` — click an element
- `browser_take_screenshot` — capture a screenshot

---

## Quick Reference: TodoMVC Selectors

These are the verified selectors for `https://demo.playwright.dev/todomvc`:

```ts
page.getByPlaceholder('What needs to be done?')  // new todo input
page.getByTestId('todo-item')                    // each todo <li>
page.getByTestId('todo-item').first()            // first todo
page.getByTestId('todo-title')                   // todo label (inside item)
page.getByTestId('todo-count')                   // "X items left" counter
page.getByLabel('Mark all as complete')          // toggle-all checkbox
page.getByRole('link', { name: 'All' })          // filter links
page.getByRole('link', { name: 'Active' })
page.getByRole('link', { name: 'Completed' })
page.getByRole('button', { name: 'Clear completed' })
```
