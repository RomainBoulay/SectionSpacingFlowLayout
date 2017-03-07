import Foundation
import UIKit

class FlowLayout: UICollectionViewFlowLayout {
    private var sectionMaxYs = [CGFloat]()
    private let spacingHeight: CGFloat
    private let decorationViewKind: String

    init(decorationViewKind: String = "Decoration", spacingHeight: CGFloat = 20) {
        self.decorationViewKind = decorationViewKind
        self.spacingHeight = spacingHeight
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        self.decorationViewKind = "Decoration"
        self.spacingHeight = 20
        super.init(coder: aDecoder)
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        sectionMaxYs.removeAll()
        var y = CGFloat(0)

        for section in 0...collectionView.numberOfSections-1 {
            let insets = sectionInset(for: section)
            y += referenceSizeForHeader(in: section).height
            y += insets.top

            let itemsCount = collectionView.numberOfItems(inSection: section)
            for row in 0...itemsCount-1 {
                y += sizeForItem(at: IndexPath(row: row, section: section)).height
                y += minimumLineSpacing(for: section)
            }

            y += insets.bottom
            y += referenceSizeForFooter(in: section).height
            sectionMaxYs.append(y)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let collectionView = collectionView,
            let superLayoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var layoutAttributes = superLayoutAttributes
        for layoutAttribute in layoutAttributes where layoutAttribute.representedElementCategory == .supplementaryView || layoutAttribute.representedElementCategory == .cell {
            let offsetY = CGFloat(1 + layoutAttribute.indexPath.section) * spacingHeight
            layoutAttribute.frame = layoutAttribute.frame.offsetBy(dx: 0, dy: offsetY)
        }

        for section in 0...collectionView.numberOfSections-1 {
            layoutAttributes.append(decoration(section: section))
        }

        return layoutAttributes
    }

    override var collectionViewContentSize: CGSize {
        guard
            let collectionView = collectionView,
            let lastSectionMaxY = sectionMaxYs.last else {
                return .zero
        }
        return CGSize(width: itemWidth,
                      height: lastSectionMaxY + CGFloat(collectionView.numberOfSections + 1) * spacingHeight)
    }

//    func itemCountPerRow() {
//        
//        int itemsAcross = floorf((availableWidth + self.minimumInteritemSpacing) / (self.itemSize.width + self.minimumInteritemSpacing));
//    }

    private var itemWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.frame.width - sectionInset.left - sectionInset.right - collectionView.contentInset.left - collectionView.contentInset.right
    }

    private func decoration(section: Int) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: "Decoration", with: IndexPath(row: 0, section: section))

        let sectionMaxY = section == 0 ? 0 : (sectionMaxYs[section-1] + CGFloat(section) * spacingHeight)
        attr.frame = CGRect(x: 0, y: sectionMaxY, width: itemWidth, height: spacingHeight)
        return attr
    }

    private func minimumLineSpacing(for section: Int) -> CGFloat {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let minimumLineSpacingForSection = flowDelegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) else {
                return minimumLineSpacing
        }
        return minimumLineSpacingForSection
    }

    private func sectionInset(for section: Int) -> UIEdgeInsets {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let insetForSection = flowDelegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) else {
                return sectionInset
        }
        return insetForSection
    }

    private func referenceSizeForHeader(in section: Int) -> CGSize {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let headerSize = flowDelegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) else {
                return headerReferenceSize
        }
        return headerSize
    }

    private func referenceSizeForFooter(in section: Int) -> CGSize {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let footerSize = flowDelegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) else {
                return footerReferenceSize
        }
        return footerSize
    }

    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let size = flowDelegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) else {
                return itemSize
        }
        return size
    }
}
