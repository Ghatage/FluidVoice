import SwiftUI

/// Central theme definition for the Fluid app. All colors, spacings and materials
/// should be defined here to keep styling consistent and easy to evolve.
struct AppTheme {
    struct TidePalette {
        let bg: Color
        let side: Color
        let card: Color
        let text: Color
        let muted: Color
        let line: Color
        let accent: Color
        let accentInk: Color
        let accentDeep: Color
        let accent2: Color
        let accent2Ink: Color
        let accent2Soft: Color
        let accent2Deep: Color
        let accentSoft: Color
        let accentHover: Color
        let page: Color

        static let light = TidePalette(
            bg: Color(red: 1.000, green: 0.969, blue: 0.949),
            side: Color(red: 1.000, green: 0.933, blue: 0.898),
            card: .white,
            text: Color(red: 0.118, green: 0.082, blue: 0.071),
            muted: Color(red: 0.478, green: 0.365, blue: 0.329),
            line: Color(red: 0.118, green: 0.082, blue: 0.071).opacity(0.12),
            accent: Color(red: 1.000, green: 0.361, blue: 0.224),
            accentInk: .white,
            accentDeep: Color(red: 0.722, green: 0.224, blue: 0.118),
            accent2: Color(red: 0.055, green: 0.486, blue: 0.525),
            accent2Ink: .white,
            accent2Soft: Color(red: 0.827, green: 0.933, blue: 0.941),
            accent2Deep: Color(red: 0.039, green: 0.353, blue: 0.380),
            accentSoft: Color(red: 1.000, green: 0.867, blue: 0.824),
            accentHover: Color(red: 0.929, green: 0.286, blue: 0.157),
            page: Color(red: 0.953, green: 0.894, blue: 0.859)
        )

        static let dark = TidePalette(
            bg: Color(red: 0.102, green: 0.063, blue: 0.051),
            side: Color(red: 0.082, green: 0.047, blue: 0.035),
            card: Color(red: 0.169, green: 0.102, blue: 0.075),
            text: Color(red: 1.000, green: 0.945, blue: 0.918),
            muted: Color(red: 0.788, green: 0.647, blue: 0.584),
            line: Color(red: 1.000, green: 0.945, blue: 0.918).opacity(0.12),
            accent: Color(red: 1.000, green: 0.478, blue: 0.361),
            accentInk: Color(red: 0.165, green: 0.051, blue: 0.020),
            accentDeep: Color(red: 1.000, green: 0.690, blue: 0.612),
            accent2: Color(red: 0.282, green: 0.769, blue: 0.812),
            accent2Ink: Color(red: 0.016, green: 0.149, blue: 0.165),
            accent2Soft: Color(red: 0.059, green: 0.227, blue: 0.243),
            accent2Deep: Color(red: 0.561, green: 0.878, blue: 0.906),
            accentSoft: Color(red: 0.302, green: 0.125, blue: 0.082),
            accentHover: Color(red: 1.000, green: 0.361, blue: 0.224),
            page: Color(red: 0.059, green: 0.031, blue: 0.024)
        )
    }

    struct Palette {
        let windowBackground: Color
        let contentBackground: Color
        let sidebarBackground: Color
        let cardBackground: Color
        let elevatedCardBackground: Color
        let toolbarBackground: Color
        let cardBorder: Color
        let separator: Color
        let primaryText: Color
        let secondaryText: Color
        let tertiaryText: Color
        let accent: Color
        let warning: Color
        let success: Color
    }

    struct Typography {
        let displayTitle: Font
        let statement: Font
        let title: Font
        let titleIcon: Font
        let sectionTitle: Font
        let body: Font
        let bodyStrong: Font
        let bodySmall: Font
        let bodySmallStrong: Font
        let caption: Font
        let captionStrong: Font
        let captionSmall: Font
        let tiny: Font
        let tinyStrong: Font
        let badge: Font
        let metricTiny: Font
        let codeCaption: Font
        let sidebarItem: Font
        let sidebarSection: Font
        let chromeCaption: Font

