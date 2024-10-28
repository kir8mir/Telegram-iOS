import Foundation
import os
import PeerSecretsManager


private let charToEmojiMap: [Character: String] = [
    // Latin lowercase letters
    "a": "🍎", "b": "🤳", "c": "🍩", "d": "🥚", "e": "🍟", "f": "👩‍🦱", "g": "🌺", "h": "🍦",
    "i": "🍏", "j": "🥝", "k": "👄", "l": "🍈", "m": "🥜", "n": "🦵", "o": "🍍", "p": "🍫",
    "q": "🍅", "r": "🍤", "s": "🅱️", "t": "🍇", "u": "🆘", "v": "🍒", "w": "🍻", "x": "🍹",
    "y": "🍷", "z": "🥂",
    
    // Latin uppercase letters
    "A": "🍉", "B": "🍕", "C": "🍔", "D": "🍖", "E": "🍗", "F": "🍜", "G": "🦝", "H": "🍿",
    "I": "🍂", "J": "🍄", "K": "🍋", "L": "🍊", "M": "🍌", "N": "👦", "O": "🧑‍🦲", "P": "🤠",
    "Q": "🥥", "R": "🍠", "S": "🥑", "T": "🌰", "U": "🫀", "V": "🍣", "W": "🍓", "X": "🌲",
    "Y": "🐫", "Z": "🥒",
    
    // Cyrillic lowercase letters
    "а": "🏤", "б": "🍑", "в": "🍧", "г": "🐂", "д": "🥗", "е": "🍙", "ё": "🍘", "ж": "🍪",
    "з": "🍬", "и": "🍭", "й": "🍮", "к": "🍯", "л": "🍰", "м": "🍳", "н": "🍽️", "о": "⌨️",
    "п": "🎂", "р": "🦷", "с": "🎄", "т": "🎇", "у": "🎉", "ф": "🎍", "х": "🎎", "ц": "🈁",
    "ч": "🚠", "ш": "🎀", "щ": "🎁", "ъ": "📸", "ы": "🎃", "ь": "🥞", "э": "🎫", "ю": "🎹", "я": "💾",
    
    // Cyrillic uppercase letters
    "А": "🎊", "Б": "🎋", "В": "🎌", "Г": "❇️", "Д": "🕣", "Е": "🎏", "Ё": "🎐", "Ж": "🎑",
    "З": "🎒", "И": "🎓", "Й": "👾", "К": "💂‍♀️", "Л": "🎖", "М": "🎗", "Н": "🧶", "О": "🎙",
    "П": "🎚", "Р": "🎛", "С": "🥻", "Т": "🪢", "У": "🎞", "Ф": "🎟", "Х": "🎠", "Ц": "🎡",
    "Ч": "🎢", "Ш": "🎣", "Щ": "🎤", "Ъ": "🎥", "Ы": "🎦", "Ь": "🎧", "Э": "🎨", "Ю": "🎩", "Я": "🎪",
    
    // Symbols
    " ": "🌂", "?": "👐", "!": "🧝‍♀️"
]


// Reverse the mapping to get emoji-to-character
private let emojiToCharMap: [String: Character] = {
    var map = [String: Character]()
    for (char, emoji) in charToEmojiMap {
        map[emoji] = char
    }
    return map
}()

// Encrypt text to emojis using the mapping
private func encryptToEmoji(text: String) -> String {
    var result = ""
    for char in text {
        if let emoji = charToEmojiMap[char] {
            result += emoji
        } else {
            result += String(char)
        }
    }
    return result
}

// Decrypt emojis back to the original text using the mapping
private func decryptFromEmoji(emojiText: String) -> String {
    var result = ""
    var currentEmoji = ""
    
    print("PRINT14 decryptFromEmoji \(emojiText)")

    for char in emojiText {
        currentEmoji += String(char)
        
        if let originalChar = emojiToCharMap[currentEmoji] {
            // Если текущий символ или последовательность символов есть в emojiToCharMap
            result += String(originalChar)
            currentEmoji = "" // Сбрасываем после нахождения совпадения
        } else if !emojiToCharMap.keys.contains(currentEmoji) {
            // Если currentEmoji не распознано как эмодзи и это не начало эмодзи, оставляем как есть
            if currentEmoji.count == 1 {
                result += currentEmoji
                currentEmoji = "" // Сбрасываем для продолжения анализа
            }
        }
    }
    
    // Если что-то осталось в currentEmoji, добавляем это в результат как есть
    if !currentEmoji.isEmpty {
        result += currentEmoji
    }
    
    print("PRINT14 result \(result)")
    return result
}


public func encryptTo(text: String, peerID: String) -> String {
    let nullWideSpace = "\u{200B}"
    let encodedKeyMarker = "🔑  "
    
    print("PRINT13 peerID \(peerID)")
    
    if isSecretPeer(peerID: peerID).isSecret {
       
        let formattedText: String
        if text.hasPrefix(nullWideSpace) {
            formattedText = text
        } else {
            if isMyPeerId(peerID: peerID.description) {
                formattedText = "\(nullWideSpace)\(encodedKeyMarker)\(encryptToEmoji(text: text))"
            } else {
                formattedText = text
            }
            
        }
        print("PRINT13 isSecretPeer tru \(formattedText)")
        return formattedText
    } else {
        print("PRINT13 isSecretPeer false \(text)")
        return text
    }
    
}

public func decryptFrom(text: String, peerID: String) -> String {
   
    if isSecretPeer(peerID: peerID).isSecret {
        let nullWideSpace = "\u{200B}"
        let encodedKeyMarker = "🔑  "
        
        if text.hasPrefix("\(nullWideSpace)\(encodedKeyMarker)") {
            
            let trimmedText = text.replacingOccurrences(of: "\(nullWideSpace)\(encodedKeyMarker)", with: "")
            let decryptedMessage = decryptFromEmoji(emojiText: trimmedText)
            print("PRINT14 decryptFrom \(decryptedMessage) text: \(text)")
            return "\(nullWideSpace)\(encodedKeyMarker)\(decryptedMessage)"
        } else {
            return text
        }
    } else {
        return text
    }
    
}

