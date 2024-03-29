# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed


## [1.0.0-alpha08] - 2022-07-04

### Added

- Methods like `watchConversations()`, `watchConverversation()` or `watchItems(ofConversationWithId:)` now return a `Watcher`.
- Using `NablaMessagingUI` will automatically register some `NotificationRefetchTrigger` for `UIApplication.willEnterForegroundNotification`.

### Changed

- `Configuration` has been renamed to `NetworkConfiguration`. This should not have an impact on an existing app as this is supposed to be for internal tests only.
- Added a new `showComposer` parameter to `NablaViewFactory.createConversationViewController` that can be set to false to hide the message composer for the patient.
- `PaginatedWatcher` now returns proper `NablaError` in case of error instead of the basic `Error`.
- Extract `NablaClient` from `NablaMessagingCore` to a new `NablaCore` library.
- Replaced `providerIdToAssign` by a list a `providerIds` in `NablaMessagingClient.createConversation`.

### Fixed


## [1.0.0-alpha07] - 2022-06-24

### Added
- Added `headerTitleFont`, `headerSubtitleFont`, `headerTitleColor` and `headerSubtitleColor` to `NablaTheme.Conversation` to customize the look of the `ConversationViewController` header

### Changed
- Remove the `description` field from `Conversation` and replace it by a `subtitle` that is displayed by the `ConversationViewController`
- `NablaTheme.Conversation.textSeparatorFont` & `NablaTheme.Conversation.textSeparatorColor` have been split into `dateSeparator` & `conversationActivity` items to allow for customization of the 2 elements differently 

### Fixed

- Add default `title` and `providerIdToAssign` arguments to `createConversation()` endpoint. Fixes [#1](https://github.com/nabla/nabla-ios/issues/1).


## [1.0.0-alpha06] - 2022-06-21

### Added

- Added the handle of replies to message, Core & UI.
- Added video messages, Core & UI.
- `NablaViewFactory` can create an `InboxViewController` that adds the button to create conversation and create them.
- Added optional `title` and `providerIdToAssign` arguments to `NablaMessagingClient.createConversation`.

### Changed

- `ConversationViewController` can be used without a `UINavigationController`
- `NablaMessagingClient.sendMessage` now takes an optional parameter `replyToMessageId ` of type `UUID?` which correspond to the message the patient replies to.
- `MimeType` is now split in different types (image, video, audio, document) and fallback on wildcard when receiving an unknown value.
- `NablaClient.initialise` now logs a `warning` log in case of multiple calls instead of a `failure`.

### Fixed

- `ConversationsListView` and `ConversationViewController` now use the device locale to format dates.


## [1.0.0-alpha05] - 2022-06-13

### Added

- Enable use of `NablaViewFactory.createConversationViewController` with the conversation's `UUID` only.
- It is possible to inject a `Logger` into `NablaClient.initialize` to intercept the SDK's logs.

### Changed

- Used `spec.resource_bundles` instead of `spec.resources` for `NablaMessaginUI` podspec.

### Fixed

- New `ConversationActivity` items are now correctly handled when the chat is open.

## [1.0.0-alpha04] - 2022-06-01

### Added

### Changed

- Automatically refreshes expired `accessToken` returned by `SessionTokenProvider.provideTokens`.


### Fixed


## [1.0.0-alpha03] - 2022-06-01

### Added
 - `ConversationActivity` in conversations. A message is displayed when a provider joins a conversation.
 - `ConversationViewController` now displays system messages, with the right name and avatar.
 - The creation of audio messages is now supported. To make it work, you should fill your `info.plist` with the key `NSMicrophoneUsageDescription` with the desired description.

### Changed
- `ConversationMessageSender.sender` now exposes a `SystemProvider` parameter which contains the name of the organization and the avatar url.
- `ConversationMessageSender.system` now exposes a `SystemProvider` parameter which contains the name of the organization and the avatar url.
- `ConversationMessageSender` now exposes a new `.unknown` case for sender types that are not handled by this version of the SDK.
- `NablaTheme` simplified it's internal naming.

### Fixed

## [1.0-alpha02] - 2022-05-19

### Added
- This CHANGELOG file
- `NablaMessagingUI` conversation screen now separates older messages from newer with a date separator
- `NablaMessagingUI` avatar component now displays Provider initials when no avatar picture is available
- `NablaMessagingUI` conversation screen now has an option to copy any text message in the conversation
- Public APIs are now documented in the code, making it available for developers in Xcode
- Started Cocoapods support for SDK integration

### Changed
- `NablaClient` messaging APIs are now a part of `NablaMessagingClient`. Only initialization and authentication are provided by `NablaClient`
- `NablaAuthenticationProvider` has been renamed `SessionTokenProvider`
- `watchConversationList` has been renamed `watchConversations`
- You can now pass your own instance of `NablaMessagingClient` to any UI component of `NablaMessagingUI`
- `NablaClient.authenticate` now requires a `userId` in addition to the `SessionTokenProvider`, this id should be stable if the authenticated user doesn't change
- Some `NablaMessagingUI` strings have been updated
- `Conversation` struct has been revamped and now contains the providers with a proper `ProviderInConversation` struct
- `NablaMessagingClient.watchConversationItems` now returns a `ConversationItems` struct which only contains the messages themselves. Details of the conversation and its participants should now be watched using `NablaMessagingClient.watchConversation`
- Used explicit errors for `NablaMessagingClient` methods

### Fixed
- `NablaMessagingClient` now correctly triggers `watchConversationItems` watcher when a Provider is not typing anymore
- `NablaMessagingUI` conversation screen now correctly adds an image message in the conversation optimistically while sending it to the server
- `NablaMessagingUI` conversation screen now correctly provides an image picker to upload an image from the library on iOS 13

## [1.0-alpha01] - 2022-05-02

### Added
- First public version of the SDK
