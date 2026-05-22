import { test, expect, type Page } from '@playwright/test';

const TODO_URL = 'https://demo.playwright.dev/todomvc';

// Helper: add a single todo item
async function addTodo(page: Page, text: string) {
  await page.getByPlaceholder('What needs to be done?').fill(text);
  await page.getByPlaceholder('What needs to be done?').press('Enter');
}

test.describe('TodoMVC', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(TODO_URL);
  });

  // ─── Adding todos ────────────────────────────────────────────────────────────

  test('should display the app and empty input on load', async ({ page }) => {
    await expect(page).toHaveTitle(/TodoMVC/);
    await expect(page.getByPlaceholder('What needs to be done?')).toBeVisible();
    await expect(page.getByPlaceholder('What needs to be done?')).toBeEmpty();
  });

  test('should add a single todo item', async ({ page }) => {
    await addTodo(page, 'Buy groceries');

    await expect(page.getByText('Buy groceries')).toBeVisible();
    await expect(page.getByTestId('todo-item')).toHaveCount(1);
  });

  test('should add multiple todo items', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');
    await addTodo(page, 'Read a book');

    await expect(page.getByTestId('todo-item')).toHaveCount(3);
  });

  test('should clear the input field after adding a todo', async ({ page }) => {
    await addTodo(page, 'Buy groceries');

    await expect(page.getByPlaceholder('What needs to be done?')).toBeEmpty();
  });

  // ─── Completing todos ─────────────────────────────────────────────────────────

  test('should mark a todo as completed', async ({ page }) => {
    await addTodo(page, 'Buy groceries');

    const todoItem = page.getByTestId('todo-item').first();
    await todoItem.getByRole('checkbox').check();

    await expect(todoItem).toHaveClass(/completed/);
  });

  test('should uncheck a completed todo', async ({ page }) => {
    await addTodo(page, 'Buy groceries');

    const checkbox = page.getByTestId('todo-item').first().getByRole('checkbox');
    await checkbox.check();
    await checkbox.uncheck();

    await expect(page.getByTestId('todo-item').first()).not.toHaveClass(/completed/);
  });

  // ─── Editing todos ────────────────────────────────────────────────────────────

  test('should edit a todo item on double-click', async ({ page }) => {
    await addTodo(page, 'Buy groceries');

    const todoLabel = page.getByTestId('todo-item').first().getByTestId('todo-title');
    await todoLabel.dblclick();

    const editInput = page.getByTestId('todo-item').first().getByRole('textbox');
    await editInput.clear();
    await editInput.fill('Buy organic groceries');
    await editInput.press('Enter');

    await expect(page.getByText('Buy organic groceries')).toBeVisible();
  });

  // ─── Deleting todos ───────────────────────────────────────────────────────────

  test('should delete a todo item by clicking the × button', async ({ page }) => {
    await addTodo(page, 'Buy groceries');

    const todoItem = page.getByTestId('todo-item').first();
    await todoItem.hover();
    await todoItem.getByRole('button', { name: '' }).click(); // × destroy button

    await expect(page.getByTestId('todo-item')).toHaveCount(0);
  });

  // ─── Filtering todos ──────────────────────────────────────────────────────────

  test('should filter: show only active todos', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');

    await page.getByTestId('todo-item').first().getByRole('checkbox').check();

    await page.getByRole('link', { name: 'Active' }).click();

    await expect(page.getByTestId('todo-item')).toHaveCount(1);
    await expect(page.getByText('Walk the dog')).toBeVisible();
  });

  test('should filter: show only completed todos', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');

    await page.getByTestId('todo-item').first().getByRole('checkbox').check();

    await page.getByRole('link', { name: 'Completed' }).click();

    await expect(page.getByTestId('todo-item')).toHaveCount(1);
    await expect(page.getByText('Buy groceries')).toBeVisible();
  });

  test('should filter: show all todos', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');

    await page.getByTestId('todo-item').first().getByRole('checkbox').check();
    await page.getByRole('link', { name: 'Active' }).click();
    await page.getByRole('link', { name: 'All' }).click();

    await expect(page.getByTestId('todo-item')).toHaveCount(2);
  });

  // ─── Footer counter ───────────────────────────────────────────────────────────

  test('should display the correct items left count', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');
    await addTodo(page, 'Read a book');

    await expect(page.getByTestId('todo-count')).toContainText('3 items left');

    await page.getByTestId('todo-item').first().getByRole('checkbox').check();

    await expect(page.getByTestId('todo-count')).toContainText('2 items left');
  });

  // ─── Clear completed ──────────────────────────────────────────────────────────

  test('should clear completed todos', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');

    await page.getByTestId('todo-item').first().getByRole('checkbox').check();

    await page.getByRole('button', { name: 'Clear completed' }).click();

    await expect(page.getByTestId('todo-item')).toHaveCount(1);
    await expect(page.getByText('Walk the dog')).toBeVisible();
  });

  // ─── Toggle all ───────────────────────────────────────────────────────────────

  test('should toggle all todos as completed', async ({ page }) => {
    await addTodo(page, 'Buy groceries');
    await addTodo(page, 'Walk the dog');
    await addTodo(page, 'Read a book');

    await page.getByLabel('Mark all as complete').check();

    const items = page.getByTestId('todo-item');
    await expect(items).toHaveCount(3);
    for (const item of await items.all()) {
      await expect(item).toHaveClass(/completed/);
    }
  });
});
