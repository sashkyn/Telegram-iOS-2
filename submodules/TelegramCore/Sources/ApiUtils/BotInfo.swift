import Foundation
import Postbox
import TelegramApi

extension BotMenuButton {
    init(apiBotMenuButton: Api.BotMenuButton) {
        switch apiBotMenuButton {
            case .botMenuButtonCommands, .botMenuButtonDefault:
                self = .commands
            case let .botMenuButton(text, url):
                self = .webView(text: text, url: url)
        }
    }
}

extension BotInfo {
    convenience init(apiBotInfo: Api.BotInfo) {
        switch apiBotInfo {
            case let .botInfo(_, _, description, descriptionPhoto, descriptionDocument, apiCommands, apiMenuButton):
                let photo: TelegramMediaImage? = descriptionPhoto.flatMap(telegramMediaImageFromApiPhoto)
                let video: TelegramMediaFile? = descriptionDocument.flatMap(telegramMediaFileFromApiDocument)
                var commands: [BotCommand] = []
                if let apiCommands = apiCommands {
                    commands = apiCommands.map { command in
                        switch command {
                            case let .botCommand(command, description):
                                return BotCommand(text: command, description: description)
                        }
                    }
                }
                var menuButton: BotMenuButton = .commands
                if let apiMenuButton = apiMenuButton {
                    menuButton = BotMenuButton(apiBotMenuButton: apiMenuButton)
                }
                self.init(description: description ?? "", photo: photo, video: video, commands: commands, menuButton: menuButton)
        }
    }
}

// HINT: волшебный синглтон

public final class ContestHelper {
    
    public static var shared = ContestHelper()
    
    public var isUserLeaveChatListScroll: Bool = true
    
    public var needToShowArchiveInChat: Bool = false
    
    public var chatItemHeight: CGFloat = 80.0
    
    public func didStartScrollChatList() {
        isUserLeaveChatListScroll = false
        debug("didStartScrollChatList")
    }
    
    public func didUserLeaveChatListScroll() {
        isUserLeaveChatListScroll = true
        debug("didUserLeaveChatListScroll")
    }
    
    public func debug(_ text: String) {
        print("ContestHelper: debug - \(text)")
    }
}
