# MathSolve

Professional Flutter Android app for solving mathematics locally.

## Product features
- Manual equation/expression input
- Camera and gallery OCR
- Editable OCR review before solving
- Device speech-to-text input
- Offline math engine, no AI API and no cloud solver
- Arithmetic/expression evaluation
- Algebraic simplification
- Linear equations
- Quadratic equations
- Two-variable linear systems
- Linear inequalities
- Derivatives
- Transformation-based solution history
- Answer-only and step-by-step modes
- Persistent local history
- Settings screen
- Light-only professional interface
- Codemagic Android APK workflow

## Supported examples
- `2x + 6 = 14`
- `x^2 - 5x + 6 = 0`
- `2x + 3y = 7; x - y = 1`
- `3x - 4 > 8`
- `2 + 5 * 3`
- `x^2 + 2x + 1`
- `derivative: x^3 + 2x`
- `d/dx (x^2 + 3x)`

## OCR
Generic OCR is not a mathematical handwriting recognizer. Fractions, roots, superscripts, matrices and handwritten symbols can be misread. MathSolve always lets the user edit detected text before solving.

## Offline note
The solver is local. OCR is performed locally by Google ML Kit. Speech recognition uses the device/platform speech service and may require the device's installed speech language resources. No AI API key is required.

## Build
Use Flutter 3.44+ / Dart 3.12+.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

For Codemagic, the repository includes `codemagic.yaml`.
