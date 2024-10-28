import Foundation
import os


// Ключ для хранения секретных пиров
public let peerSecretsKey = "peerSecrets"
let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "PeerSecrets")

// Структура для результата проверки секретного пира
public struct PeerSecretCheckResult {
    public let isSecret: Bool
   public let code: String?
}

public extension Notification.Name {
    static let peerSecretsDidChange = Notification.Name("peerSecretsDidChange")
}

// Структура для хранения данных PeerID и кода
public struct PeerSecret: Codable {
    let peerID: String
    var code: String
}

// Получаем текущие секретные пиров через UserDefaults
public func getPeerSecrets() -> [PeerSecret] {
    let defaults = UserDefaults.standard
    if let savedData = defaults.data(forKey: peerSecretsKey),
       let peerSecrets = try? JSONDecoder().decode([PeerSecret].self, from: savedData) {
        return peerSecrets
    } else {
        return []
    }
}



// Проверяем, является ли peerID секретным пиром и возвращаем результат
public func isSecretPeer(peerID: String) -> PeerSecretCheckResult {
//    print("PRINT14 ISMYPERRRTRRR \(context.account.id.description)")
    
    let peerSecrets = getPeerSecrets()
    
    // Находим PeerID в сохраненных секретах
    if let secret = peerSecrets.first(where: { $0.peerID == peerID }) {
       
        return PeerSecretCheckResult(isSecret: true, code: secret.code)
    } else {
        
        return PeerSecretCheckResult(isSecret: false, code: nil)
    }
}

public func isMyPeerId(peerID: String) -> Bool {
    let result = isSecretPeer(peerID: peerID)
    
    if result.isSecret && result.code == "#$@#" {
        return true
    } else {
        return false
    }
}


// Добавляем нового секретного пира (PeerID и код) в UserDefaults
public func addPeerSecret(peerID: String, code: String) {
    var peerSecrets = getPeerSecrets()
    
    // Проверяем, существует ли уже PeerID
    if let index = peerSecrets.firstIndex(where: { $0.peerID == peerID }) {
        // Если такой PeerID уже есть, обновляем код
        peerSecrets[index].code = code
        os_log("Updated existing PeerID %{public}@", log: log, type: .info, peerID)
    } else {
        // Если PeerID нет, добавляем новый
        let newSecret = PeerSecret(peerID: peerID, code: code)
        peerSecrets.append(newSecret)
        os_log("Added new PeerID %{public}@", log: log, type: .info, peerID)
    }
    
    // Сохраняем данные обратно в UserDefaults
    if let encodedData = try? JSONEncoder().encode(peerSecrets) {
        let defaults = UserDefaults.standard
        defaults.set(encodedData, forKey: peerSecretsKey)
        
        // Отправляем уведомление о изменении секретов
        NotificationCenter.default.post(name: .peerSecretsDidChange, object: nil)
    }
}

// Удаляем секретный пир (PeerID) из UserDefaults
public func removePeerSecret(peerID: String) {
    var peerSecrets = getPeerSecrets()
    
    // Находим индекс PeerID, если он существует
    if let index = peerSecrets.firstIndex(where: { $0.peerID == peerID }) {
        // Удаляем PeerID из массива
        peerSecrets.remove(at: index)
        os_log("Removed PeerID %{public}@", log: log, type: .info, peerID)
        
        // Сохраняем обновленные данные обратно в UserDefaults
        if let encodedData = try? JSONEncoder().encode(peerSecrets) {
            let defaults = UserDefaults.standard
            defaults.set(encodedData, forKey: peerSecretsKey)
            
            // Отправляем уведомление о изменении секретов
            NotificationCenter.default.post(name: .peerSecretsDidChange, object: nil)
        }
    } else {
        os_log("PeerID %{public}@ not found", log: log, type: .error, peerID)
    }
}

// Наблюдение за изменениями в секретных пирах
public func observePeerSecretsChange(_ observer: Any, selector: Selector) {
    NotificationCenter.default.addObserver(observer, selector: selector, name: .peerSecretsDidChange, object: nil)
    print("PRINT4 Observer subscribed for peer secret changes") // Логирование
}

// Удаление наблюдателя
public func removePeerSecretsObserver(_ observer: Any) {
    NotificationCenter.default.removeObserver(observer, name: .peerSecretsDidChange, object: nil)
}
