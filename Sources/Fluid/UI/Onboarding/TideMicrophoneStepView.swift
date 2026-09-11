import SwiftUI

struct TideMicrophoneStepView: View {
    let theme: AppTheme
    let onAllowMicrophone: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Say hello.")
                    .tideOnboardingHeading(theme: self.theme)

                Text("FluidVoice turns your voice into text in any app. First, it needs to hear you.")
                    .tideOnboardingLede(theme: self.theme)

                TideOnboardingPrimaryButton("Allow microphone", theme: self.theme) {
                    self.onAllowMicrophone()
                }
                .padding(.top, 6)

                Text("Nothing you say leaves this Mac.")
                    .font(TideOnboardingType.fine)
                    .foregroundStyle(self.theme.tide.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            self.sayHelloIllustration
        }
    }

    @ViewBuilder
    private var sayHelloIllustration: some View {
        // TODO: Replace this runtime treatment with the preferred pre-inverted dark asset.
        if self.colorScheme == .dark {
            Image("OnboardingSayHello")
                .resizable()
                .scaledToFit()
                .colorInvert()
                .hueRotation(.degrees(180))
                .brightness(0.05)
                .opacity(0.95)
                .frame(width: 200, height: 300)
                .accessibilityHidden(true)
        } else {
            Image("OnboardingSayHello")
                .resizable()
                .scaledToFit()
                .opacity(0.95)
                .frame(width: 200, height: 300)
                .accessibilityHidden(true)
        }
    }
}
