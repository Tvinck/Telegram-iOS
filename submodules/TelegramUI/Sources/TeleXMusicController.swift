import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import TelegramPresentationData
import PeerMessagesMediaPlaylist

// MARK: - TeleX Music Controller
// Full rewrite: Uses Telegram's native SharedMediaPlayer system
// instead of raw AVPlayer. Displays tracks from Telegram channels
// and plays them through the built-in overlay player.

public final class TeleXMusicController: ViewController {
    private let context: AccountContext
    
    // Data
    private var songs: [TeleXSongItem] = []
    private var isLoading = true
    private var searchQuery: String = ""
    
    // UI
    private var tableView: UITableView!
    private var searchBar: UISearchBar!
    private var emptyLabel: UILabel!
    private var loadingIndicator: UIActivityIndicatorView!
    private var headerView: UIView!
    
    // Disposables
    private let searchDisposable = MetaDisposable()
    private let disposableSet = DisposableSet()
    
    public init(context: AccountContext) {
        self.context = context
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(
            presentationData: presentationData
        ))
        
        self.title = "🎵 TeleX Музыка"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Кэш",
            style: .plain,
            target: self,
            action: #selector(showCacheInfo)
        )
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.searchDisposable.dispose()
        self.disposableSet.dispose()
    }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        self.displayNode.backgroundColor = presentationData.theme.list.plainBackgroundColor
        
        setupSearchBar()
        setupTableView()
        setupEmptyState()
        setupLoadingIndicator()
        
        // Initial load — search all music in user's Telegram
        performSearch(query: "")
    }
    
    // MARK: - UI Setup
    
    private func setupSearchBar() {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        
        searchBar = UISearchBar()
        searchBar.placeholder = "Поиск музыки в Telegram..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = presentationData.theme.list.plainBackgroundColor
        searchBar.tintColor = presentationData.theme.list.itemAccentColor
        
        // Style the text field
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = presentationData.theme.list.itemPrimaryTextColor
            textField.backgroundColor = presentationData.theme.list.itemBlocksBackgroundColor
        }
        
        searchBar.frame = CGRect(x: 0, y: 0, width: self.displayNode.bounds.width, height: 56)
        searchBar.autoresizingMask = [.flexibleWidth]
        self.displayNode.view.addSubview(searchBar)
    }
    
    private func setupTableView() {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TeleXSongCell.self, forCellReuseIdentifier: "SongCell")
        tableView.backgroundColor = presentationData.theme.list.plainBackgroundColor
        tableView.separatorColor = presentationData.theme.list.itemPlainSeparatorColor
        tableView.rowHeight = 64
        tableView.keyboardDismissMode = .onDrag
        
        let topOffset: CGFloat = 56
        tableView.frame = CGRect(
            x: 0,
            y: topOffset,
            width: self.displayNode.bounds.width,
            height: self.displayNode.bounds.height - topOffset
        )
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.displayNode.view.addSubview(tableView)
    }
    
    private func setupEmptyState() {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        
        emptyLabel = UILabel()
        emptyLabel.text = "Музыка не найдена\n\nОтправьте аудиофайл в любой чат\nили подпишитесь на музыкальный канал"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 16)
        emptyLabel.textColor = presentationData.theme.list.itemSecondaryTextColor
        emptyLabel.frame = CGRect(x: 40, y: 200, width: self.displayNode.bounds.width - 80, height: 120)
        emptyLabel.autoresizingMask = [.flexibleWidth]
        emptyLabel.isHidden = true
        self.displayNode.view.addSubview(emptyLabel)
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = CGPoint(x: self.displayNode.bounds.width / 2, y: 250)
        loadingIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        loadingIndicator.hidesWhenStopped = true
        self.displayNode.view.addSubview(loadingIndicator)
    }
    
    // MARK: - Search
    
    private func performSearch(query: String) {
        self.isLoading = true
        self.loadingIndicator.startAnimating()
        self.emptyLabel.isHidden = true
        self.tableView.reloadData()
        
        let signal = self.context.engine.messages.searchMessages(
            location: .general(scope: .everywhere, tags: .music, minDate: nil, maxDate: nil, folderId: nil),
            query: query,
            state: nil,
            limit: 200
        )
        
        self.searchDisposable.set((signal
            |> deliverOnMainQueue).start(next: { [weak self] result, _ in
                guard let strongSelf = self else { return }
                
                var items: [TeleXSongItem] = []
                
                for message in result.messages {
                    guard let file = message.media.first(where: { $0 is TelegramMediaFile }) as? TelegramMediaFile else {
                        continue
                    }
                    
                    var title = ""
                    var artist = ""
                    var duration: Int32 = 0
                    
                    for attribute in file.attributes {
                        if case let .Audio(isVoice, durationValue, titleValue, performerValue, _) = attribute {
                            if isVoice { continue }
                            duration = Int32(durationValue)
                            title = titleValue ?? ""
                            artist = performerValue ?? ""
                        }
                    }
                    
                    // Fallback to filename
                    if title.isEmpty {
                        title = file.fileName ?? "Без названия"
                    }
                    if artist.isEmpty {
                        // Use chat/channel name as artist
                        if let peer = message.peers[message.id.peerId] {
                            artist = EnginePeer(peer).displayTitle(strings: strongSelf.context.sharedContext.currentPresentationData.with { $0 }.strings, displayOrder: .firstLast)
                        } else {
                            artist = "Неизвестный"
                        }
                    }
                    
                    let item = TeleXSongItem(
                        message: message,
                        file: file,
                        title: title,
                        artist: artist,
                        duration: duration
                    )
                    items.append(item)
                }
                
                strongSelf.songs = items
                strongSelf.isLoading = false
                strongSelf.loadingIndicator.stopAnimating()
                strongSelf.emptyLabel.isHidden = !items.isEmpty
                strongSelf.tableView.reloadData()
            }))
    }
    
    // MARK: - Playback (Native Telegram Player)
    
    private func playSong(at index: Int) {
        guard index < self.songs.count else { return }
        
        let selectedSong = self.songs[index]
        let allMessages = self.songs.map { $0.message }
        
        // Create a Signal with our messages list
        let messagesSignal: Signal<([Message], Int32, Bool), NoError> = .single((allMessages, Int32(allMessages.count), false))
        
        // Use Telegram's native custom playlist location
        let playlistLocation = PeerMessagesPlaylistLocation.custom(
            messages: messagesSignal,
            canReorder: false,
            at: selectedSong.message.id,
            loadMore: nil,
            hidePanel: false
        )
        
        // Create playlist and hand off to Telegram's MediaManager
        let playlist = PeerMessagesMediaPlaylist(
            context: self.context,
            location: playlistLocation,
            chatLocationContextHolder: nil
        )
        
        // This triggers Telegram's built-in overlay player with:
        // - Mini-player bar at the top of chats
        // - Control Center / Lock Screen controls
        // - Next/Previous/Seek
        // - Background audio
        self.context.sharedContext.mediaManager.setPlaylist(
            (self.context, playlist),
            type: .music,
            control: .playback(.play)
        )
    }
    
    // MARK: - Actions
    
    @objc private func showCacheInfo() {
        let cacheSize = getCacheSize()
        let alert = UIAlertController(
            title: "Кэш музыки",
            message: "Размер: \(cacheSize)\n\nМузыка кэшируется автоматически при прослушивании.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Очистить кэш", style: .destructive, handler: { [weak self] _ in
            self?.clearCache()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true)
    }
    
    private func getCacheSize() -> String {
        // Telegram caches media automatically in its mediaBox
        // This is a simplified display
        let byteCount = self.songs.reduce(Int64(0)) { total, song in
            return total + (song.file.size ?? 0)
        }
        return ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
    
    private func clearCache() {
        // Clear Telegram's media cache for audio files
        let resourceIds = Set(self.songs.map { $0.file.resource.id })
        let _ = (self.context.engine.resources.clearCachedMediaResources(mediaResourceIds: resourceIds)
        |> deliverOnMainQueue).start(completed: { [weak self] in
            guard let strongSelf = self else { return }
            let alert = UIAlertController(
                title: "Готово",
                message: "Кэш музыки очищен",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            strongSelf.present(alert, animated: true)
        })
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        let topOffset: CGFloat = 56
        self.searchBar.frame = CGRect(x: 0, y: 0, width: layout.size.width, height: topOffset)
        self.tableView.frame = CGRect(x: 0, y: topOffset, width: layout.size.width, height: layout.size.height - topOffset)
        self.emptyLabel.frame = CGRect(x: 40, y: 200, width: layout.size.width - 80, height: 120)
        self.loadingIndicator.center = CGPoint(x: layout.size.width / 2, y: 250)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension TeleXMusicController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! TeleXSongCell
        let song = self.songs[indexPath.row]
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        cell.configure(song: song, presentationData: presentationData, index: indexPath.row + 1)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.playSong(at: indexPath.row)
    }
}

// MARK: - UISearchBarDelegate

extension TeleXMusicController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Debounce search
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(executeSearch), object: nil)
        self.searchQuery = searchText
        self.perform(#selector(executeSearch), with: nil, afterDelay: 0.5)
    }
    
    @objc private func executeSearch() {
        performSearch(query: self.searchQuery)
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch(query: searchBar.text ?? "")
    }
}

