## Summary

<!-- What does this change do, and why? -->

## Type of change

- [ ] feat — new feature
- [ ] fix — bug fix
- [ ] refactor — no behaviour change
- [ ] docs / test / chore

## Testing

<!-- How did you verify this? -->

```bash
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test
```

## Checklist

- [ ] `dart format` clean and `flutter analyze` at zero issues
- [ ] Tests added/updated and passing; coverage holds (`flutter test --coverage`)
- [ ] Generated code regenerated if schema/providers changed (`dart run build_runner build`)
- [ ] PR title follows Conventional Commits (`feat:`, `fix:`, …)
