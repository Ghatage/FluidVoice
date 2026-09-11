import SwiftUI

struct TideTryoutStepView: View {
    let shortcutDisplay: String
    let finalText: String
    let isListening: Bool
    let isReady: Bool
    let isValidated: Bool
    let isDownloadInProgress: Bool
    let theme: AppTheme
    let onTry: () -> Void
    let onDone: () -> Void
    let onFinishInBackground: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretVisible = true

    private var hasText: Bool {
        !self.finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsActiveTranscription: Bool {
        self.isListening || self.hasText
    }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Try it.")
                    .tideOnboardingHeading(theme: self.theme)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        Text("Hold")
                        self.keyCap
                        Text("and say anything.")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hold")
                        HStack(spacing: 6) {
                            self.keyCap
                            Text("and say anything.")
                        }
                    }
                }
                .font(TideOnboardingType.body)
                .foregroundStyle(self.theme.tide.muted)

                self.liveTextBox

                TideOnboardingPrimaryButton(
                    self.isValidated ? "Done" : "Try it",
                    isEnabled: self.isReady,
                    theme: self.theme
                ) {
                    if self.isValidated {
                        self.onDone()
                    } else {
                        self.onTry()
                    }
                }
                .padding(.top, 6)

                if self.isDownloadInProgress {
                    TideOnboardingLinkButton(
                        title: "Finish download in the background and complete setup",
                        theme: self.theme,
                        action: self.onFinishInBackground
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TideTryoutIllustration(theme: self.theme)
        }
        .task(id: self.isListening) {
            self.caretVisible = true
            guard self.isListening, !self.reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                self.caretVisible.toggle()
            }
        }
    }

    private var keyCap: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)

        return Text(self.shortcutDisplay)
            .font(TideOnboardingType.mono)
            .foregroundStyle(self.theme.tide.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                shape
                    .fill(self.theme.tide.card)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(self.theme.tide.line)
                            .frame(height: 2)
                    }
                    .clipShape(shape)
            )
    }

    private var liveTextBox: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(self.showsActiveTranscription ? self.theme.tide.accent : self.theme.tide.line)
                .frame(width: 10, height: 10)

            if self.showsActiveTranscription {
                Text(self.hasText ? self.finalText : "Listening…")
                    .foregroundStyle(self.theme.tide.text)
                    .lineLimit(2)

                if self.isListening {
                    Rectangle()
                        .fill(self.theme.tide.accent)
                        .frame(width: 2, height: 18)
                        .opacity(self.reduceMotion || self.caretVisible ? 1 : 0)
                }
            } else {
                Text("Your words will show up here")
                    .foregroundStyle(self.theme.tide.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: 16, weight: .regular))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(self.theme.tide.card)
        )
        .accessibilityElement(children: .combine)
    }
}
