import Combine
import Foundation

@MainActor
final class TideOnboardingDownloadCoordinator: ObservableObject {
    @Published private(set) var displayedProgress: Double = 0
    @Published private(set) var speechFinished = false
    @Published private(set) var cleanupFinished = true
    @Published private(set) var cleanupLegIncluded = false

    private var speechProgress: Double = 0
    private var cleanupProgress: Double = 1
    private var speechExpectedBytes: Int64?
    private var cleanupExpectedBytes: Int64?
    private var preparationTask: Task<Void, Never>?

    var isFinished: Bool {
        self.speechFinished && self.cleanupFinished
    }

    func start(
        route: VoiceEngineLanguageRoute,
        asr: ASRService,
        settings: SettingsStore
    ) {
        guard self.preparationTask == nil else { return }

        let cleanupModel = PrivateAIModelRegistry.defaultModel
        let cleanupAvailable = PrivateAIProviderFeature.shared.isAvailable
            && !cleanupModel.id.isEmpty
            && (cleanupModel.canDownload || PrivateAIIntegrationService.isModelInstalled(cleanupModel))

        self.speechExpectedBytes = route.model.expectedDownloadBytes > 0
            ? route.model.expectedDownloadBytes
            : nil
        self.cleanupLegIncluded = cleanupAvailable
        self.cleanupExpectedBytes = cleanupAvailable ? cleanupModel.artifact.byteCount : nil

        let speechAlreadyDownloaded = route.model.isInstalled
        self.speechProgress = (asr.isAsrReady || speechAlreadyDownloaded) ? 1 : 0
        self.speechFinished = asr.isAsrReady

        if cleanupAvailable {
            let installed = PrivateAIIntegrationService.isModelInstalled(cleanupModel)
            self.cleanupProgress = installed ? 1 : 0
            self.cleanupFinished = installed
            if installed {
                self.persistCleanupModelSelection(cleanupModel, settings: settings)
            }
        } else {
            self.cleanupProgress = 1
            self.cleanupFinished = true
        }
        self.updateDisplayedProgress()

        self.preparationTask = Task { @MainActor in
            async let speechLeg: Void = self.prepareSpeechModel(asr: asr)
            async let cleanupLeg: Void = self.prepareCleanupModel(cleanupModel, settings: settings)
            _ = await (speechLeg, cleanupLeg)
            self.preparationTask = nil
        }
    }

    func syncSpeechState(from asr: ASRService) {
        if asr.isAsrReady {
            self.speechProgress = 1
            self.speechFinished = true
        } else if asr.isLoadingModel {
            self.speechProgress = 1
        } else if let progress = asr.downloadProgress {
            self.speechProgress = max(self.speechProgress, min(1, max(0, progress)))
        }
        self.updateDisplayedProgress()
    }

    private func prepareSpeechModel(asr: ASRService) async {
        do {
            try await asr.ensureAsrReady(source: .onboarding) { [weak self] progress in
                guard let self else { return }
                self.speechProgress = max(self.speechProgress, min(1, max(0, progress)))
                self.updateDisplayedProgress()
            }
            self.speechProgress = 1
            self.speechFinished = true
            self.updateDisplayedProgress()
            await asr.checkIfModelsExistAsync()
        } catch is CancellationError {
            DebugLogger.shared.info("Cancelled Tide onboarding speech-model setup", source: "OnboardingFlowView")
        } catch {
            DebugLogger.shared.error("Failed to prepare Tide onboarding speech model: \(error)", source: "OnboardingFlowView")
            asr.errorTitle = "Voice Model Setup Failed"
            asr.errorMessage = error.localizedDescription
            asr.showError = true
        }
    }

    private func prepareCleanupModel(
        _ model: PrivateAIRegisteredModel,
        settings: SettingsStore
    ) async {
        guard self.cleanupLegIncluded else { return }
        guard !self.cleanupFinished else { return }

        do {
            let coordinator = self
            _ = try await PrivateAIIntegrationService.prepareModel(model) { progress in
                await coordinator.receiveCleanupProgress(progress, model: model)
            }
            self.cleanupProgress = 1
            self.cleanupFinished = true
            self.persistCleanupModelSelection(model, settings: settings)
            self.updateDisplayedProgress()
        } catch is CancellationError {
            // Onboarding never cancels this task. Treat external cancellation as a
            // non-gating cleanup-model failure so speech setup can still finish.
            self.finishCleanupLegAfterFailure("cancelled")
        } catch {
            self.finishCleanupLegAfterFailure(error.localizedDescription)
        }
    }

    private func receiveCleanupProgress(
        _ progress: PrivateAIModelDownloadProgress,
        model: PrivateAIRegisteredModel
    ) {
        let progress = progress.withFallbackExpectedBytes(model.artifact.byteCount)
        if let fraction = progress.fractionCompleted {
            self.cleanupProgress = max(self.cleanupProgress, fraction)
        }
        self.updateDisplayedProgress()
    }

    private func finishCleanupLegAfterFailure(_ reason: String) {
        DebugLogger.shared.warning(
            "Tide onboarding cleanup-model preparation did not complete: \(reason)",
            source: "OnboardingFlowView"
        )
        self.cleanupProgress = 1
        self.cleanupFinished = true
        self.updateDisplayedProgress()
    }

    private func persistCleanupModelSelection(
        _ model: PrivateAIRegisteredModel,
        settings: SettingsStore
    ) {
        let providerID = PrivateAIProviderFeature.shared.providerID
        let providerKey = DictationAIPostProcessingGate.providerKey(for: providerID)
        var selectedModels = settings.selectedModelByProvider
        selectedModels[providerKey] = model.id
        settings.selectedModelByProvider = selectedModels
        UserDefaults.standard.set(model.id, forKey: PrivateAIIntegrationService.selectedModelDefaultsKey)
    }

    private func updateDisplayedProgress() {
        let rawProgress: Double
        if !self.cleanupLegIncluded {
            rawProgress = self.speechProgress
        } else if let speechExpectedBytes,
                  speechExpectedBytes > 0,
                  let cleanupExpectedBytes,
                  cleanupExpectedBytes > 0
        {
            let speechWeight = Double(speechExpectedBytes)
            let cleanupWeight = Double(cleanupExpectedBytes)
            rawProgress = ((self.speechProgress * speechWeight) + (self.cleanupProgress * cleanupWeight))
                / (speechWeight + cleanupWeight)
        } else {
            rawProgress = (self.speechProgress + self.cleanupProgress) / 2
        }

        self.displayedProgress = max(self.displayedProgress, min(1, max(0, rawProgress)))
    }
}
