import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext

public struct Song: Equatable {
    public let id: MessageId
    public let title: String
    public let artist: String
    public let duration: Int32
    public let message: Message
    
    public init(id: MessageId, title: String, artist: String, duration: Int32, message: Message) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.message = message
    }
}

public class TeleXMusicLibraryManager {
    private let engine: TelegramEngine
    private let disposable = MetaDisposable()
    
    public private(set) var musicList: [Song] = []
    
    public init(engine: TelegramEngine) {
        self.engine = engine
        self.loadMusic()
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    private func loadMusic() {
        let signal = self.engine.messages.searchMessages(
            location: .general(scope: .everywhere, tags: .music, minDate: nil, maxDate: nil, folderId: nil),
            query: "",
            state: nil,
            limit: 1000
        )
        
        self.disposable.set(signal.start(next: { [weak self] (result, _) in
            guard let strongSelf = self else { return }
            var songs: [Song] = []
            
            for message in result.messages {
                if let file = message.media.first(where: { $0 is TelegramMediaFile }) as? TelegramMediaFile {
                    var title = "Unknown Title"
                    var artist = "Unknown Artist"
                    var duration: Int32 = 0
                    var foundFileName: String?
                    
                    for attribute in file.attributes {
                        if case let .Audio(_, durationValue, titleValue, performerValue, _) = attribute {
                            duration = Int32(durationValue)
                            if let t = titleValue, !t.isEmpty { title = t }
                            if let p = performerValue, !p.isEmpty { artist = p }
                        }
                        if case let .FileName(fileNameValue) = attribute {
                            foundFileName = fileNameValue
                        }
                    }
                    
                    if title == "Unknown Title", let fName = foundFileName {
                        title = fName
                    }
                    
                    let song = Song(id: message.id, title: title, artist: artist, duration: duration, message: message)
                    songs.append(song)
                }
            }
            
            strongSelf.musicList = songs
        }))
    }
}
