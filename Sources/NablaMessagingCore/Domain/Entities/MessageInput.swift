import Foundation

/// Representation of a message to give to ``NablaClient.shared().sendMessage``
/// The text will be send directly to the API, whereas medias are first uploaded then the ID is sent to the API.
/// There's a possibility of error if the ``Media.fileUrl`` points to nothing accessible at the moment
/// of upload, resulting of ``ConversationMessage.sendingState`` set to ``ConversationMessageSendingState.failed``
public enum MessageInput {
    case text(content: String)
    case image(content: Media)
    case document(content: Media)
}
