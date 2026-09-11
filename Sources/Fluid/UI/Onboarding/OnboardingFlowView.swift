import AVFoundation
import SwiftUI

struct OnboardingFlowView: View {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case microphone = 1
        case accessibility = 2
        case tryout = 3

        var analyticsStep: AnalyticsOnboardingStep {
            switch self {
            case .welcome: .welcome
            case .microphone: .microphone
            case .accessibility: .accessibility
            case .tryout: .playground
            }
        }

        var title: String {
            switch self {
            case .welcome: "Fast. Accurate. Private."
            case .microphone: "Say hello."
            case .accessibility: "Let it type for you."
            case .tryout: "Try it."
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: "Local dictation that keeps up with you."
            case .microphone: "Allow FluidVoice to hear you."
            case .accessibility: "Let FluidVoice type into other apps."
            case .tryout: "Hold your shortcut and say anything."
            }
        }

        var progressValue: Double {
            Double(self.rawValue + 1) / Double(Self.allCases.count)
        }
    }

    @EnvironmentObject private var appServices: AppServices
    @ObservedObject private var settings = SettingsStore.shared
    @StateObject private var downloads = TideOnboardingDownloadCoordinator()

    @Binding var currentStep: Int
    let accessibilityEnabled: Bool
    let finishOnboarding: () -> Void
    let finishOnboardingInBackground: () -> Void
    let startTryout: () -> Void
    let stopTryout: () async -> Void
    let openAccessibilitySettings: () -> Void
    let theme: AppTheme

    @State private var isVisible = false

    private var asr: ASRService {
        self.appServices.asr
    }

    private var step: Step {
        Step(rawValue: self.currentStep) ?? .tryout
    }

    private var recommendedOnboardingRoute: VoiceEngineLanguageRoute? {
        let storedRoutes = VoiceEngineLanguageCatalog.routes(
            forLanguageID: self.settings.onboardingSelectedLanguageID
        )
        return storedRoutes.first(where: self.isRouteSelectedInSettings)
            ?? storedRoutes.first
            ?? VoiceEngineLanguageCatalog.allLanguages().lazy
            .flatMap { VoiceEngineLanguageCatalog.routes(for: $0) }
            .first
    }

    private var recommendedOnboardingModel: SettingsStore.SpeechModel {
        self.recommendedOnboardingRoute?.model ?? .defaultModel
    }

    private var downloadSizeText: String {
        self.recommendedOnboardingModel.downloadSize
            .replacingOccurrences(of: "~", with: "")
    }

    private var showsDownloadBar: Bool {
        self.step != .welcome
            && self.settings.hasStartedModelDownload
            && !self.downloads.isFinished
    }

    private var canContinue: Bool {
        switch self.step {
        case .welcome:
            true
        case .microphone:
            self.asr.micStatus == .authorized
        case .accessibility:
            self.accessibilityEnabled || self.settings.textInsertionMode == .reliablePaste
        case .tryout:
            self.asr.isAsrReady && self.settings.onboardingPlaygroundValidated
        }
    }

    var body: some View {
        ZStack {
            self.theme.tide.bg.ignoresSafeArea()

            TideOnboardingWindow(
                stepIndex: self.step.rawValue,
                stepCount: Step.allCases.count,
                downloadProgress: self.showsDownloadBar ? self.downloads.displayedProgress : nil,
                isSpeechLoading: self.asr.isLoadingModel && !self.asr.isAsrReady,
                theme: self.theme,
                onSelectStep: self.selectPreviousStep
            ) {
                self.stepContent
            }
        }
        .onAppear(perform: self.onAppear)
        .onDisappear { self.isVisible = false }
        .onChange(of: self.currentStep) { _, _ in
            self.recordStepViewed()
            self.advancePastSatisfiedPermissionIfNeeded()
        }
        .onChange(of: self.asr.micStatus) { _, status in
            guard self.isVisible, self.step == .microphone, status == .authorized else { return }
            self.advance(to: .accessibility)
        }
        .onChange(of: self.accessibilityEnabled) { _, isEnabled in
            guard self.isVisible, self.step == .accessibility, isEnabled else { return }
            self.advance(to: .tryout)
        }
        .onChange(of: self.asr.downloadProgress) { _, _ in
            self.downloads.syncSpeechState(from: self.asr)
        }
        .onChange(of: self.asr.isLoadingModel) { _, _ in
            self.downloads.syncSpeechState(from: self.asr)
        }
        .onChange(of: self.asr.isAsrReady) { _, _ in
            self.downloads.syncSpeechState(from: self.asr)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch self.step {
        case .welcome:
            TideWelcomeStepView(
                downloadSize: self.downloadSizeText,
                theme: self.theme,
                onStartDownload: self.startDownloads
            )
        case .microphone:
            TideMicrophoneStepView(
                theme: self.theme,
                onAllowMicrophone: self.requestMicrophoneAccess
            )
        case .accessibility:
            TideAccessibilityStepView(
                theme: self.theme,
                onOpenSystemSettings: self.openAccessibilitySettings,
                onSkip: self.skipAccessibility
            )
        case .tryout:
            TideTryoutStepView(
                shortcutDisplay: self.onboardingShortcutDisplay,
                finalText: self.asr.finalText,
                isListening: self.asr.isRunning,
                isReady: self.asr.isAsrReady,
                isValidated: self.settings.onboardingPlaygroundValidated,
                isDownloadInProgress: self.settings.hasStartedModelDownload && !self.downloads.isFinished,
                theme: self.theme,
                onTry: self.handleTryoutAction,
                onDone: self.completeTryout,
                onFinishInBackground: self.completeInBackground
            )
        }
    }

    private var onboardingShortcutDisplay: String {
        let display = self.settings.primaryDictationShortcutDisplayString
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return display.isEmpty ? "your shortcut" : display
    }

    private func onAppear() {
        self.isVisible = true
        self.settings.onboardingAISkipped = true

        if self.currentStep > Step.welcome.rawValue {
            self.settings.hasStartedModelDownload = true
        }

        if self.settings.hasStartedModelDownload {
            if self.currentStep == Step.welcome.rawValue {
                self.currentStep = Step.microphone.rawValue
            }
            self.startModelPreparationIfPossible()
        }

        let origin = self.settings.analyticsOnboardingOrigin
        AnalyticsService.shared.recordOnboardingStarted(origin: origin)
        self.recordStepViewed()

        Task { @MainActor in
            await AudioStartupGate.shared.scheduleOpenAfterInitialUISettled()
            await AudioStartupGate.shared.waitUntilOpen()
            guard self.isVisible else { return }
            self.asr.micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            await self.asr.checkIfModelsExistAsync()
            self.downloads.syncSpeechState(from: self.asr)
            self.advancePastSatisfiedPermissionIfNeeded()
        }
    }

    private func startDownloads() {
        guard self.canContinue else { return }
        self.settings.hasStartedModelDownload = true
        self.settings.onboardingAISkipped = true
        self.startModelPreparationIfPossible()
        self.advance(to: .microphone)
    }

    private func startModelPreparationIfPossible() {
        guard let route = self.recommendedOnboardingRoute else {
            self.asr.errorTitle = "Voice Model Setup Failed"
            self.asr.errorMessage = "No compatible voice model is available for this Mac."
            self.asr.showError = true
            return
        }
        self.prepareOnboardingRoute(route)
    }

    private func prepareOnboardingRoute(_ route: VoiceEngineLanguageRoute) {
        let wasSelected = self.isRouteSelectedInSettings(route)
        VoiceEngineLanguageCatalog.apply(route, to: self.settings)
        if !wasSelected {
            self.settings.onboardingPlaygroundValidated = false
            self.settings.onboardingPlaygroundSkipped = false
            self.asr.finalText = ""
            self.asr.resetTranscriptionProvider()
        }
        self.downloads.start(route: route, asr: self.asr, settings: self.settings)
    }

    private func requestMicrophoneAccess() {
        switch self.asr.micStatus {
        case .notDetermined:
            self.asr.requestMicAccess()
        case .authorized:
            self.advance(to: .accessibility)
        case .denied, .restricted:
            self.asr.openSystemSettingsForMic()
        @unknown default:
            self.asr.openSystemSettingsForMic()
        }
    }

    private func skipAccessibility() {
        self.settings.textInsertionMode = .reliablePaste
        self.advance(to: .tryout, outcome: .skipped)
    }

    private func handleTryoutAction() {
        guard self.asr.isAsrReady else { return }
        if self.asr.isRunning {
            Task { await self.stopTryout() }
        } else if !self.asr.isStarting {
            self.asr.finalText = ""
            self.settings.onboardingPlaygroundValidated = false
            self.settings.onboardingPlaygroundSkipped = false
            AnalyticsService.shared.recordOnboardingTryoutAttemptStarted(startMethod: .button)
            self.startTryout()
        }
    }

    private func completeTryout() {
        guard self.canContinue else { return }
        let origin = self.settings.analyticsOnboardingOrigin
        self.finishOnboarding()
        self.completeCurrentStep(
            outcome: .completed,
            origin: origin,
            completesFlow: self.settings.onboardingCompleted
        )
    }

    private func completeInBackground() {
        let origin = self.settings.analyticsOnboardingOrigin
        AnalyticsService.shared.skipOnboardingTryout(origin: origin)
        self.settings.onboardingPlaygroundSkipped = true
        self.finishOnboardingInBackground()
        self.completeCurrentStep(
            outcome: .skipped,
            origin: origin,
            completesFlow: self.settings.onboardingCompleted
        )
    }

    private func selectPreviousStep(_ index: Int) {
        guard index < self.step.rawValue, Step(rawValue: index) != nil else { return }
        self.currentStep = index
    }

    private func advancePastSatisfiedPermissionIfNeeded() {
        if self.step == .microphone, self.asr.micStatus == .authorized {
            DispatchQueue.main.async { self.advance(to: .accessibility) }
        } else if self.step == .accessibility, self.accessibilityEnabled {
            DispatchQueue.main.async { self.advance(to: .tryout) }
        }
    }

    private func advance(
        to nextStep: Step,
        outcome: AnalyticsOnboardingOutcome = .continued
    ) {
        guard nextStep.rawValue > self.step.rawValue else { return }
        self.completeCurrentStep(outcome: outcome)
        self.currentStep = nextStep.rawValue
    }

    private func recordStepViewed() {
        AnalyticsService.shared.recordOnboardingStepViewed(
            self.step.analyticsStep,
            origin: self.settings.analyticsOnboardingOrigin
        )
    }

    private func completeCurrentStep(
        outcome: AnalyticsOnboardingOutcome,
        origin: AnalyticsOnboardingOrigin? = nil,
        completesFlow: Bool = false
    ) {
        AnalyticsService.shared.recordOnboardingStepCompleted(
            self.step.analyticsStep,
            outcome: outcome,
            origin: origin ?? self.settings.analyticsOnboardingOrigin,
            completesFlow: completesFlow
        )
    }

    private func isRouteSelectedInSettings(_ route: VoiceEngineLanguageRoute) -> Bool {
        guard route.model == self.settings.selectedSpeechModel else { return false }

        switch route.binding {
        case .automatic:
            return self.settings.onboardingSelectedLanguageID == route.language.id
        case let .whisper(languageCode):
            return self.settings.selectedWhisperLanguageCode == languageCode
        case let .appleSpeech(localeIdentifier):
            return self.settings.selectedAppleSpeechLocaleIdentifier == localeIdentifier
        case let .cohere(language):
            return self.settings.selectedCohereLanguage == language
        case let .nemotron(language):
            return self.settings.selectedNemotronLanguage == language
        }
    }
}
