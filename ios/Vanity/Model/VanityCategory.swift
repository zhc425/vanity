import Foundation

enum CategoryID: String, Codable, CaseIterable, Identifiable, Hashable {
    case mask
    case cleanser
    case cream
    case primer
    case foundation
    case loosePowder = "loose-powder"
    case pressedPowder = "pressed-powder"
    case blush
    case eyeshadow
    case lipstick
    case puff

    var id: String { rawValue }
    var info: VanityCategory { VanityCategory.all.first { $0.id == self }! }
}

struct VanityCategory: Identifiable, Hashable {
    let id: CategoryID
    let title: String
    let subtitle: String
    let imageName: String
    let coverName: String?
    let alt: String
    /// 新建藏品时的开封后可用月数建议
    let suggestedPAO: Int

    var cover: String { coverName ?? imageName }

    static let all: [VanityCategory] = [
        .init(id: .mask, title: "面膜", subtitle: "Mask", imageName: "cat-mask", coverName: nil, alt: "Fan Beauty Diary 面膜", suggestedPAO: 12),
        .init(id: .cleanser, title: "洁面乳", subtitle: "Cleanser", imageName: "cat-cleanser", coverName: nil, alt: "Chanel La Mousse 洁面", suggestedPAO: 12),
        .init(id: .cream, title: "面霜", subtitle: "Cream", imageName: "cat-cream", coverName: nil, alt: "SkinCeuticals A.G.E. 面霜", suggestedPAO: 12),
        .init(id: .primer, title: "隔离", subtitle: "Primer", imageName: "cat-primer", coverName: nil, alt: "Clé de Peau 隔离", suggestedPAO: 12),
        .init(id: .foundation, title: "粉底液", subtitle: "Foundation", imageName: "cat-foundation", coverName: nil, alt: "YSL 粉底液", suggestedPAO: 12),
        .init(id: .loosePowder, title: "散粉", subtitle: "Loose Powder", imageName: "cat-loose-powder", coverName: "cover-loose-powder", alt: "Givenchy 四宫格散粉", suggestedPAO: 24),
        .init(id: .pressedPowder, title: "蜜粉饼", subtitle: "Pressed Powder", imageName: "cat-pressed-powder", coverName: nil, alt: "NARS 蜜粉饼", suggestedPAO: 24),
        .init(id: .blush, title: "腮红", subtitle: "Blush", imageName: "cat-blush", coverName: nil, alt: "Chanel 腮红", suggestedPAO: 24),
        .init(id: .eyeshadow, title: "眼影盘", subtitle: "Palette", imageName: "cat-eyeshadow", coverName: nil, alt: "毛戈平眼影盘", suggestedPAO: 24),
        .init(id: .lipstick, title: "口红", subtitle: "Lipstick", imageName: "cat-lipstick", coverName: nil, alt: "Chanel 口红", suggestedPAO: 18),
        .init(id: .puff, title: "粉扑", subtitle: "Puff", imageName: "cat-puff", coverName: nil, alt: "Momo's Workshop 粉扑", suggestedPAO: 3)
    ]
}
