import Combine
import Foundation
import SwiftUI

struct TideHomeView: View {
    @ObservedObject private var historyStore = TranscriptionHistoryStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.theme) private var theme

    @StateObject private var intelligence = TideHomeIntelligenceCoordinator()
    @State private var intelligenceCardDismissed = false

    let shortcutDisplay: String
    let onTryHere: () -> Void
    let onSeeAllHistory: () -> Void

    private var recentEntries: ArraySlice<TranscriptionHistoryEntry> {
        self.historyStore.entries.prefix(4)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            self.theme.tide.bg

            Circle()
                .fill(self.theme.tide.accent2Soft)
                .opacity(0.7)
                .frame(width: 380, height: 380)
                .offset(x: 120, y: -160)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    self.header
                    self.stats

                    if self.intelligence.canOffer,
                       !self.intelligence.isInstalled,
                       !self.intelligenceCardDismissed
                    {
                        self.intelligenceCard
                    }

                    self.recent
                }
                .padding(.top, 26)
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
            }
        }
        .clipped()
        .foregroundStyle(self.theme.tide.text)
        .tint(self.theme.tide.accent)
        .onAppear {
            self.intelligence.refreshInstalledState()
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(TideHomeGreeting.text())
                    .font(TideOnboardingType.heading(size: 38))
                    .tracking(-1.14)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("Hold")
                    Text(self.normalizedShortcutDisplay)
                        .font(TideOnboardingType.mono(size: 13))
                        .foregroundStyle(self.theme.tide.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(self.theme.tide.card)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(self.theme.tide.line)
                                        .frame(height: 2)
                                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                }
                        )
                    Text("in any app to dictate.")
                }
                .font(TideOnboardingType.body(size: 16))
                .foregroundStyle(self.theme.tide.muted)
                .lineLimit(1)
            }

            Spacer(minLength: 12)

            Button(action: self.onTryHere) {
                HStack(spacing: 8) {
                    Image(systemName: "mic")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(self.theme.tide.accent)
                    Text("Try it here")
                        .font(TideOnboardingType.heading(size: 13, weight: .bold))
                }
                .foregroundStyle(self.theme.tide.text)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(self.theme.tide.card, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Open the Getting Started playground")
        }
    }

    private var normalizedShortcutDisplay: String {
        let display = self.shortcutDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        return display.isEmpty ? "your shortcut" : display
    }

    private var stats: some View {
        HStack(spacing: 14) {
            TideHomeStatCard(
                label: "Today",
                value: self.formattedNumber(self.historyStore.todaySummary.words),
                subline: "words dictated",
                theme: self.theme
            )
            TideHomeStatCard(
                label: "Saved",
                value: self.historyStore.formattedTimeSaved(typingWPM: self.settings.userTypingWPM),
                subline: "vs. typing at \(self.settings.userTypingWPM) wpm",
                theme: self.theme
            )
            TideHomeStatCard(
                label: "Streak",
                value: self.streakText,
                subline: "keep it going",
                theme: self.theme
            )
        }
    }

    private var streakText: String {
        let streak = self.historyStore.currentStreak
        return "\(streak) day\(streak == 1 ? "" : "s")"
    }

    private var intelligenceCard: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NOW THAT IT WORKS")
                    .font(TideOnboardingType.heading(size: 12, weight: .bold))
                    .tracking(0.96)
                    .foregroundStyle(self.theme.tide.accentDeep)

                Text("Want it to tidy up what you say?")
                    .font(TideOnboardingType.heading(size: 22))
                    .tracking(-0.44)

                Text("Fluid Intelligence fixes punctuation, capitalisation and “um”s on your Mac. No account, no cloud. One \(self.intelligence.downloadSizeText) download.")
                    .font(TideOnboardingType.body(size: 14))
                    .foregroundStyle(self.theme.tide.text.opacity(0.85))
                    .lineSpacing(7)
                    .frame(maxWidth: 520, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button {
                    self.intelligence.prepare(settings: self.settings)
                } label: {
                    HStack(spacing: 8) {
                        if self.intelligence.isPreparing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(self.theme.tide.accentInk)
                        }
                        Text("Turn it on")
                            .font(TideOnboardingType.heading(size: 15))
                    }
                    .foregroundStyle(self.theme.tide.accentInk)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(self.theme.tide.accent, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(self.intelligence.isPreparing)
                .help(self.intelligence.statusText)

                Button("Not now") {
                    self.intelligenceCardDismissed = true
                }
                .font(TideOnboardingType.heading(size: 13, weight: .bold))
                .foregroundStyle(self.theme.tide.accentDeep)
                .buttonStyle(.plain)
            }
            .frame(minWidth: 124)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 26)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(self.theme.tide.accentSoft)
        )
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(TideOnboardingType.heading(size: 18))
                    .tracking(-0.36)

                Spacer()

                Button("See all history", action: self.onSeeAllHistory)
                    .font(TideOnboardingType.heading(size: 13, weight: .bold))
                    .foregroundStyle(self.theme.tide.accent)
                    .buttonStyle(.plain)
            }

            VStack(spacing: 6) {
                ForEach(self.recentEntries) { entry in
                    Button {
                        self.historyStore.selectedEntryID = entry.id
                        self.onSeeAllHistory()
                    } label: {
                        HStack(spacing: 14) {
                            Text(entry.appName.isEmpty ? "Unknown App" : entry.appName)
                                .font(TideOnboardingType.heading(size: 13, weight: .bold))
                                .foregroundStyle(self.theme.tide.muted)
                                .lineLimit(1)
                                .frame(width: 110, alignment: .leading)

                            Text(entry.clipboardText ?? "")
                                .font(TideOnboardingType.body(size: 14))
                                .foregroundStyle(self.theme.tide.text)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(entry.relativeTimeString)
                                .font(TideOnboardingType.body(size: 12))
                                .foregroundStyle(self.theme.tide.muted)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(self.theme.tide.card)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func formattedNumber(_ number: Int) -> String {
        number.formatted(.number)
    }
}

private struct TideHomeStatCard: View {
    let label: String
    let value: String
    let subline: String
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.label.uppercased())
                .font(TideOnboardingType.heading(size: 12, weight: .bold))
                .tracking(0.96)
                .foregroundStyle(self.theme.tide.muted)

            Text(self.value)
                .font(TideOnboardingType.heading(size: 34))
                .tracking(-1.02)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(self.subline)
                .font(TideOnboardingType.body(size: 13))
                .foregroundStyle(self.theme.tide.muted)
                .lineLimit(1)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(self.theme.tide.card)
        )
    }
}

