# ClarifyApp 📰

A clean, modern article reader app built with Expo and React Native. ClarifyApp allows you to save articles from URLs and read them in a distraction-free interface.

## Features

- 📱 Clean, modern UI with card-based article layout
- 🔗 Add articles by copying URLs to clipboard
- 📖 Distraction-free reading experience
- 💾 Local storage with AsyncStorage
- 🎨 Beautiful modal interfaces
- 📱 Cross-platform (iOS, Android, Web)

## Tech Stack

- **Framework**: Expo with Expo Router
- **Language**: TypeScript
- **Navigation**: File-based routing
- **Storage**: AsyncStorage
- **UI**: React Native with custom styling

## Get started

1. Install dependencies

   ```bash
   npm install
   ```

2. Start the app

   ```bash
   npx expo start
   ```

3. Open the app in:
   - [Expo Go](https://expo.dev/go) on your phone
   - [Android emulator](https://docs.expo.dev/workflow/android-studio-emulator/)
   - [iOS simulator](https://docs.expo.dev/workflow/ios-simulator/)
   - Web browser

## How to use

1. Copy an article URL to your clipboard
2. Tap the "+" button in the app
3. Tap "Paste Article URL" to add the article
4. Tap on any article card to read it in full-screen mode

## Project Structure

```
app/
├── (tabs)/          # Tab-based navigation
├── _layout.tsx      # Root layout
├── index.tsx        # Main article list screen
└── modal.tsx        # Modal screens
```

## Learn more

To learn more about developing your project with Expo, look at the following resources:

- [Expo documentation](https://docs.expo.dev/): Learn fundamentals, or go into advanced topics with our [guides](https://docs.expo.dev/guides).
- [Learn Expo tutorial](https://docs.expo.dev/tutorial/introduction/): Follow a step-by-step tutorial where you'll create a project that runs on Android, iOS, and the web.

## Join the community

Join our community of developers creating universal apps.

- [Expo on GitHub](https://github.com/expo/expo): View our open source platform and contribute.
- [Discord community](https://chat.expo.dev): Chat with Expo users and ask questions.
