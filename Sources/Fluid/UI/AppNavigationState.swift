//
//  AppNavigationState.swift
//  fluid
//
//  Navigation state shared by the main app and settings sidebars.
//

import Foundation

enum SidebarItem: Hashable {
    case home
    case welcome
    case voiceEngine
    case aiEnhancements
    case cleanupStyles
    case meetingTools
    case customDictionary
    case stats
    case history
    case changelog
    case feedback
    case commandMode
    case rewriteMode
    case settings(SettingsSection)

    /// Stats is folded into Tide Home. Keep the legacy case as a migration target
    /// for callers that still ask for the retired destination.
    var tideDestination: SidebarItem {
        self == .stats ? .home : self
    }

    var settingsSection: SettingsSection? {
        guard case let .settings(section) = self else { return nil }
        return section
    }
}

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case dictation
    case notifications
    case audio
    case overlay
    case dataAndDiagnostics
    case experimental

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .general: return "General"
        case .dictation: return "Shortcuts"
        case .notifications: return "Notifications"
        case .audio: return "Audio"
        case .overlay: return "Overlay"
        case .dataAndDiagnostics: return "Data & Privacy"
        case .experimental: return "Experimental"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .dictation: return "keyboard"
        case .notifications: return "bell"
        case .audio: return "speaker.wave.2"
        case .overlay: return "rectangle.on.rectangle"
        case .dataAndDiagnostics: return "wrench.and.screwdriver"
        case .experimental: return "flask"
        }
    }
}

struct SettingsNavigationState: Equatable {
    var selectedSection: SettingsSection?
    private(set) var returnDestination: SidebarItem = .home

    var isPresented: Bool {
        self.selectedSection != nil
    }

    func isLeaving(_ section: SettingsSection, for destination: SettingsSection?) -> Bool {
        self.selectedSection == section && destination != section
    }

    mutating func present(_ section: SettingsSection, returningTo currentDestination: SidebarItem?) {
        if !self.isPresented {
            self.returnDestination = currentDestination?.tideDestination ?? .home
        }
        self.selectedSection = section
    }

    mutating func dismiss() -> SidebarItem {
        self.selectedSection = nil
        return self.returnDestination
    }

    mutating func leaveForApp() {
        self.selectedSection = nil
    }
}