        static let standard = Typography(
            displayTitle: TideOnboardingType.heading(size: 42),
            statement: TideOnboardingType.body(size: 17),
            title: TideOnboardingType.heading(size: 22),
            titleIcon: TideOnboardingType.body(size: 22),
            sectionTitle: TideOnboardingType.heading(size: 15, weight: .bold),
            body: TideOnboardingType.body(size: 14),
            bodyStrong: TideOnboardingType.body(size: 14, weight: .semibold),
            bodySmall: TideOnboardingType.body(size: 13),
            bodySmallStrong: TideOnboardingType.body(size: 13, weight: .semibold),
            caption: TideOnboardingType.body(size: 12),
            captionStrong: TideOnboardingType.body(size: 12, weight: .semibold),
            captionSmall: TideOnboardingType.body(size: 11),
            tiny: TideOnboardingType.body(size: 11),
            tinyStrong: TideOnboardingType.heading(size: 11, weight: .bold),
            badge: TideOnboardingType.heading(size: 11, weight: .semibold),
            metricTiny: TideOnboardingType.heading(size: 11, weight: .bold),
            codeCaption: TideOnboardingType.mono(size: 12),
            sidebarItem: TideOnboardingType.heading(size: 14, weight: .bold),
            sidebarSection: TideOnboardingType.heading(size: 11, weight: .bold),
            chromeCaption: TideOnboardingType.body(size: 12)
        )
    }

    struct Metrics {
        struct Spacing {
            let xs: CGFloat
            let sm: CGFloat
            let md: CGFloat
            let lg: CGFloat
            let xl: CGFloat
            let xxl: CGFloat

            static let standard = Spacing(
                xs: 4,
                sm: 8,
                md: 12,
                lg: 16,
                xl: 20,
                xxl: 28
            )
        }

        struct CornerRadius {
            let sm: CGFloat
            let md: CGFloat
            let lg: CGFloat
            let pill: CGFloat

            static let standard = CornerRadius(
                sm: 16,
                md: 18,
                lg: 20,
                pill: 999
            )
        }

        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
            let opacity: Double

            static func subtle(color: Color, opacity: Double = 0.45) -> Shadow {
                Shadow(color: color, radius: 12, x: 0, y: 6, opacity: opacity)
            }
        }

        struct FormRow {
            let horizontalPadding: CGFloat
            let verticalPadding: CGFloat
            let cornerRadius: CGFloat
            let materialOpacity: Double
            let borderOpacity: Double

            static let standard = FormRow(
                horizontalPadding: 12,
                verticalPadding: 10,
                cornerRadius: 16,
                materialOpacity: 0.5,
                borderOpacity: 0.8
            )
        }

        struct PickerControl {
            let horizontalPadding: CGFloat
            let verticalPadding: CGFloat
            let cornerRadius: CGFloat
            let borderOpacity: Double
            let searchBorderOpacity: Double
            let disclosureSize: CGFloat
            let disclosureBorderOpacity: Double
            let selectedRowOpacity: Double

            static let standard = PickerControl(
                horizontalPadding: 8,
                verticalPadding: 5,
                cornerRadius: 999,
                borderOpacity: 0.35,
                searchBorderOpacity: 0.3,
                disclosureSize: 20,
                disclosureBorderOpacity: 0.4,
                selectedRowOpacity: 0.15
            )
        }

        struct CardSurface {
            struct Variant {
                let borderOpacity: Double
                let hoverBorderOpacity: Double
                let borderWidth: CGFloat
                let hoverShadowBoost: Double
            }

            let defaultPadding: CGFloat
            let standard: Variant
            let prominent: Variant
            let subtle: Variant

            static let defaults = CardSurface(
                defaultPadding: 14,
                standard: Variant(
                    borderOpacity: 0.28,
                    hoverBorderOpacity: 0.5,
                    borderWidth: 1,
                    hoverShadowBoost: 0.12
                ),
                prominent: Variant(
                    borderOpacity: 0.25,
                    hoverBorderOpacity: 0.55,
                    borderWidth: 1.2,
                    hoverShadowBoost: 0.15
                ),
                subtle: Variant(
                    borderOpacity: 0.18,
                    hoverBorderOpacity: 0.32,
                    borderWidth: 0.8,
                    hoverShadowBoost: 0.08
                )
            )
        }

        struct OnboardingSurface {
            struct Landing {
                let contentWidth: CGFloat
                let heroPadding: CGFloat
                let heroIconSize: CGFloat
                let heroIconFrame: CGFloat
                let tileSpacing: CGFloat
                let sectionSpacing: CGFloat
                let heroCornerRadius: CGFloat
            }

            let normalFillOpacity: Double
            let selectedFillOpacity: Double
            let normalBorderOpacity: Double
            let selectedBorderOpacity: Double
            let editorBorderOpacity: Double
            let editorPadding: CGFloat
            let optionPadding: CGFloat
            let compactOptionPadding: CGFloat
            let optionCornerRadius: CGFloat
            let compactOptionCornerRadius: CGFloat
            let editorCornerRadius: CGFloat
            let landing: Landing

