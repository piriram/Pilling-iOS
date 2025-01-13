import Foundation

struct SideEffectTag: Codable, Equatable {
    let id: String
    var name: String
    var isVisible: Bool
    var order: Int
    let isDefault: Bool // 기본 제공 태그 여부
    
    init(id: String = UUID().uuidString, name: String, isVisible: Bool = true, order: Int, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.isVisible = isVisible
        self.order = order
        self.isDefault = isDefault
    }
}
