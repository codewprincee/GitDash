import SwiftUI

struct PRDiffView: View {
    let diff: String

    @State private var expandedFiles: Set<String> = []
    @AppStorage("diffViewMode") private var viewMode = "unified"

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(parsedFiles, id: \.filename) { file in
                    fileDiffView(file)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func fileDiffView(_ file: DiffFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button(action: { toggleFile(file.filename) }) {
                HStack(spacing: 8) {
                    Image(systemName: expandedFiles.contains(file.filename) ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .frame(width: 12)

                    Image(systemName: file.statusIcon)
                        .font(.caption)
                        .foregroundStyle(file.statusColor)

                    Text(file.filename)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    Text("+\(file.additions)")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                    Text("-\(file.deletions)")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Diff content
            if expandedFiles.contains(file.filename) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(file.lines.enumerated()), id: \.offset) { _, line in
                        diffLineView(line)
                    }
                }
            }

            Divider()
        }
    }

    private func diffLineView(_ line: DiffLine) -> some View {
        HStack(spacing: 0) {
            // Line numbers
            Text(line.oldNumber ?? "")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)
                .padding(.trailing, 4)

            Text(line.newNumber ?? "")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)
                .padding(.trailing, 8)

            // Content
            Text(line.content)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(line.backgroundColor)
    }

    private func toggleFile(_ filename: String) {
        if expandedFiles.contains(filename) {
            expandedFiles.remove(filename)
        } else {
            expandedFiles.insert(filename)
        }
    }

    // MARK: - Parsing

    private var parsedFiles: [DiffFile] {
        var files: [DiffFile] = []
        var currentFile: DiffFile?
        var oldLineNum = 0
        var newLineNum = 0

        for rawLine in diff.components(separatedBy: "\n") {
            if rawLine.hasPrefix("diff --git") {
                if let file = currentFile { files.append(file) }
                let filename = extractFilename(from: rawLine)
                currentFile = DiffFile(filename: filename)
            } else if rawLine.hasPrefix("@@") {
                // Parse hunk header: @@ -old,count +new,count @@
                let nums = parseHunkHeader(rawLine)
                oldLineNum = nums.oldStart
                newLineNum = nums.newStart
                currentFile?.lines.append(DiffLine(type: .hunk, content: rawLine, oldNumber: nil, newNumber: nil))
            } else if rawLine.hasPrefix("+") && !rawLine.hasPrefix("+++") {
                currentFile?.lines.append(DiffLine(type: .addition, content: String(rawLine.dropFirst()), oldNumber: nil, newNumber: "\(newLineNum)"))
                currentFile?.additions += 1
                newLineNum += 1
            } else if rawLine.hasPrefix("-") && !rawLine.hasPrefix("---") {
                currentFile?.lines.append(DiffLine(type: .deletion, content: String(rawLine.dropFirst()), oldNumber: "\(oldLineNum)", newNumber: nil))
                currentFile?.deletions += 1
                oldLineNum += 1
            } else if rawLine.hasPrefix("\\") {
                // "\ No newline at end of file" — skip
            } else if currentFile != nil && !rawLine.hasPrefix("index ") && !rawLine.hasPrefix("---") && !rawLine.hasPrefix("+++") && !rawLine.hasPrefix("new ") && !rawLine.hasPrefix("old ") && !rawLine.hasPrefix("deleted ") && !rawLine.hasPrefix("similarity") && !rawLine.hasPrefix("rename") {
                let content = rawLine.hasPrefix(" ") ? String(rawLine.dropFirst()) : rawLine
                currentFile?.lines.append(DiffLine(type: .context, content: content, oldNumber: "\(oldLineNum)", newNumber: "\(newLineNum)"))
                oldLineNum += 1
                newLineNum += 1
            }
        }
        if let file = currentFile { files.append(file) }

        // Auto-expand first 5 files
        for file in files.prefix(5) {
            expandedFiles.insert(file.filename)
        }

        return files
    }

    private func extractFilename(from line: String) -> String {
        // "diff --git a/path/file b/path/file"
        let parts = line.components(separatedBy: " b/")
        return parts.last ?? line
    }

    private func parseHunkHeader(_ line: String) -> (oldStart: Int, newStart: Int) {
        // @@ -1,5 +1,7 @@
        let pattern = "@@\\s*-([0-9]+)"
        let newPattern = "\\+([0-9]+)"
        let oldStart = line.range(of: pattern, options: .regularExpression).flatMap {
            Int(line[$0].dropFirst(4))
        } ?? 1
        let newStart = line.range(of: newPattern, options: .regularExpression).flatMap {
            Int(line[$0].dropFirst())
        } ?? 1
        return (oldStart, newStart)
    }
}

// MARK: - Models

struct DiffFile {
    let filename: String
    var lines: [DiffLine] = []
    var additions: Int = 0
    var deletions: Int = 0

    var statusIcon: String {
        if additions > 0 && deletions == 0 { return "plus.circle.fill" }
        if additions == 0 && deletions > 0 { return "minus.circle.fill" }
        return "pencil.circle.fill"
    }

    var statusColor: Color {
        if additions > 0 && deletions == 0 { return .green }
        if additions == 0 && deletions > 0 { return .red }
        return .orange
    }
}

struct DiffLine {
    enum LineType { case context, addition, deletion, hunk }

    let type: LineType
    let content: String
    let oldNumber: String?
    let newNumber: String?

    var backgroundColor: Color {
        switch type {
        case .addition: return Color.green.opacity(0.12)
        case .deletion: return Color.red.opacity(0.12)
        case .hunk: return Color.blue.opacity(0.06)
        case .context: return .clear
        }
    }
}
