//
//  WelcomeView.swift
//  fluid
//
//  Welcome and setup guide view
//

import AppKit
import AVFoundation
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appServices: AppServices
    private var asr: ASRService {
        self.appServices.asr
    }

    @ObservedObject private var settings = SettingsStore.shared
    @Binding var selectedSidebarItem: SidebarItem?
    @Binding var playgroundUsed: Bool
    var isTranscriptionFocused: FocusState<Bool>.Binding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.theme) private var theme

    let accessibilityEnabled: Bool
    let stopAndProcessTranscription: () async -> Void
    let startRecording: () -> Void
    let openAccessibilitySettings: () -> Void
    let restartApp: () -> Void

    private let playgroundSectionID = "welcome-playground-section"

    private var isAIEnhancementReady: Bool {
        DictationAIPostProcessingGate.isProviderConfigured()
    }

    private var appDisplayName: String {
        Bundle.main.fluidAppDisplayName
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.fill")
                            .font(self.theme.typography.titleIcon)
                            .foregroundStyle(self.theme.palette.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text((self.asr.isAsrReady || self.asr.modelsExistOnDisk) ? "Getting Started" : "Welcome to FluidVoice")
                                .font(self.theme.typography.title)
                            Text("Talk anywhere. FluidVoice types for you.")
                                .font(self.theme.typography.bodySmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 4)

                    // Quick Setup Checklist
                    ThemedCard(style: .prominent) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Label("Quick Setup", systemImage: "checkmark.circle.fill")
                                    .font(self.theme.typography.sectionTitle)
                                    .foregroundStyle(self.theme.palette.accent)

                                Spacer()

                                Button {
                                    self.settings.resetOnboardingProgress()
                                    self.playgroundUsed = false
                                } label: {
                                    Label("Run Onboarding Again", systemImage: "arrow.counterclockwise")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                SetupStepView(
                                    step: 1,
                                    // Consider model step complete if ready OR downloaded (even if not loaded)
                                    title: (self.asr.isAsrReady || self.asr.modelsExistOnDisk) ? "Voice Model Ready" : "Download Voice Model",
                                    description: self.asr.isAsrReady
                                        ? "Speech recognition model is loaded and ready"
                                        : (
                                            self.asr.modelsExistOnDisk
                                                ? "Model downloaded, will load when needed"
                                                : "Download the AI model for offline voice transcription (~500MB)"
                                        ),
                                    status: (self.asr.isAsrReady || self.asr.modelsExistOnDisk) ? .completed : .pending,
                                    action: {
                                        self.selectedSidebarItem = .voiceEngine
                                    },
                                    actionButtonTitle: "Go to Voice Engine",
                                    showActionButton: !(self.asr.isAsrReady || self.asr.modelsExistOnDisk)
                                )

                                SetupStepView(
                                    step: 2,
                                    title: self.asr.micStatus == .authorized ? "Microphone Permission Granted" : "Grant Microphone Permission",
                                    description: self.asr.micStatus == .authorized
                                        ? "FluidVoice has access to your microphone"
                                        : "Allow FluidVoice to access your microphone for voice input",
                                    status: self.asr.micStatus == .authorized ? .completed : .pending,
                                    action: {
                                        if self.asr.micStatus == .notDetermined {
                                            self.asr.requestMicAccess()
                                        } else if self.asr.micStatus == .denied {
                                            self.asr.openSystemSettingsForMic()
                                        }
                                    },
                                    actionButtonTitle: self.asr.micStatus == .notDetermined ? "Grant Access" : "Open Settings",
                                    showActionButton: self.asr.micStatus != .authorized
                                )

                                SetupStepView(
                                    step: 3,
                                    title: self.accessibilityEnabled ? "Accessibility Access Enabled" : "Enable Accessibility Access",
                                    description: self.accessibilityEnabled
                                        ? "Accessibility permission granted for typing into apps"
                                        : "Drag \(self.appDisplayName) into the Accessibility apps list as shown",
                                    status: self.accessibilityEnabled ? .completed : .pending,
                                    action: {
                                        self.openAccessibilitySettings()
                                    },
                                    actionButtonTitle: "Open Settings",
                                    showActionButton: !self.accessibilityEnabled
                                )

                                SetupStepView(
                                    step: 4,
                                    title: self.isAIEnhancementReady ? "AI Enhancement Configured" : "Set Up AI Enhancement (Optional)",
                                    description: self.isAIEnhancementReady
                                        ? "AI-powered text enhancement is ready to use"
                                        : "Configure API keys for AI-powered text enhancement",
                                    status: self.isAIEnhancementReady ? .completed : .pending,
                                    action: {
                                        self.selectedSidebarItem = .aiEnhancements
                                    },
                                    actionButtonTitle: "AI Providers"
                                )

                                SetupStepView(
                                    step: 5,
                                    title: self.playgroundUsed ? "Setup Tested Successfully" : "Test Your Setup",
                                    description: self.playgroundUsed
                                        ? "You've successfully tested voice transcription"
                                        : "Try the playground below to test your complete setup",
                                    status: self.playgroundUsed ? .completed : .pending,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            proxy.scrollTo(self.playgroundSectionID, anchor: .top)
                                        }
                                        self.isTranscriptionFocused.wrappedValue = true
                                    },
                                    actionButtonTitle: "Go to Playground",
                                    showActionButton: !self.playgroundUsed
                                )
                                .id("playground-step-\(self.playgroundUsed)")
                            }
                        }
                        .padding(14)
                    }

                    // Test Playground
                    ThemedCard(hoverEffect: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Test Playground")
                                            .font(self.theme.typography.sectionTitle)
                                        Text("Click record, speak, and see your transcription")
                                            .font(self.theme.typography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "text.bubble")
                                        .font(self.theme.typography.titleIcon)
                                }

                                Spacer()

                                if self.asr.isRunning {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(.red)
                                            .frame(width: 6, height: 6)
                                        Text("Recording...")
                                            .font(self.theme.typography.captionStrong)
                                            .foregroundStyle(.red)
                                    }
                                } else if !self.asr.finalText.isEmpty {
                                    Text("\(self.asr.finalText.count) characters")
                                        .font(self.theme.typography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 14) {
                                // Recording Control — centered button
                                HStack {
                                    Spacer()
                                    Button {
                                        if self.asr.isRunning {
                                            Task {
                                                await self.stopAndProcessTranscription()
                                            }
                                        } else {
                                            self.startRecording()
                                            self.playgroundUsed = true
                                            SettingsStore.shared.playgroundUsed = true
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: self.asr.isRunning ? "stop.fill" : "mic.fill")
                                            Text(self.asr.isRunning ? "Stop Recording" : "Start Recording")
                                        }
                                        .frame(maxWidth: 220)
                                    }
                                    .fluidButton(.primary, size: .large, isRecording: self.asr.isRunning)
                                    .buttonHoverEffect()
                                    .scaleEffect(!self.reduceMotion && self.asr.isRunning ? 1.02 : 1.0)
                                    .animation(self.reduceMotion ? nil : .spring(response: 0.3), value: self.asr.isRunning)
                                    .disabled(!self.asr.isAsrReady && !self.asr.isRunning)
                                    Spacer()
                                }

                                // Text Area
                                VStack(alignment: .leading, spacing: 8) {
                                    TextEditor(text: Binding(
                                        get: { self.asr.finalText },
                                        set: { self.asr.finalText = $0 }
                                    ))
                                    .font(self.theme.typography.body)
                                    .focused(self.isTranscriptionFocused)
                                    .frame(height: 120)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(
                                                self.asr.isRunning ? self.theme.palette.accent.opacity(0.06) : self.theme.palette.cardBackground
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(
                                                        self.asr.isRunning ? self.theme.palette.accent.opacity(0.4) : self.theme.palette.cardBorder.opacity(0.6),
                                                        lineWidth: self.asr.isRunning ? 2 : 1
                                                    )
                                            )
                                    )
                                    .scrollContentBackground(.hidden)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            if self.asr.isRunning {
                                                Image(systemName: "waveform")
                                                    .font(self.theme.typography.titleIcon)
                                                    .foregroundStyle(self.theme.palette.accent)
                                                Text("Listening... Speak now!")
                                                    .font(self.theme.typography.bodySmallStrong)
                                                    .foregroundStyle(self.theme.palette.accent)
                                                Text("Transcription will appear when you stop recording")
                                                    .font(self.theme.typography.caption)
                                                    .foregroundStyle(self.theme.palette.accent.opacity(0.7))
                                            } else if self.asr.finalText.isEmpty {
                                                Image(systemName: "text.bubble")
                                                    .font(self.theme.typography.titleIcon)
                                                    .foregroundStyle(.secondary.opacity(0.5))
                                                Text("Press record or your hotkey to begin")
                                                    .font(self.theme.typography.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .allowsHitTesting(false)
                                    )

                                    if !self.asr.finalText.isEmpty {
                                        HStack(spacing: 8) {
                                            Button {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(self.asr.finalText, forType: .string)
                                            } label: {
                                                Label("Copy Text", systemImage: "doc.on.doc")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(self.theme.palette.accent)
                                            .controlSize(.small)

                                            Button("Clear & Test Again") {
                                                self.asr.finalText = ""
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)

                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .id(self.playgroundSectionID)
                }
                .padding(16)
            }
        }
        .onAppear {
            Task { @MainActor in
                await AudioStartupGate.shared.scheduleOpenAfterInitialUISettled()
                await AudioStartupGate.shared.waitUntilOpen()
                self.asr.micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                await self.asr.checkIfModelsExistAsync()
            }
        }
    }
}
