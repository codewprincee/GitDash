# GitDash

A native macOS GitHub dashboard — all your repos, PRs, CI, issues, and notifications in one window.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Dashboard** — All your repos at a glance with stars, forks, language, and last push time
- **Pull Requests** — PRs you created + PRs requesting your review, across all repos
- **Actions / CI** — Live workflow runs, status, re-run failed jobs
- **Issues** — Issues assigned to you across all repos
- **Notifications** — All GitHub notifications with filters (PRs, Issues, unread)
- **Command Palette** — `⌘K` to navigate anywhere instantly
- **GitHub OAuth** — Secure Device Flow login, token stored in macOS Keychain

## Screenshots

<!-- Add screenshots here -->

## Setup

### 1. Create a GitHub OAuth App

1. Go to [GitHub Settings → Developer Settings → OAuth Apps](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Set:
   - Application name: `GitDash`
   - Homepage URL: `https://github.com/codewprincee/GitDash`
   - Authorization callback URL: `https://github.com/login/device` (not used, but required)
4. Click **Register application**
5. Copy the **Client ID**

### 2. Configure

Edit `GitDash/App/Constants.swift` and replace the `clientID` with your OAuth App Client ID:

```swift
static var clientID: String {
    ProcessInfo.processInfo.environment["GITDASH_CLIENT_ID"] ?? "YOUR_CLIENT_ID_HERE"
}
```

Or set the environment variable:
```bash
export GITDASH_CLIENT_ID=your_client_id
```

### 3. Build & Run

```bash
git clone https://github.com/codewprincee/GitDash.git
cd GitDash
open GitDash.xcodeproj
# Hit ⌘R in Xcode
```

## Architecture

```
GitDash/
├── App/          # Entry point, global state, constants
├── Auth/         # GitHub OAuth Device Flow + Keychain
├── Networking/   # GitHub REST + GraphQL API client
├── Models/API/   # Codable models for GitHub API responses
├── Services/     # Business logic (repos, PRs, actions, notifications)
├── Views/        # SwiftUI views organized by feature
│   ├── Dashboard/
│   ├── PullRequests/
│   ├── Actions/
│   ├── Issues/
│   ├── Notifications/
│   ├── CommandPalette/
│   └── Settings/
└── Utilities/    # Extensions and helpers
```

**Stack:** Swift · SwiftUI · async/await · GitHub REST API v3

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘K` | Command Palette |
| `⌘1` | Dashboard |
| `⌘2` | Pull Requests |
| `⌘3` | Actions |
| `⌘4` | Issues |
| `⌘5` | Notifications |

## Contributing

PRs welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT — see [LICENSE](LICENSE)
