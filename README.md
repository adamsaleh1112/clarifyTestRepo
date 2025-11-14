# Clarify Swift

A SwiftUI-based iOS app for reading and annotating articles with advanced text processing features.

## Features

- 📱 Native SwiftUI interface optimized for iPhone and iPad
- 📖 Advanced reading features (Center Stage, Tunnel Vision, Bionic Reading)
- ✏️ Text selection and annotation capabilities
- 🤖 AI-powered content processing with OpenAI integration
- 🎨 Responsive grid layout with device-specific column counts
- 🌙 Dark/Light mode support

## Setup

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.0 or later

### Environment Configuration

This app requires an OpenAI API key for AI features. Set up your environment:

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Add your OpenAI API key to `.env`:**
   ```
   OPENAI_API_KEY=your_actual_api_key_here
   ```

3. **Alternative: Set environment variable (for CI/CD):**
   ```bash
   export OPENAI_API_KEY=your_actual_api_key_here
   ```

### Building and Running

1. **Clone the repository:**
   ```bash
   git clone https://github.com/adamsaleh1112/clarifyTestRepo.git
   cd clarifyTestRepo
   ```

2. **Open in Xcode:**
   ```bash
   open Clarify.xcodeproj
   ```

3. **Install dependencies:**
   - Swift Package Manager will automatically resolve dependencies
   - Main dependency: SwiftSoup for HTML parsing

4. **Build and run:**
   - Select your target device/simulator
   - Press ⌘+R to build and run

## Project Structure

```
Clarify Swift/
├── .env.example          # Environment variables template
├── .gitignore           # Git ignore rules
├── Clarify.xcodeproj/   # Xcode project files
├── Clarify/             # Main app source code
│   ├── Clarify/         # Swift source files
│   │   ├── ClarifyApp.swift        # App entry point
│   │   ├── ContentView.swift       # Main content view
│   │   ├── ArticleDetailView.swift # Article reading interface
│   │   ├── ArticleGridView.swift   # Article grid layout
│   │   ├── EnvironmentConfig.swift # Environment configuration
│   │   ├── OpenAIService.swift     # AI integration
│   │   └── ...                     # Other source files
│   ├── Assets.xcassets/ # App icons and resources
│   ├── Info.plist       # App configuration
│   └── Base.lproj/      # Localization resources
└── README.md            # This file
```

## Security

- ✅ API keys are stored in environment variables or `.env` files
- ✅ `.env` files are excluded from version control
- ✅ No secrets are hardcoded in source code
- ✅ GitHub push protection prevents accidental secret commits

## Development

### Adding New Environment Variables

1. Add the variable to `.env.example` with a placeholder value
2. Add the actual value to your local `.env` file
3. Update `EnvironmentConfig.swift` to read the new variable
4. Document the variable in this README

### Git Workflow

- `main` branch: Production-ready code with full Xcode project setup
- `feature/*` branches: New features and experiments
- `local_main_backup`: Development backup branch

## Dependencies

- **SwiftSoup**: HTML parsing and manipulation
- **Foundation**: Core iOS framework
- **SwiftUI**: User interface framework

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]
