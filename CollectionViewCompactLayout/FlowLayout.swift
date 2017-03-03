import Foundation
import UIKit

class FlowLayout: UICollectionViewFlowLayout {
    var sectionMaxYs = [CGFloat]()
    let spacingHeight = 20.0 as CGFloat

    override func awakeFromNib() {
        super.awakeFromNib()
//        minimumLineSpacing = 1.0 / UIScreen.main.scale
        headerReferenceSize = .init(width: itemWidth, height: 50)
        footerReferenceSize = .init(width: itemWidth, height: 50)
        itemSize = CGSize(width: itemWidth, height: 30)
    }

    var itemWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.frame.width - sectionInset.left - sectionInset.right - collectionView.contentInset.left - collectionView.contentInset.right
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        sectionMaxYs.removeAll()
        var y = CGFloat(0)

        for section in 0...collectionView.numberOfSections-1 {
            y += headerReferenceSize.height
            y += sectionInset.top

            let itemsCount = collectionView.numberOfItems(inSection: section)
            y += itemSize.height * CGFloat(itemsCount)
            y += minimumLineSpacing * CGFloat(itemsCount)

            y += sectionInset.bottom
            y += footerReferenceSize.height
            sectionMaxYs.append(y)
            print("Appended y: \(y)")
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let collectionView = collectionView,
            let superLayoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var layoutAttributes = Array(superLayoutAttributes)
        for layoutAttributes in layoutAttributes where layoutAttributes.representedElementCategory == .supplementaryView || layoutAttributes.representedElementCategory == .cell {
            let sectionFactor = 1 + (section(for: layoutAttributes.frame.minY) ?? 0)
            layoutAttributes.frame = layoutAttributes.frame.offsetBy(dx: 0, dy: spacingHeight * CGFloat(sectionFactor))
        }

        for section in 0...collectionView.numberOfSections-1 {
            layoutAttributes.append(decoration(section: section))
        }

        return layoutAttributes
    }

    func section(for minY: CGFloat) -> Int? {
        for (index, sectionHeight) in sectionMaxYs.enumerated() {
            if sectionHeight > minY {
                return index
            }
        }
        return nil
    }

    override var collectionViewContentSize: CGSize {
        guard let lastSectionMaxY = sectionMaxYs.last else {
            return .zero
        }
        return CGSize(width: itemWidth,
                      height: lastSectionMaxY + CGFloat(sectionMaxYs.count + 1) * spacingHeight)
    }

    func decoration(section: Int) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: "Decoration", with: IndexPath(row: 0, section: section))

        let sectionMaxY = section == 0 ? 0 : (sectionMaxYs[section-1] + CGFloat(section) * spacingHeight) //.rounded(.down)

        print("sectionMaxY: \(sectionMaxY) for section: \(section)")
        attr.frame = CGRect(x: 0, y: sectionMaxY, width: itemWidth, height: spacingHeight)
        return attr
    }
}
