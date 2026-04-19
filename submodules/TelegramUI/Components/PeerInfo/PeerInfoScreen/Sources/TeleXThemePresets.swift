import Foundation
import UIKit
import TelegramCore
import TelegramUIPreferences

// MARK: - TeleX Theme Preset Definition

enum TeleXThemePreset: String, CaseIterable {
    case original = "original"
    case icq = "icq"
    case vk = "vk"
    
    var displayName: String {
        switch self {
        case .original: return "Оригинал"
        case .icq: return "ICQ"
        case .vk: return "ВКонтакте"
        }
    }
    
    var displayIcon: String {
        switch self {
        case .original: return "💬"
        case .icq: return "🌸"
        case .vk: return "💙"
        }
    }
    
    // MARK: - Color Palettes
    
    /// Main accent color (nav bar tint, links, buttons)
    var accentColorRGB: UInt32 {
        switch self {
        case .original: return 0x2CA5E0  // Telegram blue
        case .icq: return 0x5BA818       // ICQ dark green
        case .vk: return 0x4A76A8        // VK blue
        }
    }
    
    /// Outgoing message bubble colors (top, bottom gradient)
    var bubbleColors: [UInt32] {
        switch self {
        case .original: return []  // Default Telegram green
        case .icq: return [0xDCF8C6, 0xC8E6B0]  // Light green gradient
        case .vk: return [0xCCE4FF, 0xA8D0F5]   // Light blue gradient
        }
    }
    
    /// Chat wallpaper as solid color (nil = keep current)
    var wallpaperColor: UInt32? {
        switch self {
        case .original: return nil        // Keep default
        case .icq: return 0xFFFFFF        // Pure white (classic ICQ feel)
        case .vk: return 0xEDEEF0         // VK gray background
        }
    }
}
