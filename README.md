# CheckPlan

A local-first checklist planner — a Flutter app for learning Dart and Flutter deeply.

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
