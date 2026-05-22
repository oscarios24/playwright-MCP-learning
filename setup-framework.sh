#!/usr/bin/env bash
# =============================================================================
# Playwright Automation Framework Setup Script
# =============================================================================
# Usage: Place this file in a new empty project folder, then run:
#   chmod +x setup-framework.sh && ./setup-framework.sh
# =============================================================================

set -e  # Exit immediately on any error

PROJECT_DIR="$(pwd)"
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
RESET="\033[0m"

info()    { echo -e "${CYAN}ℹ  $*${RESET}"; }
success() { echo -e "${GREEN}✅ $*${RESET}"; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

header "========================================="
header " Playwright Framework Setup"
header "========================================="
info "Project root: $PROJECT_DIR"

# ─── 1. Directory structure ───────────────────────────────────────────────────
header "1/7  Creating directory structure..."
mkdir -p page-objects/base
mkdir -p test-support
mkdir -p tests/UI
mkdir -p data
mkdir -p .auth
mkdir -p test-results
success "Directories created."

# ─── 2. package.json ─────────────────────────────────────────────────────────
header "2/7  Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "playwright-automation-framework",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "stateless-tests": "npx playwright test --project=chromium --grep '@safe' --workers=4 --fully-parallel",
    "stateful-tests": "npx playwright test --project=chromium --grep-invert '@safe' --workers=1",
    "test": "npx playwright test",
    "test:headed": "npx playwright test --headed",
    "report": "npx playwright show-report",
    "allure:generate": "allure generate allure-results -o allure-report --clean",
    "allure:open": "allure open allure-report"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "description": "Playwright E2E automation framework",
  "devDependencies": {
    "@faker-js/faker": "^8.4.1",
    "@playwright/test": "^1.48.2",
    "@types/node": "^20.19.39",
    "allure-playwright": "^3.0.0-beta.10",
    "chalk": "^4.1.2",
    "dotenv": "^16.4.5",
    "npm-run-all": "^4.1.5",
    "xlsx": "^0.18.5"
  }
}
EOF
success "package.json created."

# ─── 3. tsconfig.json ────────────────────────────────────────────────────────
header "3/7  Creating tsconfig.json..."
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "types": ["node", "@playwright/test"]
  },
  "include": [
    "**/*.ts",
    "**/*.js"
  ],
  "exclude": [
    "node_modules",
    "dist"
  ]
}
EOF
success "tsconfig.json created."

# ─── 4. Config / setup files ─────────────────────────────────────────────────
header "4/7  Creating Playwright config and supporting files..."

# playwright.config.ts
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

require('dotenv').config();

export default defineConfig({
  testDir: './tests',
  timeout: 60000,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['json',  { outputFile: 'test-results/jsonReport.json' }],
    ['junit', { outputFile: 'test-results/junitReport.xml' }],
    ['allure-playwright'],
    ['html'],
  ],
  globalSetup: require.resolve('./global-setup'),
  use: {
    extraHTTPHeaders: {
      'CF-Access-Client-Id':     process.env.CF_ACCESS_CLIENT_ID     || '',
      'CF-Access-Client-Secret': process.env.CF_ACCESS_CLIENT_SECRET || '',
    },
    baseURL: process.env.BASE_URL || 'https://your-app-url.com/',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        deviceScaleFactor: undefined,
        viewport: null,
        launchOptions: { args: ['--start-maximized'] },
      },
    },
    {
      name: 'firefox',
      use: {
        ...devices['Desktop Firefox'],
        deviceScaleFactor: undefined,
        viewport: null,
        launchOptions: { args: ['--start-maximized'] },
      },
    },
    {
      name: 'webkit',
      use: {
        ...devices['Desktop Safari'],
        deviceScaleFactor: undefined,
        viewport: null,
        launchOptions: { args: ['--start-maximized'] },
      },
    },
  ],
});
EOF

# global-setup.ts
cat > global-setup.ts << 'EOF'
import { request } from '@playwright/test';
import { HttpClient } from './test-support/httpClient';
import { Utils } from './test-support/utils';
import fs from 'fs';

const regularAuthFile = '.auth/regular_user.json';
const adminAuthFile   = '.auth/admin_user.json';
const httpClient      = new HttpClient();

/**
 * Obtains an auth token for the given email and writes it to the auth file.
 */
async function raiseAuthFile(email: string | undefined): Promise<void> {
  const responseBody = await httpClient.getUserInfo(email, Utils.generateOneTimeCode());
  const authToken    = responseBody.data.token;

  const isAdmin = email !== process.env.NORMAL_USER_EMAIL;
  const filePath = isAdmin ? adminAuthFile : regularAuthFile;
  const envKey   = isAdmin ? 'ADMIN_AUTH_TOKEN' : 'REGULAR_AUTH_TOKEN';

  const content = { data: { token: authToken } };
  fs.writeFileSync(filePath, JSON.stringify(content, null, 2));
  process.env[envKey] = authToken;
}