// MARK: - Data Model

struct TeleXSongItem {
    let message: Message
    let file: TelegramMediaFile
    let title: String
    let artist: String
    let duration: Int32
}

// MARK: - Song Cell

final class TeleXSongCell: UITableViewCell {
    private let indexLabel = UILabel()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let durationLabel = UILabel()
    private let musicIcon = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        // Music icon
        musicIcon.font = UIFont.systemFont(ofSize: 28)
        musicIcon.text = "🎵"
        musicIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(musicIcon)
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(titleLabel)
        
        // Artist
        artistLabel.font = UIFont.systemFont(ofSize: 13)
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(artistLabel)
        
        // Duration
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        durationLabel.textAlignment = .right
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            musicIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            musicIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            musicIcon.widthAnchor.constraint(equalToConstant: 36),
            
            titleLabel.leadingAnchor.constraint(equalTo: musicIcon.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    func configure(song: TeleXSongItem, presentationData: PresentationData, index: Int) {
        titleLabel.text = song.title
        artistLabel.text = song.artist
        durationLabel.text = formatDuration(song.duration)
        
        // Theme colors
        backgroundColor = presentationData.theme.list.plainBackgroundColor
        titleLabel.textColor = presentationData.theme.list.itemPrimaryTextColor
        artistLabel.textColor = presentationData.theme.list.itemSecondaryTextColor
        durationLabel.textColor = presentationData.theme.list.itemSecondaryTextColor
    }
    
    private func formatDuration(_ seconds: Int32) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
