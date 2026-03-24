import SwiftUI

struct DashboardView: View {
    @Environment(AuthenticationManager.self) private var auth
    @State private var repoService = RepositoryService()
    @State private var polling = PollingManager()
    @State private var searchText = ""
    @State private var filterLanguage = "All"
    @State private var showArchived = false
    @State private var selectedRepo: GitHubRepository?
    @State private var navigationPath = NavigationPath()

    private var filteredRepos: [GitHubRepository] {
        var repos = repoService.repositories
        if !showArchived { repos = repos.filter { !$0.archived } }
        if filterLanguage != "All" { repos = repos.filter { $0.language == filterLanguage } }
        if !searchText.isEmpty {
            repos = repos.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return repos
    }

    private var languages: [String] {
        let langs = Set(repoService.repositories.compactMap(\.language))
        return ["All"] + langs.sorted()
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search repos...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)

                    Picker("Language", selection: $filterLanguage) {
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 140)

                    Toggle("Archived", isOn: $showArchived)
                        .toggleStyle(.switch).controlSize(.small)

                    Spacer()

                    if repoService.isLoading {
                        ProgressView().controlSize(.small)
                    }

                    Button(action: { Task { await repoService.fetchRepositories() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh")

                    Text("\(filteredRepos.count) repos").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Content
                if repoService.isLoading && repoService.repositories.isEmpty {
                    LoadingStateView(message: "Fetching repositories...")
                } else if repoService.repositories.isEmpty {
                    EmptyStateView(title: "No Repositories", subtitle: "No repositories found.", systemImage: "folder")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 420), spacing: 12)], spacing: 12) {
                            ForEach(filteredRepos) { repo in
                                RepositoryCardView(repo: repo) {
                                    navigationPath.append(repo)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationDestination(for: GitHubRepository.self) { repo in
                RepoDetailView(repo: repo)
            }
        }
        .task {
            await repoService.fetchRepositories()
            polling.startPolling(id: "dashboard", interval: 120) {
                await repoService.fetchRepositories()
            }
        }
        .onDisappear { polling.stopAll() }
    }
}

struct RepositoryCardView: View {
    let repo: GitHubRepository
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AvatarView(url: repo.owner.avatarUrl, size: 20)
                    Text(repo.fullName).font(.headline).lineLimit(1)
                    Spacer()
                    if repo.isPrivate {
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.orange)
                    }
                    if repo.archived {
                        Text("Archived").font(.caption2)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                }

                if let desc = repo.description {
                    Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let lang = repo.language {
                        HStack(spacing: 4) {
                            Circle().fill(languageColor(lang)).frame(width: 8, height: 8)
                            Text(lang).font(.caption2)
                        }
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "star"); Text("\(repo.stargazersCount)")
                    }.font(.caption2).foregroundStyle(.secondary)
                    HStack(spacing: 3) {
                        Image(systemName: "tuningfork"); Text("\(repo.forksCount)")
                    }.font(.caption2).foregroundStyle(.secondary)
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.circle"); Text("\(repo.openIssuesCount)")
                    }.font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    if let pushed = repo.pushedAt {
                        RelativeTimeText(dateString: pushed)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(.background))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open in GitHub") {
                if let url = URL(string: repo.htmlUrl) { NSWorkspace.shared.open(url) }
            }
            Button("Copy Clone URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(repo.htmlUrl + ".git", forType: .string)
            }
        }
    }

    private func languageColor(_ lang: String) -> Color {
        switch lang.lowercased() {
        case "swift": return .orange; case "javascript", "typescript": return .yellow
        case "python": return .blue; case "rust": return Color(red: 0.87, green: 0.45, blue: 0.20)
        case "go": return .cyan; case "ruby": return .red; case "java": return Color(red: 0.69, green: 0.13, blue: 0.13)
        case "c++", "c": return Color(red: 0.0, green: 0.35, blue: 0.65)
        case "html": return .orange; case "css": return .purple; case "shell": return .green
        default: return .gray
        }
    }
}
