import Foundation
import Postbox
import SwiftSignalKit

//func _internal_enqueueOutgoingMessageWithChatContextResult(account: Account, to peerId: PeerId, threadId: Int64?, botId: PeerId, result: ChatContextResult, replyToMessageId: EngineMessageReplySubject?, replyToStoryId: StoryId?, hideVia: Bool, silentPosting: Bool, scheduleTime: Int32?, correlationId: Int64?) -> Bool {
//    guard let message = _internal_outgoingMessageWithChatContextResult(to: peerId, threadId: threadId, botId: botId, result: result, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, hideVia: hideVia, silentPosting: silentPosting, scheduleTime: scheduleTime, correlationId: correlationId) else {
//        return false
//    }
//    let _ = enqueueMessages(account: account, peerId: peerId, messages: [message]).start()
//    return true
//}

func _internal_enqueueOutgoingMessageWithChatContextResult(
    account: Account,
    to peerId: PeerId,
    threadId: Int64?,
    botId: PeerId,
    result: ChatContextResult,
    replyToMessageId: EngineMessageReplySubject?,
    replyToStoryId: StoryId?,
    hideVia: Bool,
    silentPosting: Bool,
    scheduleTime: Int32?,
    correlationId: Int64?
) -> Bool {
    guard let message = _internal_outgoingMessageWithChatContextResult(
        to: peerId,
        threadId: threadId,
        botId: botId,
        result: result,
        replyToMessageId: replyToMessageId,
        replyToStoryId: replyToStoryId,
        hideVia: hideVia,
        silentPosting: silentPosting,
        scheduleTime: scheduleTime,
        correlationId: correlationId
    ) else {
        return false
    }
    
    // Проверяем, является ли сообщение текстом
    if case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets) = message {
        // Добавляем смайлик к тексту
        var modifiedText = text
            
            // Добавляем смайлик к тексту
            modifiedText += " 😊"
        
        // Создаем новое сообщение с изменённым текстом
        let modifiedMessage = EnqueueMessage.message(
            text: modifiedText,
            attributes: attributes,
            inlineStickers: inlineStickers,
            mediaReference: mediaReference,
            threadId: threadId,
            replyToMessageId: replyToMessageId,
            replyToStoryId: replyToStoryId,
            localGroupingKey: localGroupingKey,
            correlationId: correlationId,
            bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets
        )
        
        // Отправляем изменённое сообщение
        let _ = enqueueMessages(account: account, peerId: peerId, messages: [modifiedMessage]).start()
        return true
    }
    
    // Если сообщение не текстовое, отправляем его как есть
    let _ = enqueueMessages(account: account, peerId: peerId, messages: [message]).start()
    return true
}


