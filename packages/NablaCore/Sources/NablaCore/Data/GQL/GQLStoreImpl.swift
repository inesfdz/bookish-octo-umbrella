import Apollo
import Foundation

class GQLStoreImpl: GQLStore {
    // MARK: - Internal
    
    func createCache<Q: GraphQLQuery>(
        for query: Q,
        data: Q.Data,
        completion: @escaping (Result<Void, GQLError.CacheError>) -> Void
    ) {
        apollo.withinReadWriteTransaction(
            _: { transaction in
                try transaction.write(data: data, forQuery: query)
            },
            completion: Self.makeCompletionHandler(completion: completion)
        )
    }
    
    func updateCache<Q: GraphQLQuery>(
        for query: Q,
        onlyIfExists: Bool,
        body: @escaping (inout Q.Data) throws -> Void,
        completion: @escaping (Result<Void, GQLError.CacheError>) -> Void
    ) {
        apollo.withinReadWriteTransaction(
            _: { transaction in
                let cache = try? transaction.read(query: query)
                if cache != nil {
                    try transaction.update(query: query, body)
                } else if onlyIfExists {
                    return // If the cache does not exist, silently return
                } else {
                    throw GQLError.cacheError(.queryNotCached)
                }
            },
            completion: Self.makeCompletionHandler(completion: completion)
        )
    }
    
    func cacheExists<Q: GraphQLQuery>(
        for query: Q,
        completion: @escaping (Result<Bool, GQLError.CacheError>) -> Void
    ) {
        apollo.withinReadWriteTransaction(
            _: { transaction -> Bool in
                let cache = try? transaction.read(query: query)
                return cache != nil
            },
            completion: Self.makeCompletionHandler(completion: completion)
        )
    }
    
    func cacheExists<F: GraphQLFragment>(
        for fragment: F,
        completion: @escaping (Result<Bool, GQLError.CacheError>) -> Void
    ) {
        guard let key = Normalization.cacheKey(for: fragment.jsonObject) else {
            return completion(.failure(.normalizationFailed(object: fragment)))
        }
        
        apollo.withinReadWriteTransaction(
            _: { transaction -> Bool in
                let cache = try? transaction.readObject(ofType: F.self, withKey: key)
                return cache != nil
            },
            completion: Self.makeCompletionHandler(completion: completion)
        )
    }
    
    func clearCache(
        completion: @escaping (Result<Void, GQLError.CacheError>) -> Void
    ) {
        apollo.clearCache(
            completion: Self.makeCompletionHandler(completion: completion)
        )
    }
    
    // MARK: Init
    
    let apollo: ApolloStore
    
    init(
        cache: NormalizedCache = InMemoryNormalizedCache()
    ) {
        apollo = ApolloStore(cache: cache)
    }
    
    // MARK: - Private
    
    private static func makeCompletionHandler<T>(
        completion: @escaping (Result<T, GQLError.CacheError>) -> Void
    ) -> (Result<T, Error>) -> Void {
        { result in
            switch result {
            case let .failure(error):
                let gqlError = parseApolloError(error)
                completion(.failure(gqlError))
            case let .success(data):
                completion(.success(data))
            }
        }
    }
    
    private static func parseApolloError(_ error: Error) -> GQLError.CacheError {
        if let cacheError = error as? GQLError.CacheError {
            return cacheError
        }
        // TODO: @tgy Handle each Apollo errors individually
        return .unexpectedError
    }
}