async function globalSetup(): Promise<void> {
  await raiseAuthFile(process.env.NORMAL_USER_EMAIL);
  await raiseAuthFile(process.env.ADMIN_USER_EMAIL);
}

export default globalSetup;
EOF

# test-options.ts
cat > test-options.ts << 'EOF'
import { test as base, Page } from '@playwright/test';
import { PageManager } from './page-objects/pageManager';
import { HttpClient } from './test-support/httpClient';
import { Utils } from './test-support/utils';

export type TestOptions = {
  pageManager: PageManager;
  httpClient: HttpClient;
  RegularUserLogin: string;
  AdminUserLogin: string;
};

async function performUILogin(page: Page): Promise<void> {
  await page.reload();
  const pm = new PageManager(page);
  await pm.onLoginPage().clickOnLogInBtn();
  await page.waitForLoadState('networkidle');
}

export const test = base.extend<TestOptions>({
  pageManager: async ({ page }, use) => {
    const pm = new PageManager(page);
    await use(pm);
  },

  httpClient: async ({}, use) => {
    const client = new HttpClient();
    await use(client);
  },

  RegularUserLogin: async ({ page }, use) => {
    try {
      await page.goto(`/login?email=${process.env.NORMAL_USER_EMAIL}&token=${Utils.generateOneTimeCode()}`);
      await performUILogin(page);
      await use('');
    } catch (error) {
      console.error('Error during RegularUserLogin setup:', error);
      throw error;
    }
  },

  AdminUserLogin: async ({ page }, use) => {
    try {
      await page.goto(`/login?email=${process.env.ADMIN_USER_EMAIL}&token=${Utils.generateOneTimeCode()}`);
      await performUILogin(page);
      await use('');
    } catch (error) {
      console.error('Error during AdminUserLogin setup:', error);
      throw error;
    }
  },
});

export { expect } from '@playwright/test';
EOF

success "Playwright config and setup files created."

# ─── 5. Source files (test-support + page-objects) ───────────────────────────
header "5/7  Creating framework source files..."

# test-support/logger.ts
cat > test-support/logger.ts << 'EOF'
import chalk from 'chalk';

export const logger = {
  info:    (msg: string) => console.log(chalk.blueBright(`ℹ INFO: ${msg}`)),
  action:  (msg: string) => console.log(chalk.cyanBright(`👉 ACTION: ${msg}`)),
  success: (msg: string) => console.log(chalk.green(`✅ SUCCESS: ${msg}`)),
  warning: (msg: string) => console.log(chalk.yellow(`⚠ WARNING: ${msg}`)),
  error:   (msg: string) => console.log(chalk.red(`❌ ERROR: ${msg}`)),
};
EOF

# test-support/utils.ts
cat > test-support/utils.ts << 'EOF'
import { faker } from '@faker-js/faker';

export class Utils {

  /**
   * Generates a one-time login code: LOGIN_CODE prefix + mmdd.
   */
  static generateOneTimeCode(): string {
    const now   = new Date();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day   = String(now.getDate()).padStart(2, '0');
    return `${process.env.LOGIN_CODE}${month}${day}`;
  }

