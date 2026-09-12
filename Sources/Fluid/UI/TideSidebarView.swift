import AppKit
import SwiftUI

struct TideSidebarView: View {
    @Binding var selection: SidebarItem?
    let theme: AppTheme

    var body: some View {
        ZStack {
            self.theme.tide.side
                .ignoresSafeArea()

            VStack(spacing: 0) {
                self.brand
                self.searchField

                ScrollView {
                    LazyVStack(spacing: 0) {
                        VStack(spacing: 4) {
                            self.row(.home, "Home", "house.fill")
                            self.row(.welcome, "Getting Started", "checkmark.circle")
                            self.row(.history, "History", "clock.arrow.circlepath")
                            self.row(.customDictionary, "Dictionary", "text.book.closed.fill")
                        }

                        self.group("MODES") {
                            self.row(.commandMode, "Command", "terminal.fill", alpha: true)
                            self.row(.rewriteMode, "Write", "pencil.line")
                            self.row(.meetingTools, "Files", "doc.text.fill")
                        }

                        self.group("DICTATION") {
                            self.row(.voiceEngine, "Voice Engine", "waveform")
                            self.row(.settings(.dictation), "Shortcuts", "keyboard")
                            self.row(.settings(.audio), "Audio", "speaker.wave.2")
                            self.row(.settings(.overlay), "Overlay", "rectangle.on.rectangle")
                        }

                        self.group("INTELLIGENCE") {
                            self.row(.aiEnhancements, "AI Providers", "cpu")
                            self.row(.cleanupStyles, "Cleanup Styles", "wand.and.stars")
                        }

                        self.group("APP") {
                            self.row(.settings(.general), "General", "gearshape")
                            self.row(.settings(.notifications), "Notifications", "bell")
                            self.row(.settings(.dataAndDiagnostics), "Data & Privacy", "lock.shield")
                            self.row(.settings(.experimental), "Experimental", "flask")
                            self.row(.changelog, "Changelog", "doc.text.magnifyingglass")
                        }
                    }
                }
                .scrollIndicators(.hidden)

                Spacer(minLength: 12)

                self.row(.feedback, "Feedback", "envelope.fill")
            }
            .padding(.top, 18)
            .padding(.horizontal, 14)
            .padding(.bottom, 16)
        }
        .foregroundStyle(self.theme.tide.text)
        .tint(self.theme.tide.accent)
    }

    private var brand: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)

            Text("FluidVoice")
                .font(TideOnboardingType.heading(size: 18, weight: .heavy))
                .tracking(-0.36)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 14)
    }

    /// Presentational only — the sidebar search is not wired to anything yet.
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))

            Text("Search")

            Spacer(minLength: 0)
        }
        .font(TideOnboardingType.body(size: 13))
        .foregroundStyle(self.theme.tide.muted)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Capsule().fill(self.theme.tide.card))
        .padding(.horizontal, 4)
        .padding(.bottom, 16)
        .accessibilityHidden(true)
    }

    private func group<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(TideOnboardingType.heading(size: 11, weight: .bold))
                .tracking(0.88)
                .foregroundStyle(self.theme.tide.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 18)
                .padding(.bottom, 6)

            content()
        }
    }

    private func row(
        _ item: SidebarItem,
        _ title: String,
        _ systemImage: String,
        alpha: Bool = false
    ) -> some View {
        TideSidebarRow(
            item: item,
            title: title,
            systemImage: systemImage,
            showsAlphaTag: alpha,
            selection: self.$selection,
            theme: self.theme
        )
    }
}

private struct TideSidebarRow: View {
    let item: SidebarItem
    let title: String
    let systemImage: String
    let showsAlphaTag: Bool
    @Binding var selection: SidebarItem?
    let theme: AppTheme

    @State private var isHovered = false

    private var isSelected: Bool {
        self.selection?.tideDestination == self.item.tideDestination
    }

    var body: some View {
        Button {
            self.selection = self.item
        } label: {
            HStack(spacing: 10) {
                Image(systemName: self.systemImage)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)

                Text(self.title)
                    .font(TideOnboardingType.heading(size: 14, weight: .bold))
                    .lineLimit(1)

                Spacer(minLength: 6)

                if self.showsAlphaTag {
                    Text("Alpha")
                        .font(TideOnboardingType.heading(size: 10, weight: .bold))
                        .foregroundStyle(self.theme.tide.accent2Deep)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(self.theme.tide.accent2Soft, in: Capsule())
                }
            }
            .foregroundStyle(self.isSelected ? self.theme.tide.accentInk : self.theme.tide.text)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)
            .background(self.rowBackground, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { self.isHovered = $0 }
        .accessibilityLabel(self.title)
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    }

    private var rowBackground: Color {
        if self.isSelected {
            return self.theme.tide.accent
        }
        return self.isHovered ? self.theme.tide.card : .clear
    }
}
