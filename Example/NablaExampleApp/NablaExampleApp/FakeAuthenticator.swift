import Foundation
import NablaCore

class FakeAuthenticator: SessionTokenProvider {
    static let shared = FakeAuthenticator()
    
    func provideTokens(forUserId _: UUID, completion: (Tokens?) -> Void) {
        // Emulate a call to authenticate the user on your server
        // In your app, you need to replace this with an actual call to your backend to get fresh tokens
        completion(.init(
            accessToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIwNWUzM2FmMC02M2I1LTRlZDctOWIxMi00ZDcxOGE4YmI3NWMiLCJpc3MiOiJwcm9kLXBhdGllbnQiLCJ0eXAiOiJCZWFyZXIiLCJleHAiOjE2NTcwMjM2MTQsInNlc3Npb25fdXVpZCI6IjIzZjA4OGY0LTQ3MzgtNGQyYi1iMzUzLTdiYzcwYjA0ZmViMyIsIm9yZ2FuaXphdGlvblN0cmluZ0lkIjoiaGlubGFiMyJ9.cemYBBwW3K11PM03LzDyYF3eUkT_g7-9nQPWsh6o3Ec",
            refreshToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIwNWUzM2FmMC02M2I1LTRlZDctOWIxMi00ZDcxOGE4YmI3NWMiLCJpc3MiOiJwcm9kLXBhdGllbnQiLCJ0eXAiOiJSZWZyZXNoIiwiZXhwIjoxNjY0Nzk5MzE0LCJzZXNzaW9uX3V1aWQiOiIyM2YwODhmNC00NzM4LTRkMmItYjM1My03YmM3MGIwNGZlYjMiLCJvcmdhbml6YXRpb25TdHJpbmdJZCI6ImhpbmxhYjMifQ.uU3aHMNFKAWv3fBYS7AsO_KSv_Mdu3cH4dzZvPsOA0E"
        ))
    }
}
