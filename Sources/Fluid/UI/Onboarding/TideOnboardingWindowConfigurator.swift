import AppKit
import SwiftUI

/// The Tide mock presents onboarding as a window whose titlebar is part of the artwork:
/// no title, the traffic lights floating over the `bg` surface.
///
/// This makes the *real* window look that way — full-size content view, transparent
/// titlebar, `bg` as the window background — and restores what it touched when onboarding
/// tears the view down.
///
/// It deliberately does **not** touch the window's size, position or resizability. The app
/// keeps its normal dimensions and the onboarding layout scales to fit. Driving window
/// geometry from here crashes two different ways: setting frame or style during SwiftUI's
/// render pass re-enters the attribute graph (EXC_BAD_ACCESS in `AG::Graph::value_set`),
/// and resizing inside the display cycle makes AppKit throw from
/// `_postWindowNeedsUpdateConstraints`.
struct TideOnboardingWindowConfigurator: NSViewRepresentable {
    let backgroundColor: Color

    func makeNSView(context _: Context) -> NSView {
        TideOnboardingWindowConfiguratorView(backgroundColor: NSColor(self.backgroundColor))
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        guard let view = nsView as? TideOnboardingWindowConfiguratorView else { return }
        view.update(backgroundColor: NSColor(self.backgroundColor))
    }
}

private final class TideOnboardingWindowConfiguratorView: NSView {
    private struct RestoreState {
        let styleMask: NSWindow.StyleMask
        let titleVisibility: NSWindow.TitleVisibility
        let titlebarAppearsTransparent: Bool
        let backgroundColor: NSColor
    }

    private var backgroundColor: NSColor
    private weak var configuredWindow: NSWindow?
    private var restoreState: RestoreState?

    init(backgroundColor: NSColor) {
        self.backgroundColor = backgroundColor
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    deinit {
        // `deinit` can land off the main actor; hop before touching AppKit.
        let window = self.configuredWindow
        let state = self.restoreState
        guard let window, let state else { return }
        Task { @MainActor in
            Self.restore(window: window, to: state)
        }
    }

    func update(backgroundColor: NSColor) {
        guard self.backgroundColor != backgroundColor else { return }
        self.backgroundColor = backgroundColor
        guard let window = self.configuredWindow else { return }
        DispatchQueue.main.async { window.backgroundColor = backgroundColor }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if self.window == nil {
            // Onboarding finished (or the view moved away): hand the window back as we found it.
            if let window = self.configuredWindow, let state = self.restoreState {
                DispatchQueue.main.async { Self.restore(window: window, to: state) }
            }
            self.configuredWindow = nil
            self.restoreState = nil
            return
        }

        guard let window, window !== self.configuredWindow else { return }
        // This runs inside `NSHostingView.layout()`; mutating the window here would fire KVO
        // back into SwiftUI mid-render. Hop to the next main-queue turn instead.
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window, self.window === window, window !== self.configuredWindow else { return }
            self.configure(window)
        }
    }

    private func configure(_ window: NSWindow) {
        self.restoreState = RestoreState(
            styleMask: window.styleMask,
            titleVisibility: window.titleVisibility,
            titlebarAppearsTransparent: window.titlebarAppearsTransparent,
            backgroundColor: window.backgroundColor
        )
        self.configuredWindow = window

        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = self.backgroundColor

        // Hiding the window toolbar (so no opaque band paints over the `bg` surface) also
        // takes the traffic lights with it. Put them back, floating over the content, which
        // is how the mock draws them — and without them there is no way to close the window
        // with the mouse.
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = false
        }
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }

    @MainActor
    private static func restore(window: NSWindow, to state: RestoreState) {
        window.styleMask = state.styleMask
        window.titleVisibility = state.titleVisibility
        window.titlebarAppearsTransparent = state.titlebarAppearsTransparent
        window.backgroundColor = state.backgroundColor
        window.standardWindowButton(.zoomButton)?.isEnabled = true
    }
}
