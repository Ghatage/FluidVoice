import SwiftUI

enum TideOnboardingType {
    static func heading(size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func mono(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let heading = Self.heading(size: 44)
    static let body = Self.body(size: 17)
    static let button = Font.system(size: 16, weight: .heavy, design: .rounded)
    static let fine = Font.system(size: 13, weight: .regular)
    static let link = Font.system(size: 14, weight: .bold)
    static let kicker = Font.system(size: 13, weight: .bold)
    static let sellingPoint = Font.system(size: 14, weight: .regular)
    static let mono = Self.mono(size: 14)
    static let percent = Font.system(size: 12, weight: .medium, design: .monospaced)
}

struct TideOnboardingWindow<Content: View>: View {
    let stepIndex: Int
    let stepCount: Int
    let downloadProgress: Double?
    let isSpeechLoading: Bool
    let theme: AppTheme
    let onSelectStep: (Int) -> Void
    let content: Content

    init(
        stepIndex: Int,
        stepCount: Int,
        downloadProgress: Double?,
        isSpeechLoading: Bool,
        theme: AppTheme,
        onSelectStep: @escaping (Int) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.stepIndex = stepIndex
        self.stepCount = stepCount
        self.downloadProgress = downloadProgress
        self.isSpeechLoading = isSpeechLoading
        self.theme = theme
        self.onSelectStep = onSelectStep
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Painted first and allowed under the titlebar so the window reads as one
            // continuous `bg` surface with the traffic lights floating on it.
            self.theme.tide.bg

            self.canvas
        }
        .ignoresSafeArea()
        .background(TideOnboardingWindowConfigurator(backgroundColor: self.theme.tide.bg))
    }

    private var canvas: some View {
        VStack(spacing: 0) {
            // The traffic lights in the mock are the window's own — the system draws them
            // over this band, which is why nothing is painted at the leading edge here.
            HStack(spacing: 8) {
                Spacer()

                TideOnboardingStepDots(
                    activeIndex: self.stepIndex,
                    count: self.stepCount,
                    theme: self.theme,
                    onSelect: self.onSelectStep
                )
            }
            .frame(height: TideOnboardingMetrics.titlebarHeight)
            .accessibilityElement(children: .contain)
            .padding(.bottom, 14)

            self.content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            if let downloadProgress {
                TideOnboardingDownloadStatusView(
                    progress: downloadProgress,
                    isSpeechLoading: self.isSpeechLoading,
                    theme: self.theme
                )
                .padding(.top, 14)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 36)
        // Lay out at exactly the mock's canvas, then scale that canvas into whatever size
        // the window happens to be. Every spacing and type relationship stays as drawn.
        .frame(
            width: TideOnboardingMetrics.canvasSize.width,
            height: TideOnboardingMetrics.canvasSize.height
        )
        .modifier(TideOnboardingScaleToFit())
    }
}

/// Scales the fixed design canvas to fill the available space, preserving its aspect ratio
/// and centring it.
private struct TideOnboardingScaleToFit: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let canvas = TideOnboardingMetrics.canvasSize
            let scale = max(
                0.1,
                min(proxy.size.width / canvas.width, proxy.size.height / canvas.height)
            )
            content
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

enum TideOnboardingMetrics {
    /// Matches the macOS titlebar so the step dots sit level with the traffic lights.
    static let titlebarHeight: CGFloat = 28
    /// The mock's canvas. The layout is built at this size and scaled to the window.
    static let canvasSize = CGSize(width: 680, height: 460)
}

private struct TideOnboardingStepDots: View {
    let activeIndex: Int
    let count: Int
    let theme: AppTheme
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<self.count, id: \.self) { index in
                Button {
                    self.onSelect(index)
                } label: {
                    Capsule()
                        .fill(index == self.activeIndex ? self.theme.tide.accent : self.theme.tide.line)
                        .frame(width: index == self.activeIndex ? 22 : 6, height: 6)
                        .contentShape(Rectangle().inset(by: -6))
                }
                .buttonStyle(.plain)
                .disabled(index >= self.activeIndex)
                .accessibilityLabel("Go back to step \(index + 1)")
                .accessibilityAddTraits(index == self.activeIndex ? .isSelected : [])
            }
        }
    }
}

struct TideOnboardingPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let theme: AppTheme
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    init(
        _ title: String,
        isEnabled: Bool = true,
        theme: AppTheme,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.theme = theme
        self.action = action
    }

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .font(TideOnboardingType.button)
                .foregroundStyle(self.theme.tide.accentInk)
                .padding(.horizontal, 24)
                .frame(height: 48)
                .background(
                    Capsule()
                        .fill(self.isHovered && self.isEnabled ? self.theme.tide.accentHover : self.theme.tide.accent)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(TideOnboardingPressedButtonStyle(reduceMotion: self.reduceMotion))
        .focused(self.$isFocused)
        .focusable(self.isEnabled)
        // The mock specifies a 2pt accent focus ring; suppress AppKit's blue one so the
        // overlay below is the only ring that shows.
        .focusEffectDisabled()
        .overlay(
            Capsule()
                .stroke(self.isFocused ? self.theme.tide.accent : .clear, lineWidth: 2)
                .padding(-2)
        )
        .opacity(self.isEnabled ? 1 : 0.4)
        .disabled(!self.isEnabled)
        .onHover { self.isHovered = $0 }
    }
}

private struct TideOnboardingPressedButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !self.reduceMotion ? 0.98 : 1)
            .animation(self.reduceMotion ? nil : .easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

struct TideOnboardingLinkButton: View {
    let title: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .font(TideOnboardingType.link)
                .foregroundStyle(self.theme.tide.muted)
                .underline()
        }
        .buttonStyle(.plain)
        .focusable()
    }
}

extension View {
    func tideOnboardingHeading(theme: AppTheme) -> some View {
        self
            .font(TideOnboardingType.heading)
            .tracking(-1.32)
            .foregroundStyle(theme.tide.text)
            .fixedSize(horizontal: false, vertical: true)
    }

    func tideOnboardingLede(theme: AppTheme) -> some View {
        self
            .font(TideOnboardingType.body)
            .foregroundStyle(theme.tide.muted)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}
