import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramUIPreferences
import AccountContext

// MARK: - TeleX Theme Manager

final class TeleXThemeManager {
    static let shared = TeleXThemeManager()
    
    private let selectedThemeKey = "TeleXSelectedTheme"
    
    private init() {}
    
    // MARK: - Current Theme
    
    var currentPreset: TeleXThemePreset {
        get {
            guard let raw = UserDefaults.standard.string(forKey: selectedThemeKey),
                  let preset = TeleXThemePreset(rawValue: raw) else {
                return .original
            }
            return preset
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedThemeKey)
        }
    }
    
    // MARK: - Apply Theme
    
    func applyTheme(preset: TeleXThemePreset, context: AccountContext) {
        self.currentPreset = preset
        
        let _ = updatePresentationThemeSettingsInteractively(
            accountManager: context.sharedContext.accountManager
        ) { settings in
            let themeRef = settings.theme
            var accentColors = settings.themeSpecificAccentColors
            var wallpapers = settings.themeSpecificChatWallpapers
            
            switch preset {
            case .original:
                // Remove custom overrides — restore Telegram defaults
                accentColors.removeValue(forKey: themeRef.index)
                wallpapers.removeValue(forKey: themeRef.index)
                
            case .icq, .vk:
                // Apply custom accent color + bubble colors
                let accentColor = PresentationThemeAccentColor(
                    index: preset == .icq ? 100 : 101,
                    baseColor: .custom,
                    accentColor: preset.accentColorRGB,
                    bubbleColors: preset.bubbleColors
                )
                accentColors[themeRef.index] = accentColor
                
                // Apply solid color wallpaper
                if let wpColor = preset.wallpaperColor {
                    wallpapers[themeRef.index] = .color(wpColor)
                    
                    // Also apply for colored theme index
                    let coloredIndex = coloredThemeIndex(reference: themeRef, accentColor: accentColor)
                    wallpapers[coloredIndex] = .color(wpColor)
                }
            }
            
            return settings
                .withUpdatedThemeSpecificAccentColors(accentColors)
                .withUpdatedThemeSpecificChatWallpapers(wallpapers)
        }.start()
}