  /**
   * Returns today's date formatted as yyyy-mm-dd.
   */
  static getCurrentDateFormatted(): string {
    const today = new Date();
    const year  = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day   = String(today.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * Adds the given number of days to a yyyy-mm-dd date string.
   */
  static addDaysToDate(dateStr: string, daysToAdd: number): string {
    const [year, month, day] = dateStr.split('-').map(Number);
    const date = new Date(year, month - 1, day);
    date.setDate(date.getDate() + daysToAdd);
    return [
      date.getFullYear(),
      String(date.getMonth() + 1).padStart(2, '0'),
      String(date.getDate()).padStart(2, '0'),
    ].join('-');
  }

  /**
   * Returns a random string of the given length using faker.
   */
  static randomString(length = 8): string {
    return faker.string.alphanumeric(length);
  }

  /**
   * Returns a random email address.
   */
  static randomEmail(): string {
    return faker.internet.email();
  }
}
EOF

# test-support/httpClient.ts
cat > test-support/httpClient.ts << 'EOF'
import { request, APIResponse, APIRequestContext } from '@playwright/test';

export type PostOptions = {
  data?: unknown;
  multipart?: Record<string, unknown>;
  headers?: Record<string, string>;
};

export class HttpClient {
  private context: APIRequestContext | undefined;

  constructor() {
    this.initContext();
  }

  private async initContext(): Promise<void> {
    this.context = await request.newContext({
      extraHTTPHeaders: {
        'CF-Access-Client-Id':     process.env.CF_ACCESS_CLIENT_ID     || '',
        'CF-Access-Client-Secret': process.env.CF_ACCESS_CLIENT_SECRET || '',
      },
    });
  }

  private async ensureContext(): Promise<void> {
    if (!this.context) await this.initContext();
  }

  /**
   * Sends a GET request and returns the parsed JSON body.
   */
  async get<T = unknown>(url: string, headers?: Record<string, string>): Promise<T> {
    await this.ensureContext();
    const response = await this.context!.get(url, { headers });
    if (!response.ok()) {
      throw new Error(`GET ${url} failed [${response.status()}]: ${await response.text()}`);
    }
    return response.json() as Promise<T>;
  }

  /**
   * Sends a POST request and returns the parsed JSON body.
   */
  async post<T = unknown>(url: string, options: PostOptions): Promise<T> {
    await this.ensureContext();
    const response = await this.context!.post(url, options);
    if (!response.ok()) {
      throw new Error(`POST ${url} failed [${response.status()}]: ${await response.text()}`);
    }
    return response.json() as Promise<T>;
  }

  /**
   * Sends a PUT request and returns the parsed JSON body.
   */
  async put<T = unknown>(url: string, data: unknown, headers?: Record<string, string>): Promise<T> {
    await this.ensureContext();
    const response = await this.context!.put(url, { data, headers });
    if (!response.ok()) {
      throw new Error(`PUT ${url} failed [${response.status()}]: ${await response.text()}`);
    }
    return response.json() as Promise<T>;
  }

  /**
   * Sends a DELETE request.
   */
  async delete(url: string, headers?: Record<string, string>): Promise<APIResponse> {
    await this.ensureContext();
    const response = await this.context!.delete(url, { headers });
    if (!response.ok()) {
      throw new Error(`DELETE ${url} failed [${response.status()}]: ${await response.text()}`);
    }
    return response;
  }

  /**
   * Fetches user info from the auth endpoint.
   * Override or extend this method to match your API contract.
   */
  async getUserInfo(email: string | undefined, token: string): Promise<{ data: { token: string } }> {
    const baseUrl = process.env.API_BASE_URL || process.env.BASE_URL || '';
    return this.get(`${baseUrl}/api/auth/login?email=${email}&token=${token}`);
  }
}
EOF

# page-objects/pageBase.ts
cat > page-objects/pageBase.ts << 'EOF'
import { Locator, Page } from '@playwright/test';
import { logger } from '../test-support/logger';

/**
 * Base class for all Page Objects.
 * Provides common wait helpers and shared locators.
 */
export class PageBase {
  readonly page: Page;
  protected logger = logger;

  // Shared locators common across pages
  readonly exportToExcelButton: Locator;
  readonly resetFiltersButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.exportToExcelButton = page.getByRole('button', { name: 'Export to Excel' });
    this.resetFiltersButton  = page.getByRole('button', { name: 'Reset filters' });
  }

  /**
   * Hard wait — use sparingly.
   * @param timeInSeconds Number of seconds to wait.
   */
  async waitForNumberOfSeconds(timeInSeconds: number): Promise<void> {
    await this.page.waitForTimeout(timeInSeconds * 1000);
  }

  /**
   * Waits for an element to become visible.
   * @param locator CSS / Playwright selector string.
   * @param timeoutSeconds Timeout in seconds (default 10).
   */
  async waitForElement(locator: string, timeoutSeconds = 10): Promise<void> {
    try {
      await this.page.waitForSelector(locator, {
        state: 'visible',
        timeout: timeoutSeconds * 1000,
      });
    } catch (error) {
      this.logger.error(`Element '${locator}' not visible after ${timeoutSeconds}s`);
      throw error;
    }
  }

  /**
   * Waits for an element to become visible and clicks it.
   * @param locator CSS / Playwright selector string.
   * @param timeoutSeconds Timeout in seconds (default 10).
   */
  async waitForElementAndClick(locator: string, timeoutSeconds = 10): Promise<void> {
    await this.waitForElement(locator, timeoutSeconds);
    const element = this.page.locator(locator);
    await element.waitFor({ state: 'attached' });
    await element.click();
  }

  /**
   * Navigates to a path relative to baseURL.
   * @param path URL path (e.g. '/dashboard').
   */
  async navigate(path: string): Promise<void> {
    await this.page.goto(path);
  }
}
EOF

# page-objects/loginPage.ts  — minimal template
cat > page-objects/loginPage.ts << 'EOF'
import { Page } from '@playwright/test';
import { PageBase } from './pageBase';

/**
 * Page Object for the Login page.
 * Extend with selectors and actions specific to your application.
 */
export class LoginPage extends PageBase {
  // ── Locators ──────────────────────────────────────────────────────────────
  // Use data-testid > id > text as priority order for selectors.
  private readonly logInButton = this.page.getByRole('button', { name: 'Log in' });

