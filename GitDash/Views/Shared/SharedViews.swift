import SwiftUI

struct CIStatusBadge: View {
    let status: String?
    let conclusion: String?

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .help(statusText)
    }

    private var statusColor: Color {
        if let conclusion {
            switch conclusion {
            case "success": return .green
            case "failure": return .red
            case "cancelled": return .gray
            default: return .yellow
            }
        }
        switch status ?? "" {
        case "completed": return .green
        case "in_progress": return .orange
        case "queued": return .yellow
        default: return .gray
        }
    }

    private var statusText: String {
        conclusion ?? status ?? "unknown"
    }
}

struct LabelBadge: View {
    let name: String
    let colorHex: String

    var body: some View {
        Text(name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: colorHex).opacity(0.2), in: Capsule())
            .foregroundStyle(Color(hex: colorHex))
    }
}

struct AvatarView: View {
    let url: String
    var size: CGFloat = 24

    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle().fill(.quaternary)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct RelativeTimeText: View {
    let dateString: String

    var body: some View {
        Text(formatted)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var formatted: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

struct LoadingStateView: View {
    var message: String = "Loading..."
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(message).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let onRetry {
                Button("Retry", action: onRetry).buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 40)).foregroundStyle(.quaternary)
            Text(title).font(.title3.weight(.medium)).foregroundStyle(.secondary)
            Text(subtitle).font(.body).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
