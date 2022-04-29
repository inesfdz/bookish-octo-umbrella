import Foundation
import NablaUtils

final class ConversationRemoteDataSourceImpl: ConversationRemoteDataSource {
    // MARK: - Internal
    
    func createConversation(completion: @escaping (Result<RemoteConversation, GQLError>) -> Void) -> Cancellable {
        gqlClient.perform(mutation: GQL.CreateConversationMutation()) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(data):
                completion(.success(data.createConversation.conversation.fragments.conversationFragment))
            }
        }
    }
    
    func watchConversations(callback: @escaping (Result<RemoteConversationList, GQLError>) -> Void) -> PaginatedWatcher {
        ConversationListWatcher(
            numberOfItemsPerPage: Constants.numberOfItemsPerPage,
            callback: callback
        )
    }
    
    func subscribeToConversationsEvents(
        callback: @escaping (Result<RemoteConversationsEvent, GQLError>) -> Void
    ) -> Cancellable {
        gqlClient.subscribe(subscription: GQL.ConversationsEventsSubscription()) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                callback(.failure(error))
            case let .success(data):
                guard let event = data.conversations?.event else { return }
                self.handleConversationsEvent(event)
                callback(.success(event))
            }
        }
    }
    
    // MARK: - Private
    
    private enum Constants {
        static let numberOfItemsPerPage = 50
        static let conversationsRootQuery = GQL.GetConversationsQuery(
            page: .init(cursor: nil, numberOfItems: numberOfItemsPerPage)
        )
    }
    
    @Inject private var gqlClient: GQLClient
    @Inject private var gqlStore: GQLStore
    
    private func handleConversationsEvent(_ event: RemoteConversationsEvent) {
        if let conversationCreatedEvent = event.asConversationCreatedEvent {
            appendToCache(
                conversation: conversationCreatedEvent.conversation.fragments.conversationFragment
            )
        } else if let conversationDeletedEvent = event.asConversationDeletedEvent {
            removeFromCache(conversationId: conversationDeletedEvent.conversationId)
        }
    }
    
    private func appendToCache(conversation: GQL.ConversationFragment) {
        gqlStore.updateCache(
            for: Constants.conversationsRootQuery,
            onlyIfExists: true,
            body: { cache in
                cache.conversations.conversations.append(.init(unsafeResultMap: conversation.resultMap))
            },
            completion: { _ in }
        )
    }
    
    private func removeFromCache(conversationId: UUID) {
        gqlStore.updateCache(
            for: Constants.conversationsRootQuery,
            onlyIfExists: true,
            body: { cache in
                cache.conversations.conversations.removeAll(where: { $0.fragments.conversationFragment.id == conversationId })
            },
            completion: { _ in }
        )
    }
}

extension GQL.GetConversationsQuery: PaginatedQuery {
    static func getCursor(from data: Data) -> String? {
        data.conversations.nextCursor
    }
}

private class ConversationListWatcher: GQLPaginatedWatcher<GQL.GetConversationsQuery> {
    // MARK: - Initializer
    
    override func makeQuery(page: GQL.OpaqueCursorPage) -> GQL.GetConversationsQuery {
        GQL.GetConversationsQuery(page: page)
    }
    
    override func updateCache(_ cache: inout RemoteConversationList, withAdditionalData data: RemoteConversationList) {
        cache.conversations.conversations.append(contentsOf: data.conversations.conversations)
        cache.conversations.hasMore = data.conversations.hasMore
        cache.conversations.nextCursor = data.conversations.nextCursor
    }
}