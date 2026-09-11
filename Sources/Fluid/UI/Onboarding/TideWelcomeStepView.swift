import SwiftUI

struct TideWelcomeStepView: View {
    let downloadSize: String
    let theme: AppTheme
    let onStartDownload: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("WELCOME TO FLUIDVOICE")
                    .font(TideOnboardingType.kicker)
                    .tracking(1.04)
                    .foregroundStyle(self.theme.tide.accent)

                Text("Fast. Accurate. Private.")
                    .tideOnboardingHeading(theme: self.theme)

                VStack(alignment: .leading, spacing: 10) {
                    self.sellingPoint(
                        lead: "Sub-second transcription.",
                        detail: "Your words land before you lift the key.",
                        color: self.theme.tide.accent
                    )
                    self.sellingPoint(
                        lead: "State-of-the-art accuracy.",
                        detail: "Names, jargon and punctuation, right the first time.",
                        color: self.theme.tide.accent
                    )
                    self.sellingPoint(
                        lead: "Completely local.",
                        detail: "Nothing you say ever leaves this Mac.",
                        color: self.theme.tide.accent2
                    )
                }

                TideOnboardingPrimaryButton("Start download", theme: self.theme) {
                    self.onStartDownload()
                }
                .padding(.top, 6)

                Text("Fetches your voice model · about \(self.downloadSize), one time only")
                    .font(TideOnboardingType.fine)
                    .foregroundStyle(self.theme.tide.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TideWelcomeIllustration(theme: self.theme)
        }
    }

    private func sellingPoint(lead: String, detail: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            (Text(lead + " ")
                .fontWeight(.bold)
                .foregroundColor(self.theme.tide.text)
                + Text(detail)
                .foregroundColor(self.theme.tide.muted))
                .font(TideOnboardingType.sellingPoint)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
