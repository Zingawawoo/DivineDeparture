# Contributing to Divine Departure

Thank you for helping build Divine Departure, a 2D isometric sword-fighting RPG made with Godot 4.

This document outlines how work should be contributed, reviewed, and merged into the project.

---

## Branch Structure

### `main`
- Stable, playable branch
- Fully protected
- Only the maintainer (Code Owner) can approve and merge pull requests into `main`

### `dev`
- Integration branch for daily development
- Pull requests require **one approval** from any contributor before merging
- Should remain functional when possible

### Short-Lived Branches
Use focused, descriptive branch names:

- `feature/<name>` — new mechanics, systems, UI, etc.
- `fix/<name>` — bug fixes
- `chore/<name>` — refactors, cleanup, configuration

---

## Workflow

1. **Update your local `dev`:**

   ```bash
   git checkout dev
   git pull origin dev
   ```

2. **Create a feature branch:**

   ```bash
   git checkout -b feature/<name>
   ```

3. **Make changes in Godot** and test them locally.

4. **Stage and commit your work:**

   ```bash
   git add .
   git commit -m "Description of changes"
   ```

5. **Push your branch and open a PR into `dev`:**

   ```bash
   git push -u origin feature/<name>
   ```

6. **Request one approval.**  
   After approval and resolving any comments, the PR may be merged into `dev`.

7. **Promotion from `dev` → `main`**  
   Only the maintainer may open and approve PRs that merge into `main`.

---

## Godot Project Rules

- Use `.tscn` (scenes) and `.tres` (resources) — text formats that merge cleanly.
- Avoid binary scene formats.
- Do not commit:
  - `.godot/`
  - `.import/`
  - export presets
- Keep files organized in logical directories.
- Avoid two developers editing the same scene simultaneously.
- Test your changes before creating a pull request.

---

## Pull Request Guidelines

A good PR includes:

- Clear title: e.g., “Add dodge roll mechanic”
- Summary of what changed
- Screenshots or short clips if visual
- Testing steps
- Notes about potential issues

Smaller, focused PRs are easier to review and merge.

---

## Reporting Bugs

Open a GitHub Issue with:

- Steps to reproduce the bug
- Expected vs actual behavior
- Screenshots or videos if helpful

---

## Requesting Features

Include:

- Feature summary
- Reasoning / gameplay impact
- Optional examples, sketches, or references

---

Thank you for contributing to Divine Departure!