            static let standard = OnboardingSurface(
                normalFillOpacity: 0.55,
                selectedFillOpacity: 0.82,
                normalBorderOpacity: 0.32,
                selectedBorderOpacity: 0.45,
                editorBorderOpacity: 0.6,
                editorPadding: 10,
                optionPadding: 12,
                compactOptionPadding: 10,
                optionCornerRadius: 12,
                compactOptionCornerRadius: 10,
                editorCornerRadius: 8,
                landing: Landing(
                    contentWidth: 820,
                    heroPadding: 28,
                    heroIconSize: 48,
                    heroIconFrame: 68,
                    tileSpacing: 12,
                    sectionSpacing: 16,
                    heroCornerRadius: 18
                )
            )
        }

        struct Window {
            let mainMinWidth: CGFloat
            let mainMinHeight: CGFloat
            let onboardingMinWidth: CGFloat
            let onboardingMinHeight: CGFloat

            static let standard = Window(
                mainMinWidth: 800,
                mainMinHeight: 500,
                onboardingMinWidth: 680,
                onboardingMinHeight: 460
            )
        }

        let spacing: Spacing
        let corners: CornerRadius
        let formRow: FormRow
        let pickerControl: PickerControl
        let cardSurface: CardSurface
        let onboardingSurface: OnboardingSurface
        let window: Window
        let cardShadow: Shadow
        let elevatedCardShadow: Shadow
    }

    struct Materials {
        let window: Material
        let sidebar: Material
        let card: Material
        let elevatedCard: Material
        let formRow: Material
        let toolbar: Material
    }

    let palette: Palette
    let tide: TidePalette
    let typography: Typography
    let metrics: Metrics
    let materials: Materials

    static func adaptive(accent: Color, colorScheme: ColorScheme) -> AppTheme {
        switch colorScheme {
        case .light:
            return .light(accent: accent)
        case .dark:
            return .dark(accent: accent)
        @unknown default:
            return .dark(accent: accent)
        }
    }

    /// Light Tide theme shared by the app chrome and existing content surfaces.
    static func light(accent _: Color) -> AppTheme {
        let tide = TidePalette.light
        return AppTheme(
            palette: Palette(
                windowBackground: tide.page,
                contentBackground: tide.bg,
                sidebarBackground: tide.side,
                cardBackground: tide.card,
                elevatedCardBackground: tide.card,
                toolbarBackground: tide.side,

                cardBorder: tide.line,
                separator: tide.line,
                primaryText: tide.text,
                secondaryText: tide.muted,
                tertiaryText: tide.muted.opacity(0.72),
                accent: tide.accent,
                warning: Color(nsColor: .systemOrange),
                success: tide.accent2
            ),
            tide: tide,
            typography: .standard,
            metrics: Metrics(
                spacing: .standard,
                corners: .standard,
                formRow: .standard,
                pickerControl: .standard,
                cardSurface: .defaults,
                onboardingSurface: .standard,
                window: .standard,
                cardShadow: .subtle(color: .black, opacity: 0.18),
                elevatedCardShadow: .subtle(color: .black, opacity: 0.22)
            ),
            materials: Materials(
                window: .thinMaterial,
                sidebar: .ultraThinMaterial,
                card: .thinMaterial,
                elevatedCard: .regularMaterial,
                formRow: .ultraThinMaterial,
                toolbar: .ultraThinMaterial
            )
        )
    }

    /// Dark Tide theme shared by the app chrome and existing content surfaces.
    static func dark(accent _: Color) -> AppTheme {
        let tide = TidePalette.dark
        return AppTheme(
            palette: Palette(
                windowBackground: tide.page,
                contentBackground: tide.bg,
                sidebarBackground: tide.side,
                cardBackground: tide.card,
                elevatedCardBackground: tide.card,
                toolbarBackground: tide.side,

                cardBorder: tide.line,
                separator: tide.line,
                primaryText: tide.text,
                secondaryText: tide.muted,
                tertiaryText: tide.muted.opacity(0.72),
                accent: tide.accent,
                warning: Color(nsColor: .systemOrange),
                success: tide.accent2
            ),
            tide: tide,
            typography: .standard,
            metrics: Metrics(
                spacing: .standard,
                corners: .standard,
                formRow: .standard,
                pickerControl: .standard,
                cardSurface: .defaults,
                onboardingSurface: .standard,
                window: .standard,
                cardShadow: .subtle(color: .black, opacity: 0.70),
                elevatedCardShadow: .subtle(color: .black, opacity: 0.80)
            ),
            materials: Materials(
                window: .thinMaterial,
                sidebar: .ultraThinMaterial,
                card: .thinMaterial,
                elevatedCard: .regularMaterial,
                formRow: .ultraThinMaterial,
                toolbar: .ultraThinMaterial
            )
        )
    }

    static let light = AppTheme.light(accent: .fluidGreen)
    static let dark = AppTheme.dark(accent: .fluidGreen)
}

// MARK: - Helpers
