import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AVFoundation

public final class TeleXMusicController: ViewController {
    private var player: AVPlayer?
    private let playPauseButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    
    // LoFi Girl stream directly for basic listening tests
    // A classic free web stream or basic sample mp3
    private let streamUrl = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!
    
    public override init(navigationBarPresentationData: NavigationBarPresentationData?) {
        super.init(navigationBarPresentationData: navigationBarPresentationData)
        
        self.title = "🎵 Музыка (Бета)"
        self.statusBar.statusBarStyle = .Black
        self.navigationPresentation = .default
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        
        // Match the background to current theme context (for now, default VKish white)
        self.displayNode.backgroundColor = UIColor(rgb: 0xF0F2F5) // VK standard background
        
        setupUI()
        setupPlayer()
    }
    
    private func setupUI() {
        let view = self.displayNode.view
        
        // Title Label
        titleLabel.text = "SoundHelix (Стриминг)"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: 20, y: 150, width: view.bounds.width - 40, height: 40)
        titleLabel.textColor = .black
        view.addSubview(titleLabel)
        
        // Status Label
        statusLabel.text = "Готово к воспроизведению. Кэш: 0 MB"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .gray
        statusLabel.frame = CGRect(x: 20, y: 190, width: view.bounds.width - 40, height: 30)
        view.addSubview(statusLabel)
        
        // Play button
        playPauseButton.setTitle("▶ Играть сейчас (Стрим)", for: .normal)
        playPauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        playPauseButton.frame = CGRect(x: (view.bounds.width - 250) / 2, y: 250, width: 250, height: 50)
        playPauseButton.backgroundColor = UIColor(rgb: 0x5181b8) // VK Blue
        playPauseButton.setTitleColor(.white, for: .normal)
        playPauseButton.layer.cornerRadius = 10
        playPauseButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        view.addSubview(playPauseButton)
        
        // Disclaimer below
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "Данный трек стримится прямо в оперативную память. Он не сохранится на телефон и исчезнет после закрытия плеера."
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.font = UIFont.systemFont(ofSize: 14)
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.textColor = .darkGray
        disclaimerLabel.frame = CGRect(x: 40, y: 320, width: view.bounds.width - 80, height: 80)
        view.addSubview(disclaimerLabel)
    }
    
    private func setupPlayer() {
        // Prepare global audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
        
        // Initialize player item (streaming direct from URL)
        let playerItem = AVPlayerItem(url: streamUrl)
        player = AVPlayer(playerItem: playerItem)
    }
    
    @objc private func togglePlayback() {
        guard let player = player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.setTitle("▶ Слушать", for: .normal)
            statusLabel.text = "Пауза"
        } else {
            player.play()
            playPauseButton.setTitle("⏸ Пауза", for: .normal)
            statusLabel.text = "Буферизация и воспроизведение... (Стриминг)"
        }
    }
}
