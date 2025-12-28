# Contributing to Grassroots Canvass

Thank you for considering contributing to Grassroots Canvass! This project exists to help grassroots campaigns and independent candidates run effective voter outreach.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/jotra7/grassroots-canvass/issues) first
2. Open a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Device/browser/OS information

### Suggesting Features

1. Open a [GitHub Discussion](https://github.com/jotra7/grassroots-canvass/discussions) first
2. Describe the use case and who would benefit
3. If there's interest, we'll create an issue for implementation

### Submitting Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Open a Pull Request

### Code Style

**Flutter/Dart:**
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `flutter analyze` before committing
- Use meaningful variable and function names

**TypeScript/Next.js:**
- Run `npm run lint` before committing
- Use TypeScript types (avoid `any`)
- Follow existing patterns in the codebase

### Documentation

Improvements to documentation are always welcome:
- Fix typos or unclear instructions
- Add missing steps to guides
- Translate documentation

## Development Setup

### Flutter App

```bash
cd flutter-app
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Admin Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

### Database

Use Supabase local development:
```bash
supabase start
```

## Priority Areas

Current priorities for contributions:

1. **Bug fixes** - Always welcome
2. **Documentation** - Especially for non-technical users
3. **Testing** - Unit tests, integration tests
4. **Accessibility** - Screen reader support, keyboard navigation
5. **Internationalization** - Translations for non-English campaigns

## Questions?

- Open a [Discussion](https://github.com/jotra7/grassroots-canvass/discussions)
- Check the [FAQ](docs/FAQ.md)

## License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license.
