# Divine Departure

[![GDD Society](https://img.shields.io/badge/UoB%20GDD%20Society-8E24AA?style=for-the-badge&logo=github)](https://github.com/Zingawawoo/GDD-Repo)

Divine Departure is a 2D isometric sword-fighting RPG built in **Godot 4**.

This repo is set up for team development with a protected `main` branch and a collaborative `dev` branch.

> Part of the **University of Bristol Game Development & Design Society**  
> 🔗 https://github.com/Zingawawoo/GDD-Repo  

---

## Requirements

- Godot Engine **4.x** (latest stable recommended)
- Git

---

## Getting Started

1. **Clone the project:**

   ```bash
   git clone <SSH-or-HTTPS-url-of-this-repo>
   cd divine-departure
   ```

2. **Open the project in Godot:**
   - Launch Godot 4
   - Click Import
   - Select `project.godot` in this folder

3. **Run the game:**
   - Press Play inside the Godot editor

---

## Branch Model

### `main`
- Stable, playable builds only
- Protected branch
- Pull requests into `main` must be approved and merged by the project maintainer (Code Owner)

### `dev`
- Shared integration branch
- All feature work is merged here after at least one approval from any contributor

### Feature Branches
Use short-lived branches for focused changes:
- `feature/...` — new gameplay, systems, mechanics
- `fix/...` — bug fixes
- `chore/...` — refactors, tooling, or non-gameplay changes

---

## Contributing

See the full contribution workflow in [CONTRIBUTING.md](CONTRIBUTING.md).

### Basic workflow

1. Update local `dev`:

   ```bash
   git checkout dev
   git pull origin dev
   ```

2. Create a new branch:

   ```bash
   git checkout -b feature/name
   ```

3. Make your changes in Godot

4. Commit your changes:

   ```bash
   git add .
   git commit -m "Description of changes"
   ```

5. Push your branch and open a PR into `dev`:

   ```bash
   git push -u origin feature/name
   ```

6. Get one approval  
   Once approved, the PR can be merged into `dev`.

7. Promotions from `dev` → `main`  
   These are handled only by the maintainer.

---

## Godot Guidelines

- Use `.tscn` for scenes and `.tres` for resources
- Use text-based formats to keep merges clean
- Avoid two people editing the same scene simultaneously
- Keep folders organized and consistent
- Test your changes before opening a PR

---

## Issues & Feature Requests

Use GitHub Issues.

### Bug Reports
Include:
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or video

### Feature Requests
Include:
- Short description
- Gameplay impact
- Optional references or mockups

---

## 🏛️ Part of the Game Development & Design Society

This project is developed as part of the  
**University of Bristol Game Development & Design Society (GDD).**

- 🌐 Society Hub Repo: https://github.com/Zingawawoo/GDD-Repo  
- 📚 Workshops, resources, and documentation  
- 🎮 Other student-led game projects  


---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.


---

## Credits

Divine Departure is developed by the Game Development and Design Society and contributors.
