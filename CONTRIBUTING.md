# Contributing to DAANSETU

First off, thank you for considering contributing to DAANSETU! 🎉

Every contribution helps reduce food waste and fight hunger. Whether it's fixing a bug, adding a feature, or improving documentation - your help matters.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)

## 📜 Code of Conduct

This project adheres to our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@daansetu.org.

## 🚀 Getting Started

### Prerequisites

- **Backend**: Node.js 18+, MongoDB
- **Mobile**: Flutter 3.0+, Android Studio or Xcode
- **Git**: For version control

### Fork & Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/phcoder05/daansetu.git
   cd daansetu
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/original/daansetu.git
   ```

## 🛠️ Development Setup

### Backend (backend)

```bash
cd backend
npm install
cp .env.example .env
# Configure your .env file
npm run dev
```

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
cp .env.example .env
# Configure your .env file
flutter run
```

### Running Tests

```bash
# Backend tests
cd api_ops
npm test

# Flutter tests
cd mobile
flutter test
```

## 🎯 How to Contribute

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Environment details** (OS, Node/Flutter version)

### 💡 Suggesting Features

Feature suggestions are welcome! Please include:

- **Clear use case** - why is this feature needed?
- **Proposed solution** - how should it work?
- **Alternatives considered** - other approaches you thought of

### 🔧 Contributing Code

See our [Git Workflow & Branching Strategy](docs/GIT_WORKFLOW.md) for details on branches and commit standards.

1. **Find an issue** to work on (or create one)
2. **Comment** on the issue to claim it
3. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```
4. **Make your changes** following our style guidelines
5. **Test** your changes thoroughly
6. **Commit** with meaningful messages
7. **Push** and create a Pull Request

### 📚 Improving Documentation

Documentation improvements are always welcome! This includes:
- README updates
- Code comments
- API documentation
- Tutorials and guides

## 📝 Pull Request Process

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Ensure all tests pass**
4. **Follow the PR template**
5. **Request review** from maintainers

### PR Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have tested my changes
- [ ] I have updated documentation if needed
- [ ] My changes don't break existing functionality
- [ ] I have added/updated tests if applicable

## 🎨 Style Guidelines

### JavaScript/Node.js

- Use ES6+ features
- Prefer `const` over `let`
- Use meaningful variable names
- Add JSDoc comments for functions

### Dart/Flutter

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use meaningful widget names
- Separate business logic from UI
- Use Riverpod for state management

### Commit Messages

Use conventional commits:
```
feat: add donation tracking feature
fix: resolve login crash on iOS
docs: update API documentation
style: format code with prettier
test: add unit tests for auth
```

## 🏷️ Issue Labels

| Label | Description |
|-------|-------------|
| `good first issue` | Great for newcomers |
| `help wanted` | Needs community help |
| `bug` | Something isn't working |
| `enhancement` | New feature request |
| `documentation` | Docs improvements |

## ❓ Questions?

- Open a [Discussion](https://github.com/yourusername/daansetu/discussions)
- Join our [Discord](https://discord.gg/daansetu)
- Email: contributors@daansetu.org

---

Thank you for contributing to DAANSETU! 🙏
