import SwiftUI

struct DashboardView: View {
    @Environment(AuthenticationManager.self) private var auth
    @State private var repoService = RepositoryService()

    var body: some View {
        Group {
            if repoService.isLoading && repoService.repositories.isEmpty {
                LoadingStateView(message: "Fetching repositories...")
            } else if let error = repoService.error, repoService.repositories.isEmpty {
                ErrorStateView(message: error) {
                    Task { await repoService.fetchRepositories() }
                }
            } else if repoService.repositories.isEmpty {
                EmptyStateView(title: "No Repositories", subtitle: "No repositories found.", systemImage: "folder")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)], spacing: 16) {
                        ForEach(repoService.repositories) { repo in
                            RepositoryCardView(repo: repo)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Dashboard (\(repoService.repositories.count) repos)")
        .task { await repoService.fetchRepositories() }
        .refreshable { await repoService.fetchRepositories() }
    }
}

struct RepositoryCardView: View {
    let repo: GitHubRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AvatarView(url: repo.owner.avatarUrl, size: 20)
                Text(repo.fullName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if repo.isPrivate {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let desc = repo.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                if let lang = repo.language {
                    HStack(spacing: 4) {
                        Circle().fill(.blue).frame(width: 8, height: 8)
                        Text(lang).font(.caption2)
                    }
                }

                Label("\(repo.stargazersCount)", systemImage: "star")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label("\(repo.forksCount)", systemImage: "tuningfork")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label("\(repo.openIssuesCount)", systemImage: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if let pushed = repo.pushedAt {
                    RelativeTimeText(dateString: pushed)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(.background))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
        .contextMenu {
            Button("Open in GitHub") {
                if let url = URL(string: repo.htmlUrl) { NSWorkspace.shared.open(url) }
            }
        }
    }
}
