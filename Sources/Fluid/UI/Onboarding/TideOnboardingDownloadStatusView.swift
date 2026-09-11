import Combine
import SwiftUI

struct TideOnboardingDownloadStatusView: View {
    let progress: Double
    let isSpeechLoading: Bool
    let theme: AppTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var statusLineIndex = 0

    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    private static let statusLines = [
        "Warming up your digital voice…",
        "Teaching it to keep up with you…",
        "Tuning in to your accent…",
        "Fetching a few billion words…",
        "Learning where the commas go…",
        "Getting the punctuation just right…",
        "Stretching its vocal cords…",
        "Loading your typing superpower…",
        "Making room for big ideas…",
        "Sharpening its ears…",
        "Practising your name…",
        "Downloading a very good listener…",
        "Preparing to type at the speed of talk…",
        "Memorising the dictionary…",
        "Getting fluent…",
        "Building your private transcriber…",
        "Plugging in the microphone (metaphorically)…",
        "Nothing here leaves your Mac…",
        "Almost ready to take dictation…",
        "Clearing its throat…",
        "Rehearsing the hard words…",
        "Calibrating for mumbling…",
        "Warming up the keyboard…",
        "Learning to spell \"definitely\"…",
        "Nearly there…",
    ]

    private var normalizedProgress: Double {
        min(1, max(0, self.progress))
    }

    private var label: String {
        if self.isSpeechLoading {
            return "Almost there…"
        }
        return Self.statusLines[self.statusLineIndex]
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(self.label)
                    .id(self.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(self.theme.tide.muted)
                    .transition(.opacity)

                Spacer(minLength: 12)

                Text("\(Int((self.normalizedProgress * 100).rounded()))%")
                    .font(TideOnboardingType.percent)
                    .foregroundStyle(self.theme.tide.text)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(self.theme.tide.line)
                    Capsule()
                        .fill(self.theme.tide.accent)
                        .frame(width: proxy.size.width * self.normalizedProgress)
                }
            }
            .frame(height: 4)
            .animation(self.reduceMotion ? nil : .easeOut(duration: 0.25), value: self.normalizedProgress)
        }
        .onReceive(self.timer) { _ in
            let nextIndex = (self.statusLineIndex + 1) % Self.statusLines.count
            if self.reduceMotion {
                self.statusLineIndex = nextIndex
            } else {
                withAnimation(.easeInOut(duration: 0.30)) {
                    self.statusLineIndex = nextIndex
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.label), \(Int((self.normalizedProgress * 100).rounded())) percent")
    }
}
