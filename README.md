# playwright-MCP-learning

A learning project for Playwright test automation and the `@playwright/mcp` server with Windsurf (Cascade).

## Running Tests

```bash
npm test
# or
npx playwright test
```

## Playwright MCP Server (Windsurf / AI-driven automation)

The `playwright` MCP server is registered in `~/.codeium/windsurf/mcp_config.json`. After reloading MCP servers in Windsurf, Cascade can control a real browser via natural language.

**Example prompts to try with Cascade:**
- "Navigate to https://playwright.dev/ and take a screenshot"
- "Click the Get started link and tell me what's on the page"
- "Fill in the search box with 'locators' and show me the results"

The `--isolated` flag gives each session its own clean browser context.

## Project Structure

```
tests/
  example.spec.ts   # Basic Playwright tests against playwright.dev
playwright.config.ts
package.json
tsconfig.json
```