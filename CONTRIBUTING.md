# Contributing to EleuMind 🧘‍♂️

Thanks for your interest in contributing to **EleuMind**!  
This project is developed by **EleuCode** as a **free, open source, privacy-first meditation app**.  
We welcome code, documentation, testing, and design contributions.

---

## 📌 Branching Model
All changes must be made on a **feature branch**, never directly to `develop` or `main`.

- `docs/MIND-#/ticket-title` → documentation updates  
- `fix/MIND-#/ticket-title` → bug fixes  
- `feat/MIND-#/ticket-title` → new features tied to an Issue  

Example:  
```bash
git checkout -b feat/MIND-9/timer-ui-scaffold
```

---

## ✍️ Commit Messages
Commits must reference the corresponding Issue ID.

Format:
```
MIND-#: Short title
```

Example:
```
MIND-9: Add Timer screen scaffold
```

If a commit needs more detail, include it in the message body below the title.

---

## 🔀 Pull Requests
- Target branch: `develop`  
- Provide a list of changes.
- Add **Notes** if there are limitations or TODOs.  
- Include a **Feature image** if applicable (screenshots encouraged).  
- Link the PR to the corresponding Issue (`Ex: Closes #9`).  

---

## ⚙️ Development Setup
1. Install [Flutter](https://docs.flutter.dev/get-started/install).  
2. Clone the repository and install dependencies:  
   ```bash
   git clone https://github.com/EleuCode/eleumind.git
   cd eleumind
   flutter pub get
   ```
3. Run on simulator/emulator:  
   ```bash
   flutter run -d ios      # iOS Simulator  
   flutter run -d android  # Android Emulator  
   flutter run -d macos    # macOS desktop  
   flutter run -d chrome   # Web  
   ```

---

## ✅ Testing
- **All new features must include tests.**  
- Run tests locally:  
  ```bash
  flutter test
  ```
- **All tests must pass** before merge.

---

## 🧭 Project Standards
- Accessibility (a11y) is required: labels, large text scaling, screen reader support.  
- No data collection, tracking, or telemetry will be accepted.  
- Code must follow Flutter/Dart conventions (dart format).  
- Keep PRs focused (< ~400 lines changed).  

---

## 🤝 Code of Conduct
Participation in this project is governed by the [Code of Conduct](./CODE_OF_CONDUCT.md).  
By contributing, you agree to abide by it.