enum TideHomeGreeting {
    static func text(at date: Date = Date(), calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 0..<12:
            return "Good morning."
        case 12..<18:
            return "Good afternoon."
        default:
            return "Good evening."
        }
    }
}

@MainActor
private final class TideHomeIntelligenceCoordinator: ObservableObject {
    @Published private(set) var isInstalled: Bool
    @Published private(set) var isPreparing = false
    @Published private(set) var progress: PrivateAIModelDownloadProgress?
    @Published private(set) var errorMessage: String?

    private let model: PrivateAIRegisteredModel
    private var preparationTask: Task<Void, Never>?

    init() {
        let model = PrivateAIModelRegistry.defaultModel
        self.model = model
        self.isInstalled = PrivateAIIntegrationService.isModelInstalled(model)
    }

    var canOffer: Bool {
        PrivateAIProviderFeature.shared.isAvailable
            && !self.model.id.isEmpty
            && self.model.artifact.byteCount.map { $0 > 0 } == true
            && (self.model.canDownload || self.isInstalled)
    }

    var downloadSizeText: String {
        guard let byteCount = self.model.artifact.byteCount, byteCount > 0 else { return "model" }
        return ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }

    var statusText: String {
        if let errorMessage {
            return errorMessage
        }
        return PrivateAIModelDownloadProgressText.statusText(for: self.progress)
    }

    func refreshInstalledState() {
        self.isInstalled = PrivateAIIntegrationService.isModelInstalled(self.model)
    }

    func prepare(settings: SettingsStore) {
        guard self.canOffer, !self.isInstalled, self.preparationTask == nil else { return }

        self.isPreparing = true
        self.errorMessage = nil
        self.progress = PrivateAIModelDownloadProgress(initialExpectedBytes: self.model.artifact.byteCount)

        self.preparationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let coordinator = self
                _ = try await PrivateAIIntegrationService.prepareModel(self.model) { progress in
                    await coordinator.receive(progress)
                }
                self.persistSelection(settings: settings)
                self.isInstalled = true
            } catch is CancellationError {
                self.errorMessage = "Fluid Intelligence setup was cancelled."
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isPreparing = false
            self.preparationTask = nil
        }
    }

    private func receive(_ progress: PrivateAIModelDownloadProgress) {
        self.progress = progress.withFallbackExpectedBytes(self.model.artifact.byteCount)
    }

    private func persistSelection(settings: SettingsStore) {
        let providerID = PrivateAIProviderFeature.shared.providerID
        let providerKey = DictationAIPostProcessingGate.providerKey(for: providerID)
        var selectedModels = settings.selectedModelByProvider
        selectedModels[providerKey] = self.model.id
        settings.selectedModelByProvider = selectedModels
        settings.setDictationPromptSelection(.privateAI, for: .primary)
        UserDefaults.standard.set(self.model.id, forKey: PrivateAIIntegrationService.selectedModelDefaultsKey)
    }
}