  constructor(page: Page) {
    super(page);
  }

  /**
   * Clicks the main Log In button (e.g. after SSO redirect).
   */
  async clickOnLogInBtn(): Promise<void> {
    this.logger.action('Clicking Log In button');
    await this.logInButton.click();
    this.logger.success('Clicked Log In button');
  }

  /**
   * Fills email and password and submits the form.
   */
  async loginWithCredentials(email: string, password: string): Promise<void> {
    this.logger.action(`Logging in as ${email}`);
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.logInButton.click();
    this.logger.success('Login submitted');
  }
}
EOF

# page-objects/pageManager.ts  — minimal template
cat > page-objects/pageManager.ts << 'EOF'
import { Page } from '@playwright/test';
import { LoginPage } from './loginPage';
// Import additional page objects here as the project grows.

/**
 * Central access point for all Page Objects.
 * Instantiate once per test via the `pageManager` fixture.
 */
export class PageManager {
  private readonly page: Page;

  // ── Page Object instances ─────────────────────────────────────────────────
  private readonly loginPage: LoginPage;

  constructor(page: Page) {
    this.page = page;
    this.loginPage = new LoginPage(page);
  }

  onLoginPage(): LoginPage {
    return this.loginPage;
  }

  // Add accessor methods for each new page object:
  // onDashboardPage(): DashboardPage { return this.dashboardPage; }
}
EOF

# page-objects/base/basePage.ts  — base for report/complex pages
cat > page-objects/base/basePage.ts << 'EOF'
import { Page } from '@playwright/test';
import { PageBase } from '../pageBase';

/**
 * Extended base for pages that share report-specific helpers.
 * Extend this instead of PageBase when building report page objects.
 */
export class BaseReportPage extends PageBase {
  constructor(page: Page) {
    super(page);
  }

  /**
   * Clicks the Export to Excel button and waits for the download.
   */
  async exportToExcel(): Promise<void> {
    const [download] = await Promise.all([
      this.page.waitForEvent('download'),
      this.exportToExcelButton.click(),
    ]);
    this.logger.success(`Download started: ${download.suggestedFilename()}`);
  }
}
EOF

# tests/UI/example.spec.ts
cat > tests/UI/example.spec.ts << 'EOF'
import { test, expect } from '../../test-options';

/**
 * Example test suite — replace with your actual test cases.
 * Tags: @safe (stateless/parallel-safe) | @smoke | @regression
 */
test.describe('Example suite @safe', () => {

  test('Page title is correct @smoke', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/.+/); // replace regex with actual title
  });

  test('Login page renders @smoke', async ({ pageManager, RegularUserLogin }) => {
    // RegularUserLogin fixture performs the SSO login flow automatically.
    // pageManager gives access to all page objects.
    // Add assertions here.
    expect(RegularUserLogin).toBeDefined();
  });

});
EOF

# .gitignore
cat > .gitignore << 'EOF'
node_modules/
dist/
.env
.auth/
test-results/
playwright-report/
allure-results/
allure-report/
EOF

success "Source files created."

# ─── 6. .env.example ─────────────────────────────────────────────────────────
header "6/7  Creating .env.example..."
cat > .env.example << 'EOF'
# ── Application ───────────────────────────────────────────────────────────────
BASE_URL=https://your-app-url.com/
API_BASE_URL=https://your-api-url.com

# ── Auth credentials ──────────────────────────────────────────────────────────
NORMAL_USER_EMAIL=user@example.com
ADMIN_USER_EMAIL=admin@example.com

# ── One-time login code prefix ────────────────────────────────────────────────
LOGIN_CODE=yourCode

# ── Cloudflare Access (if applicable) ────────────────────────────────────────
CF_ACCESS_CLIENT_ID=
CF_ACCESS_CLIENT_SECRET=
EOF

# Create a blank .env for immediate use
cp .env.example .env
success ".env.example and .env created."

# ─── 7. Install dependencies ──────────────────────────────────────────────────
header "7/7  Installing npm dependencies..."
npm install

echo ""
info "Installing Playwright browsers (chromium, firefox, webkit)..."
npx playwright install chromium firefox webkit

echo ""
echo -e "${BOLD}${GREEN}========================================="
echo " Setup complete!"
echo "=========================================${RESET}"
echo ""
echo -e "  Next steps:"
echo -e "  1. Fill in ${YELLOW}.env${RESET} with your project credentials"
echo -e "  2. Update ${YELLOW}playwright.config.ts${RESET} baseURL if needed"
echo -e "  3. Add your page objects in ${YELLOW}page-objects/${RESET}"
echo -e "  4. Add your tests in ${YELLOW}tests/UI/${RESET}"
echo -e "  5. Run tests: ${YELLOW}npx playwright test${RESET}"
echo ""
