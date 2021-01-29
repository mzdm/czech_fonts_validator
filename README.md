# czech_fonts_validator

An **experimental** Flutter app which validates Czech fonts.

[Static Web App Preview](https://gray-meadow-0950e7203.azurestaticapps.net/)

### Usages in
- [google_language_fonts](https://pub.dev/packages/google_language_fonts) Flutter package
- []()

### Run
It is recommended to run the app only on the **Web and/or Windows** to avoid inaccurate results in the confidence calculation (especially on mobile due to the small screen size).
```
flutter channel beta
flutter upgrade
flutter config --enable-web
flutter pub get
flutter run web
```

### How it works
The app fetches all [Latin Extended](https://fonts.google.com/?subset=latin-ext) font names from Google Fonts from [this generated JSON file](https://github.com/mzdm/google-language-fonts-flutter/blob/dev-1.0.0/generator/lang_font_subsets/fonts.json). Latin Extended fonts should include also letters from the Czech alphabet however there are still some fonts that don't support these letters.

This app renders both Latin Extended and Czech test phrase and then calculates the relative difference in width & height sizes and calculates the so-called '**Confidence**'.

Confidence HIGHEST means that the font most certainly supports all letters from the Czech alphabet. On the other side, LOWEST means that the font contains unsupported characters.

If you have any notes or an improvement feel free to post an [issue](https://github.com/mzdm/czech_fonts_validator/issues/new/choose) or straight up PR.
