import Foundation

protocol ConversationRemoteDataSource {
    func createConversation(
        title: String?,
        providerIdToAssign: UUID?,
        handler: ResultHandler<RemoteConversation, GQLError>
    ) -> Cancellable
    
    func watchConversation(_ conversationId: UUID, handler: ResultHandler<RemoteConversation, GQLError>) -> Cancellable
    
    func watchConversations(handler: ResultHandler<RemoteConversationList, GQLError>) -> PaginatedWatcher
    
    func subscribeToConversationsEvents(
        handler: ResultHandler<RemoteConversationsEvent, GQLError>
    ) -> Cancellable
}
