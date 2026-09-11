import SwiftUI

struct TideAccessibilityStepView: View {
    let theme: AppTheme
    let onOpenSystemSettings: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Let it type for you.")
                    .tideOnboardingHeading(theme: self.theme)

                Text("macOS asks once. Switch on FluidVoice under Accessibility, then come back here.")
                    .tideOnboardingLede(theme: self.theme)

                TideOnboardingPrimaryButton("Open System Settings", theme: self.theme) {
                    self.onOpenSystemSettings()
                }
                .padding(.top, 6)

                TideOnboardingLinkButton(
                    title: "Skip, I’ll paste text myself",
                    theme: self.theme,
                    action: self.onSkip
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TideAccessibilityIllustration(theme: self.theme)
        }
    }
}
