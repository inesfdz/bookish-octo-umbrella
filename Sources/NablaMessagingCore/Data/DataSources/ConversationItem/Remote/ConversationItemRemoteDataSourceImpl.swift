import Foundation
import NablaUtils

class ConversationItemRemoteDataSourceImpl: ConversationItemRemoteDataSource {
    // MARK: - Internal
    
    func watchConversationItems(
        ofConversationWithId conversationId: UUID,
        callback: @escaping (Result<RemoteConversationWithItems, GQLError>) -> Void
    ) -> PaginatedWatcher {
        ConversationItemsWatcher(
            conversationId: conversationId,
            numberOfItemsPerPage: Constants.numberOfItemsPerPage,
            callback: callback
        )
    }
    
    func send(
        localMessageClientId: UUID,
        remoteMessageInput: GQL.SendMessageContentInput,
        conversationId: UUID,
        callback: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable {
        gqlClient.perform(
            mutation: GQL.SendMessageMutation(
                conversationId: conversationId,
                content: remoteMessageInput,
                clientId: localMessageClientId
            ),
            completion: { result in
                callback(result.map { _ in () }.mapError { $0 as Error })
            }
        )
    }
    
    func delete(messageId: UUID, callback: @escaping (Result<Void, Error>) -> Void) -> Cancellable {
        gqlClient.perform(
            mutation: GQL.DeleteMessageMutation(messageId: messageId),
            completion: { result in
                switch result {
                case let .failure(error): callback(.failure(error))
                case .success: callback(.success(()))
                }
            }
        )
    }
    
    func subscribeToConversationItemsEvents(
        ofConversationWithId conversationId: UUID,
        callback: @escaping (Result<RemoteConversationEvent, GQLError>) -> Void
    ) -> Cancellable {
        gqlClient.subscribe(subscription: GQL.ConversationEventsSubscription(id: conversationId)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                callback(.failure(error))
            case let .success(data):
                guard let event = data.conversation?.event else { return }
                self.handleConversationEvent(event, inConversationWithId: conversationId)
                callback(.success(event))
            }
        }
    }
    
    func setIsTyping(_ isTyping: Bool, conversationId: UUID) -> Cancellable {
        gqlClient.perform(
            mutation: GQL.SetTypingMutation(conversationId: conversationId, isTyping: isTyping),
            completion: { _ in }
        )
    }
    
    func markConversationAsSeen(conversationId: UUID) -> Cancellable {
        gqlClient.perform(
            mutation: GQL.MaskAsSeenMutation(conversationId: conversationId),
            completion: { _ in }
        )
    }
    
    // MARK: - Private
    
    @Inject private var gqlClient: GQLClient
    @Inject private var gqlStore: GQLStore
    
    private enum Constants {
        static let numberOfItemsPerPage = 50
        
        static func rootQuery(conversationId: UUID) -> GQL.GetConversationItemsQuery {
            .init(id: conversationId, page: .init(cursor: nil, numberOfItems: numberOfItemsPerPage))
        }
    }
    
    private func handleConversationEvent(_ event: RemoteConversationEvent, inConversationWithId conversationId: UUID) {
        if let messageCreatedEvent = event.asMessageCreatedEvent {
            append(
                message: messageCreatedEvent.message.fragments.messageFragment,
                toCacheOfConversationWithId: conversationId
            )
        } else if let typingEvent = event.asTypingEvent {
            update(
                provider: typingEvent.provider.fragments.providerInConversationFragment,
                inCacheOfConversationWithId: conversationId
            )
        }
    }
    
    private func append(message: GQL.MessageFragment, toCacheOfConversationWithId conversationId: UUID) {
        gqlStore.updateCache(
            for: Constants.rootQuery(conversationId: conversationId),
            onlyIfExists: true,
            body: { cache in
                let isAlreadyInConversation = cache.conversation.conversation.items.data.contains(
                    where: { $0?.fragments.conversationItemFragment.fragments.messageFragment.id == message.id }
                )
                if !isAlreadyInConversation {
                    cache.conversation.conversation.items.data.append(.init(unsafeResultMap: message.resultMap))
                }
            },
            completion: { _ in }
        )
    }
    
    private func update(provider: GQL.ProviderInConversationFragment, inCacheOfConversationWithId conversationId: UUID) {
        gqlStore.updateCache(
            for: Constants.rootQuery(conversationId: conversationId),
            onlyIfExists: true,
            body: { cache in
                let isAlreadyInConversation = cache.conversation.conversation.providers.contains(where: { $0.fragments.providerInConversationFragment.id == provider.id })
                if !isAlreadyInConversation {
                    cache.conversation.conversation.providers.append(.init(unsafeResultMap: provider.resultMap))
                }
            },
            completion: { _ in }
        )
    }
}

extension GQL.GetConversationItemsQuery: PaginatedQuery {
    static func getCursor(from data: Data) -> String? {
        data.conversation.conversation.items.nextCursor
    }
}

private class ConversationItemsWatcher: GQLPaginatedWatcher<GQL.GetConversationItemsQuery> {
    init(
        conversationId: UUID,
        numberOfItemsPerPage: Int,
        callback: @escaping (Result<RemoteConversationWithItems, GQLError>) -> Void
    ) {
        self.conversationId = conversationId
        super.init(
            numberOfItemsPerPage: numberOfItemsPerPage,
            callback: callback
        )
    }
    
    override func makeQuery(page: GQL.OpaqueCursorPage) -> GQL.GetConversationItemsQuery {
        GQL.GetConversationItemsQuery(id: conversationId, page: page)
    }
    
    override func updateCache(_ cache: inout RemoteConversationWithItems, withAdditionalData data: RemoteConversationWithItems) {
        let existingIds = Set(cache.conversation.conversation.items.data.compactMap {
            $0?.fragments.conversationItemFragment.fragments.messageFragment.id
        })
        let newItems = data.conversation.conversation.items.data.filter { maybeItem in
            guard let item = maybeItem else { return false }
            if existingIds.contains(item.fragments.conversationItemFragment.fragments.messageFragment.id) {
                logger.warning(message: "Found duplicated item when loading more: \(item)")
                return false
            }
            return true
        }
        cache.conversation.conversation.items.data.append(contentsOf: newItems)
        cache.conversation.conversation.items.hasMore = data.conversation.conversation.items.hasMore
        cache.conversation.conversation.items.nextCursor = data.conversation.conversation.items.nextCursor
    }
    
    // MARK: - Private
    
    @Inject private var logger: Logger
    
    private let conversationId: UUID
}