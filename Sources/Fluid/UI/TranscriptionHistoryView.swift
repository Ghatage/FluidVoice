import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct TranscriptionHistoryView: View {
    @ObservedObject private var historyStore = TranscriptionHistoryStore.shared
    @Environment(\.theme) private var theme

    @State private var searchQuery = ""
    @State private var showReportConfirmation = false
    @State private var selectedReportEntry: TranscriptionHistoryEntry?

    private var filteredEntries: [TranscriptionHistoryEntry] {
        self.historyStore.search(query: self.searchQuery)
    }

    private var selectedEntry: TranscriptionHistoryEntry? {
        if let id = self.historyStore.selectedEntryID,
           let selected = self.filteredEntries.first(where: { $0.id == id })
        {
            return selected
        }
        return self.filteredEntries.first
    }

    var body: some View {
        HStack(spacing: 0) {
            self.listColumn
                .frame(width: 340)

            Rectangle()
                .fill(self.theme.tide.line)
                .frame(width: 1)

            Group {
                if let entry = self.selectedEntry {
                    self.detailColumn(entry)
                } else {
                    self.noSelectionView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(self.theme.tide.bg)
        .foregroundStyle(self.theme.tide.text)
        .tint(self.theme.tide.accent)
        .onAppear(perform: self.reconcileSelection)
        .onChange(of: self.filteredEntries.map(\.id)) { _, _ in
            self.reconcileSelection()
        }
        .alert("Report Sent", isPresented: self.$showReportConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for helping improve FluidVoice dictation.")
        }
        .sheet(item: self.$selectedReportEntry) { entry in
            TranscriptionFeedbackReportSheet(entry: entry) {
                self.selectedReportEntry = nil
                self.showReportConfirmation = true
            }
            .environment(\.theme, self.theme)
        }
    }

    private var listColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("History")
                .font(TideOnboardingType.heading(size: 30))
                .tracking(-0.9)

            self.searchField

            if self.historyStore.isLoading {
                ProgressView("Loading history…")
                    .font(TideOnboardingType.body(size: 13))
                    .foregroundStyle(self.theme.tide.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else if let error = self.historyStore.persistenceError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .font(TideOnboardingType.body(size: 12))
                        .foregroundStyle(self.theme.tide.muted)
                    Button("Retry saving history") {
                        self.historyStore.retryPersistence()
                    }
                    .font(TideOnboardingType.heading(size: 12, weight: .bold))
                    .foregroundStyle(self.theme.tide.accent)
                    .buttonStyle(.plain)
                }
            }

            if self.filteredEntries.isEmpty {
                self.emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        ForEach(self.filteredEntries) { entry in
                            self.entryRow(entry)
                        }
                    }
                }
            }
        }
        .padding(.top, 22)
        .padding(.leading, 22)
        .padding(.trailing, 14)
        .padding(.bottom, 22)
        .background(self.theme.tide.bg)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(self.theme.tide.muted)

            TextField("Search transcriptions…", text: self.$searchQuery)
                .textFieldStyle(.plain)
                .font(TideOnboardingType.body(size: 14))
                .foregroundStyle(self.theme.tide.text)

            if !self.searchQuery.isEmpty {
                Button {
                    self.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(self.theme.tide.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(self.theme.tide.card, in: Capsule())
    }

    private func entryRow(_ entry: TranscriptionHistoryEntry) -> some View {
        let isSelected = self.selectedEntry?.id == entry.id

        return Button {
            self.historyStore.selectedEntryID = entry.id
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.appName.isEmpty ? "Unknown App" : entry.appName)
                        .font(TideOnboardingType.heading(size: 12, weight: .bold))
                        .lineLimit(1)

                    if entry.wasAIProcessed {
                        self.polishedTag(selected: isSelected, compact: true)
                    }

                    Spacer(minLength: 4)

                    Text(entry.relativeTimeString)
                        .font(TideOnboardingType.body(size: 11))
                        .foregroundStyle(self.theme.tide.text.opacity(0.7))
                        .lineLimit(1)
                }

                Text(self.finalText(for: entry))
                    .font(TideOnboardingType.body(size: 14))
                    .lineSpacing(3)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(self.theme.tide.text)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? self.theme.tide.accentSoft : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                self.copyToClipboard(self.finalText(for: entry))
            } label: {
                Label(entry.wasAIProcessed ? "Copy AI Text" : "Copy Text", systemImage: "doc.on.doc")
            }

            if entry.wasAIProcessed {
                Button {
                    self.copyToClipboard(entry.rawText)
                } label: {
                    Label("Copy Raw Text", systemImage: "doc.on.doc.fill")
                }

                Button {
                    self.copyToClipboard(self.combinedText(for: entry))
                } label: {
                    Label("Copy Both", systemImage: "doc.on.doc")
                }
            }

            if self.hasAudio(entry) {
                Divider()

                Button {
                    self.exportPair(entry)
                } label: {
                    Label("Export Pair...", systemImage: "square.and.arrow.up")
                }

                Button {
                    self.revealAudio(entry)
                } label: {
                    Label("Reveal Audio", systemImage: "waveform")
                }
            }

            Divider()

            Button {
                self.openFeedbackReport(for: entry)
            } label: {
                Label("Report Bad Result...", systemImage: "hand.thumbsup.slash")
            }

            Divider()

            Button(role: .destructive) {
                self.delete(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .help(entry.aiProcessingError ?? "")
    }

    private func detailColumn(_ entry: TranscriptionHistoryEntry) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(self.appName(for: entry)) · \(entry.fullDateString)")
                            .font(TideOnboardingType.heading(size: 12, weight: .bold))
                            .tracking(0.96)
                            .foregroundStyle(self.theme.tide.muted)
                            .textCase(.uppercase)

                        Text(self.finalText(for: entry))
                            .font(TideOnboardingType.heading(size: 22))
                            .tracking(-0.44)
                            .lineSpacing(3)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }

                    Spacer(minLength: 8)

                    Button {
                        self.copyToClipboard(self.finalText(for: entry))
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(TideOnboardingType.heading(size: 14, weight: .heavy))
                            .foregroundStyle(self.theme.tide.accentInk)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(self.theme.tide.accent, in: Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                self.finalTextSection(entry)

                if !entry.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.rawTextSection(entry)
                }

                self.metadataChips(entry)

                HStack {
                    Button("Report a bad result") {
                        self.openFeedbackReport(for: entry)
                    }
                    .font(TideOnboardingType.heading(size: 13, weight: .bold))
                    .foregroundStyle(self.theme.tide.muted)
                    .buttonStyle(.plain)

                    Spacer()

                    Button(role: .destructive) {
                        self.delete(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(TideOnboardingType.heading(size: 13, weight: .bold))
                            .foregroundStyle(self.theme.tide.accentDeep)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 22)
            .padding(.leading, 28)
            .padding(.trailing, 32)
            .padding(.bottom, 32)
        }
        .background(self.theme.tide.bg)
    }

    private func finalTextSection(_ entry: TranscriptionHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                self.sectionLabel("Final text")
                if entry.wasAIProcessed {
                    self.polishedTag(selected: false, compact: false)
                }
            }

            Text(self.finalText(for: entry))
                .font(TideOnboardingType.body(size: 16))
                .lineSpacing(8)
                .textSelection(.enabled)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(self.theme.tide.card)
                )
        }
    }

    private func rawTextSection(_ entry: TranscriptionHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            self.sectionLabel("What you said")

            Text(entry.rawText)
                .font(TideOnboardingType.body(size: 15))
                .foregroundStyle(self.theme.tide.muted)
                .lineSpacing(7.5)
                .textSelection(.enabled)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            self.theme.tide.line,
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                )
        }
    }

    private func metadataChips(_ entry: TranscriptionHistoryEntry) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 136), spacing: 8, alignment: .leading)],
            alignment: .leading,
            spacing: 8
        ) {
            self.metadataChip(key: "App", value: self.appName(for: entry))
            self.metadataChip(key: "Characters", value: "\(entry.characterCount)")
            self.metadataChip(key: "Model", value: self.modelText(for: entry))
            self.metadataChip(key: "Audio", value: self.audioMetadataText(for: entry))
        }
    }

    private func metadataChip(key: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .foregroundStyle(self.theme.tide.muted)
            Text(value)
                .font(TideOnboardingType.body(size: 13, weight: .bold))
                .foregroundStyle(self.theme.tide.text)
                .lineLimit(1)
        }
        .font(TideOnboardingType.body(size: 13))
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .background(self.theme.tide.card, in: Capsule())
        .help("\(key): \(value)")
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(TideOnboardingType.heading(size: 12, weight: .bold))
            .tracking(0.96)
            .foregroundStyle(self.theme.tide.muted)
    }

    private func polishedTag(selected: Bool, compact: Bool) -> some View {
        Text("Polished")
            .font(TideOnboardingType.heading(size: compact ? 10 : 11, weight: .bold))
            .foregroundStyle(selected ? self.theme.tide.accentInk : self.theme.tide.accent2Deep)
            .padding(.horizontal, compact ? 7 : 8)
            .padding(.vertical, compact ? 1 : 2)
            .background(selected ? self.theme.tide.accent : self.theme.tide.accent2Soft, in: Capsule())
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: self.searchQuery.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(self.theme.tide.muted)
            Text(self.searchQuery.isEmpty ? "No History Yet" : "No Results")
                .font(TideOnboardingType.heading(size: 14, weight: .bold))
                .foregroundStyle(self.theme.tide.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionView: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.quote")
                .font(.system(size: 36, weight: .medium))
            Text("Select a transcription")
                .font(TideOnboardingType.heading(size: 14, weight: .bold))
        }
        .foregroundStyle(self.theme.tide.muted)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reconcileSelection() {
        guard let current = self.historyStore.selectedEntryID,
              self.filteredEntries.contains(where: { $0.id == current })
        else {
            self.historyStore.selectedEntryID = self.filteredEntries.first?.id
            return
        }
    }

    private func finalText(for entry: TranscriptionHistoryEntry) -> String {
        entry.clipboardText ?? ""
    }

    private func appName(for entry: TranscriptionHistoryEntry) -> String {
        entry.appName.isEmpty ? "Unknown App" : entry.appName
    }

    private func modelText(for entry: TranscriptionHistoryEntry) -> String {
        let model = entry.processingModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !model.isEmpty { return model }
        return entry.wasAIProcessed ? "Unknown" : "Not polished"
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func openFeedbackReport(for entry: TranscriptionHistoryEntry) {
        self.selectedReportEntry = entry
    }

    private func combinedText(for entry: TranscriptionHistoryEntry) -> String {
        "\(entry.rawText)\n\n\(self.finalText(for: entry))"
    }

    private func delete(_ entry: TranscriptionHistoryEntry) {
        let nextEntry = self.filteredEntries.first(where: { $0.id != entry.id })
        self.historyStore.deleteEntry(id: entry.id)
        self.historyStore.selectedEntryID = nextEntry?.id
    }

    private func hasAudio(_ entry: TranscriptionHistoryEntry) -> Bool {
        DictationAudioHistoryStore.shared.audioFileExists(for: entry)
    }

    private func audioMetadataText(for entry: TranscriptionHistoryEntry) -> String {
        guard let audio = entry.audio, self.hasAudio(entry) else { return "Not saved" }
        let seconds = Double(audio.durationMilliseconds) / 1000.0
        let size = ByteCountFormatter.string(fromByteCount: Int64(audio.byteCount), countStyle: .file)
        return "\(String(format: "%.1f", seconds))s · \(size)"
    }

    private func revealAudio(_ entry: TranscriptionHistoryEntry) {
        guard let url = DictationAudioHistoryStore.shared.audioFileURL(for: entry),
              FileManager.default.fileExists(atPath: url.path)
        else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func exportPair(_ entry: TranscriptionHistoryEntry) {
        do {
            guard self.hasAudio(entry) else { throw DictationAudioHistoryError.audioMissing }
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.allowedContentTypes = [.zip]
            panel.nameFieldStringValue = DictationAudioHistoryStore.shared.suggestedPairExportFilename(for: entry)

            guard panel.runModal() == .OK, let url = panel.url else { return }
            try DictationAudioHistoryStore.shared.exportPair(entry: entry, to: url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Pair Export Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

private struct TranscriptionFeedbackReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var inputText: String
    @State private var outputText: String
    @State private var processingModel: String
    @State private var comment: String
    @State private var isSending = false
    @State private var errorMessage: String?

    let onSent: () -> Void

    init(entry: TranscriptionHistoryEntry, onSent: @escaping () -> Void) {
        _inputText = State(initialValue: entry.rawText)
        _outputText = State(initialValue: entry.processedText)
        _processingModel = State(initialValue: Self.reportModel(for: entry))
        _comment = State(initialValue: "")
        self.onSent = onSent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Share anonymous datapoint")
                    .font(TideOnboardingType.heading(size: 18, weight: .bold))
                Text("Help improve our model. Only the example shown below will be sent.")
                    .font(TideOnboardingType.body(size: 12))
                    .foregroundStyle(self.theme.tide.muted)
            }

            self.feedbackField(title: "Raw Text", text: self.$inputText, height: 88)
            self.feedbackField(title: "Processed Text", text: self.$outputText, height: 88)
            self.feedbackField(title: "Processing Model", text: self.$processingModel, height: 40)
            self.feedbackField(title: "Comment optional", text: self.$comment, height: 72)

            if let errorMessage {
                Text(errorMessage)
                    .font(TideOnboardingType.body(size: 12, weight: .medium))
                    .foregroundStyle(self.theme.tide.accentDeep)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    self.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(self.isSending)

                Button {
                    Task { await self.sendReport() }
                } label: {
                    HStack(spacing: 8) {
                        if self.isSending {
                            ProgressView()
                                .controlSize(.small)
                                .fixedSize()
                        }
                        Text(self.isSending ? "Sending..." : "Send Example")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(self.theme.tide.accent)
                .disabled(self.isSendDisabled)
            }
        }
        .padding(20)
        .frame(width: 520)
        .foregroundStyle(self.theme.tide.text)
        .background(self.theme.tide.bg)
    }

    private var isSendDisabled: Bool {
        self.isSending ||
            (self.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                self.outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
            self.processingModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendReport() async {
        let payload = TranscriptionFeedbackReporter.Payload(
            rawText: self.inputText.trimmingCharacters(in: .whitespacesAndNewlines),
            processedText: self.outputText.trimmingCharacters(in: .whitespacesAndNewlines),
            processingModel: self.processingModel.trimmingCharacters(in: .whitespacesAndNewlines),
            comments: self.comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        self.isSending = true
        self.errorMessage = nil
        do {
            try await TranscriptionFeedbackReporter.submit(payload)
            self.isSending = false
            self.onSent()
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSending = false
        }
    }

    private func feedbackField(title: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(TideOnboardingType.heading(size: 11, weight: .bold))
                .foregroundStyle(self.theme.tide.muted)

            TextEditor(text: text)
                .font(TideOnboardingType.body(size: 13))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: height)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(self.theme.tide.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(self.theme.tide.line, lineWidth: 1)
                        )
                )
        }
    }

    private static func reportModel(for entry: TranscriptionHistoryEntry) -> String {
        let model = entry.processingModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return model.isEmpty ? "unknown" : model
    }
}

#Preview {
    TranscriptionHistoryView()
        .frame(width: 800, height: 600)
        .environment(\.theme, AppTheme.dark)
}
