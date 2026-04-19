import Foundation
import UIKit
import CoreText

public enum TeleXFontPreset: String, CaseIterable {
    case system = "System"
    case tahoma = "Tahoma"
    case verdana = "Verdana"
    case segoeUI = "Segoe UI"
    case comicSans = "Comic Sans"
    case firaCode = "Fira Code"
    case georgia = "Georgia"
    
    public var title: String { return self.rawValue }
    
    public var familyName: String? {
        switch self {
        case .system: return nil
        case .tahoma: return "Verdana" // iOS has 'Verdana' natively which is very similar
        case .verdana: return "Verdana"
        case .segoeUI: return "SegoeUI" // Loaded custom TTF
        case .comicSans: return "ComicNeue-Regular" // Loaded custom TTF
        case .firaCode: return "FiraCodeRoman-Regular" // Loaded custom TTF
        case .georgia: return "Georgia"
        }
    }
}

public final class TeleXFontManager {
    public static let shared = TeleXFontManager()
    
    public var currentPreset: TeleXFontPreset {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "TeleXSelectedFont"),
                  let preset = TeleXFontPreset(rawValue: raw) else {
                return .system
            }
            return preset
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "TeleXSelectedFont")
            // Notify when font is changed if we need soft reloads
        }
    }
    
    private var fontsRegistered = false
    private let lock = NSLock()
    
    public func ensureFontsRegistered() {
        if fontsRegistered { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        if fontsRegistered { return }
        fontsRegistered = true
        
        let fontNames = ["ComicNeue", "FiraCode", "SegoeUI"]
        for name in fontNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    print("Failed to register font: \(name)")
                }
            } else {
                print("Font not found in bundle: \(name).ttf")
            }
        }
    }
    
    public func customFont(size: CGFloat, isBold: Bool, isItalic: Bool) -> UIFont? {
        ensureFontsRegistered()
        
        guard let familyName = currentPreset.familyName else {
            return nil
        }
        
        // Let's create UIFontDescriptor and try to find the specific traits
        let descriptor = UIFontDescriptor(name: familyName, size: size)
        
        // Some custom TTFs might not have explicit Bold/Italic traits correctly mapped,
        // but we'll try to apply symbolic traits anyway.
        var symbolicTraits = descriptor.symbolicTraits
        if isBold { symbolicTraits.insert(.traitBold) }
        if isItalic { symbolicTraits.insert(.traitItalic) }
        
        if let styledDescriptor = descriptor.withSymbolicTraits(symbolicTraits) {
            return UIFont(descriptor: styledDescriptor, size: size)
        }
        
        return UIFont(descriptor: descriptor, size: size)
    }
}
