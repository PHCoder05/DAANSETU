# Git Workflow & Branching Strategy

To maintain a clean and stable codebase, DAANSETU follows a strict branching strategy.

## 🌳 Branches

| Branch | Purpose | Protected? |
|--------|---------|------------|
| `main` | Production-ready code. Deployed to production. | ✅ Yes |
| `develop` | Integration branch for next release. Deployed to staging. | ✅ Yes |
| `feature/*` | New features (e.g., `feature/auth-login`) | ❌ No |
| `fix/*` | Bug fixes (e.g., `fix/crash-on-ios`) | ❌ No |
| `hotfix/*` | Critical fixes for production (e.g., `hotfix/security-patch`) | ❌ No |
| `docs/*` | Documentation changes (e.g., `docs/update-readme`) | ❌ No |

## 🔄 Workflow

1.  **Start a new feature:**
    ```bash
    git checkout develop
    git pull origin develop
    git checkout -b feature/my-new-feature
    ```

2.  **Commit changes:**
    - Make granular commits.
    - Follow [Conventional Commits](https://www.conventionalcommits.org/).
    ```bash
    git commit -m "feat: add user login screen"
    ```

3.  **Push and PR:**
    ```bash
    git push origin feature/my-new-feature
    ```
    - Open a Pull Request (PR) to merge `feature/my-new-feature` into `develop`.
    - Request review from maintainers.

4.  **Merge:**
    - Once approved and CI passes, squash and merge into `develop`.

5.  **Release:**
    - When `develop` is stable and ready, create a release branch or merge `develop` into `main` via PR.

## 🏷️ Tagging

Releases on `main` are tagged with semantic versioning (e.g., `v1.0.0`, `v1.1.0`).

## 🚨 Rules

- **Never push directly to `main` or `develop`.** Always use PRs.
- **Keep PRs small.** Focus on one task per PR.
- **Resolving Conflicts:** Rebase your feature branch on `develop` before pushing.
    ```bash
    git fetch origin
    git rebase origin/develop
    ```