func _internal_outgoingMessageWithChatContextResult(to peerId: PeerId, threadId: Int64?, botId: PeerId, result: ChatContextResult, replyToMessageId: EngineMessageReplySubject?, replyToStoryId: StoryId?, hideVia: Bool, silentPosting: Bool, scheduleTime: Int32?, correlationId: Int64?) -> EnqueueMessage? {
    var replyToMessageId = replyToMessageId
    if replyToMessageId == nil, let threadId = threadId {
        replyToMessageId = EngineMessageReplySubject(messageId: MessageId(peerId: peerId, namespace: Namespaces.Message.Cloud, id: MessageId.Id(clamping: threadId)), quote: nil)
    }
    
    var webpageUrl: String?
    if case let .webpage(_, _, url, _, _) = result.message {
        webpageUrl = url
    }
    
    var attributes: [MessageAttribute] = []
    attributes.append(OutgoingChatContextResultMessageAttribute(queryId: result.queryId, id: result.id, hideVia: hideVia, webpageUrl: webpageUrl))
    if !hideVia {
        attributes.append(InlineBotMessageAttribute(peerId: botId, title: nil))
    }
    if let scheduleTime = scheduleTime {
        attributes.append(OutgoingScheduleInfoMessageAttribute(scheduleTime: scheduleTime))
    }
    if silentPosting {
        attributes.append(NotificationInfoMessageAttribute(flags: .muted))
    }
    switch result.message {
    case let .auto(caption, entities, replyMarkup):
        if let entities = entities {
            attributes.append(entities)
        }
        if let replyMarkup = replyMarkup {
            attributes.append(replyMarkup)
        }
        switch result {
        case let .internalReference(internalReference):
            if internalReference.type == "game" {
                if peerId.namespace == Namespaces.Peer.SecretChat {
                    let filteredAttributes = attributes.filter { attribute in
                        if let _ = attribute as? ReplyMarkupMessageAttribute {
                            return false
                        }
                        return true
                    }
                    if let media: Media = internalReference.file ?? internalReference.image {
                        return .message(text: caption, attributes: filteredAttributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
                    } else {
                        return .message(text: caption, attributes: filteredAttributes, inlineStickers: [:], mediaReference: nil, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
                    }
                } else {
                    return .message(text: "", attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: TelegramMediaGame(gameId: 0, accessHash: 0, name: "", title: internalReference.title ?? "", description: internalReference.description ?? "", image: internalReference.image, file: internalReference.file)), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
                }
            } else if let file = internalReference.file, internalReference.type == "gif" {
                return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: file), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
            } else if let image = internalReference.image {
                return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: image), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
            } else if let file = internalReference.file {
                return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: file), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
            } else {
                return nil
            }
        case let .externalReference(externalReference):
            if externalReference.type == "photo" {
                if let thumbnail = externalReference.thumbnail {
                    var randomId: Int64 = 0
                    arc4random_buf(&randomId, 8)
                    let thumbnailResource = thumbnail.resource
                    let imageDimensions = thumbnail.dimensions ?? PixelDimensions(width: 128, height: 128)
                    let tmpImage = TelegramMediaImage(imageId: MediaId(namespace: Namespaces.Media.LocalImage, id: randomId), representations: [TelegramMediaImageRepresentation(dimensions: imageDimensions, resource: thumbnailResource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false)], immediateThumbnailData: nil, reference: nil, partialReference: nil, flags: [])
                    return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: tmpImage), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
                } else {
                    return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: nil, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
                }
            } else if externalReference.type == "document" || externalReference.type == "gif" || externalReference.type == "audio" || externalReference.type == "voice" {
                var videoThumbnails: [TelegramMediaFile.VideoThumbnail] = []
                var previewRepresentations: [TelegramMediaImageRepresentation] = []
                if let thumbnail = externalReference.thumbnail {
                    var randomId: Int64 = 0
                    arc4random_buf(&randomId, 8)
                    let thumbnailResource = thumbnail.resource
                    
                    if thumbnail.mimeType.hasPrefix("video/") {
                        videoThumbnails.append(TelegramMediaFile.VideoThumbnail(dimensions: thumbnail.dimensions ?? PixelDimensions(width: 128, height: 128), resource: thumbnailResource))
                    } else {
                        previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: thumbnail.dimensions ?? PixelDimensions(width: 128, height: 128), resource: thumbnailResource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
                    }
                }
                var fileName = "file"
                if let content = externalReference.content {
                    var contentUrl: String?
                    if let resource = content.resource as? HttpReferenceMediaResource {
                        contentUrl = resource.url
                    } else if let resource = content.resource as? WebFileReferenceMediaResource {
                        contentUrl = resource.url
                    }
                    if let contentUrl = contentUrl, let url = URL(string: contentUrl) {
                        if !url.lastPathComponent.isEmpty {
                            fileName = url.lastPathComponent
                        }
                    }
                }
                
                var fileAttributes: [TelegramMediaFileAttribute] = []
                fileAttributes.append(.FileName(fileName: fileName))
                
                if externalReference.type == "gif" {
                    fileAttributes.append(.Animated)
                }
                
                if let dimensions = externalReference.content?.dimensions {
                    fileAttributes.append(.ImageSize(size: dimensions))
                    if externalReference.type == "gif" {
                        fileAttributes.append(.Video(duration: externalReference.content?.duration ?? 0.0, size: dimensions, flags: [], preloadSize: nil, coverTime: nil))
                    }
                }
                
                if externalReference.type == "audio" || externalReference.type == "voice" {
                    fileAttributes.append(.Audio(isVoice: externalReference.type == "voice", duration: Int(Int32(externalReference.content?.duration ?? 0)), title: externalReference.title, performer: externalReference.description, waveform: nil))
                }
                
                var randomId: Int64 = 0
                arc4random_buf(&randomId, 8)
                
                let resource: TelegramMediaResource
                if peerId.namespace == Namespaces.Peer.SecretChat, let webResource = externalReference.content?.resource as? WebFileReferenceMediaResource {
                    resource = webResource
                } else {
                    resource = EmptyMediaResource()
                }
                
                let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: randomId), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: videoThumbnails, immediateThumbnailData: nil, mimeType: externalReference.content?.mimeType ?? "application/binary", size: nil, attributes: fileAttributes)
                return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: file), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
            } else {
                return .message(text: caption, attributes: attributes, inlineStickers: [:], mediaReference: nil, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
            }
        }
    case let .text(text, entities, disableUrlPreview, previewParameters, replyMarkup):
        if let entities = entities {
            attributes.append(entities)
        }
        if let replyMarkup = replyMarkup {
            attributes.append(replyMarkup)
        }
        if let previewParameters = previewParameters {
            attributes.append(previewParameters)
        }
        if disableUrlPreview {
            attributes.append(OutgoingContentInfoMessageAttribute(flags: [.disableLinkPreviews]))
        }
        return .message(text: text, attributes: attributes, inlineStickers: [:], mediaReference: nil, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
    case let .mapLocation(media, replyMarkup):
        if let replyMarkup = replyMarkup {
            attributes.append(replyMarkup)
        }
        return .message(text: "", attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
    case let .contact(media, replyMarkup):
        if let replyMarkup = replyMarkup {
            attributes.append(replyMarkup)
        }
        return .message(text: "", attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
    case let .invoice(media, replyMarkup):
        if let replyMarkup = replyMarkup {
            attributes.append(replyMarkup)
        }
        return .message(text: "", attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
    case let .webpage(text, entities, _, previewParameters, replyMarkup):
        if let entities = entities {
            attributes.append(entities)
        }
        if let replyMarkup = replyMarkup {
            attributes.append(replyMarkup)
        }
        if let previewParameters = previewParameters {
            attributes.append(previewParameters)
        }
        return .message(text: text, attributes: attributes, inlineStickers: [:], mediaReference: nil, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])
    }
}
