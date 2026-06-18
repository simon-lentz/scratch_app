# CheckPlan

A local-first checklist planner — a Flutter app for learning Dart and Flutter deeply.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Development

### Setup

```bash
flutter pub get
```

### Quality gate

Run the same checks CI enforces before pushing:

```bash
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test
```

CI (`.github/workflows/ci.yaml`) runs format, analyze, test + coverage, and a web build on every pull
request and push to `main`. `main` is protected and requires the `build` check to pass; coverage is
gated at a baseline (`min_coverage` in the workflow) and ratcheted upward over time. Dependency
vulnerabilities are scanned by OSV-Scanner, and Dependabot opens weekly update PRs.

### Git hooks (recommended)

Format staged Dart files on commit, and run analyze + tests on push. Install the native
[lefthook](https://github.com/evilmartians/lefthook), then activate the hooks:

```bash
brew install lefthook   # macOS (see lefthook docs for other platforms)
lefthook install        # installs hooks into .git/hooks
```

Hook config lives in `lefthook.yml`. (The `lefthook_dart` pub wrapper is **not** recommended — v1.0.8
crashes on Apple Silicon: it has no `arm64` branch in its binary-download logic.)
