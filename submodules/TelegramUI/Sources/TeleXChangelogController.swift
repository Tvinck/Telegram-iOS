import Foundation
import UIKit
import Display
import AsyncDisplayKit

public struct TeleXVersionInfo {
    public let version: String
    public let changes: [String]
}

public final class TeleXChangelogData {
    public static let currentVersion = "1.1.0"
    
    public static let versions: [TeleXVersionInfo] = [
        TeleXVersionInfo(version: "1.1.0", changes: [
            "🎵 Добавлен ранний прототип ТелеX Музыки",
            "🛡 Подготовлен фундамент для встроенного Viel VPN",
            "🎨 Расширена система переключения тем (ВК / Аська)",
            "📋 Добавлен этот список версий (Changelog)"
        ]),
        TeleXVersionInfo(version: "1.0.0", changes: [
            "🟢 Полностью переработан UI в стиле ICQ (Аська)",
            "🔤 Добавлена поддержка кастомных шрифтов (Tahoma, Comic Sans)",
            "🚀 Релиз первой стабильной iOS-сборки TeleX"
        ])
    ]
}

public final class TeleXChangelogController: ViewController {
    private let tableNode: ASTableNode
    
    public override init(navigationBarPresentationData: NavigationBarPresentationData?) {
        self.tableNode = ASTableNode()
        super.init(navigationBarPresentationData: navigationBarPresentationData)
        
        self.title = "Версии TeleX"
        self.statusBar.statusBarStyle = .Black
        self.navigationPresentation = .default
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        
        self.displayNode.backgroundColor = .white
        
        // Let's create a huge scroll view with native labels for simplicity in testing
        let scrollView = UIScrollView(frame: self.displayNode.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        var currentY: CGFloat = 20.0
        
        for v in TeleXChangelogData.versions {
            let versionLabel = UILabel(frame: CGRect(x: 20, y: currentY, width: self.displayNode.bounds.width - 40, height: 30))
            versionLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            versionLabel.text = "Версия \(v.version)"
            scrollView.addSubview(versionLabel)
            
            currentY += 40
            
            for change in v.changes {
                let changeLabel = UILabel()
                changeLabel.numberOfLines = 0
                changeLabel.font = UIFont.systemFont(ofSize: 16)
                changeLabel.text = "• \(change)"
                
                let size = changeLabel.sizeThatFits(CGSize(width: self.displayNode.bounds.width - 40, height: CGFloat.greatestFiniteMagnitude))
                changeLabel.frame = CGRect(x: 20, y: currentY, width: self.displayNode.bounds.width - 40, height: size.height)
                
                scrollView.addSubview(changeLabel)
                currentY += size.height + 10
            }
            
            currentY += 20
        }
        
        scrollView.contentSize = CGSize(width: self.displayNode.bounds.width, height: currentY + 50)
        self.displayNode.view.addSubview(scrollView)
    }
}
