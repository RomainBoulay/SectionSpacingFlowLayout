import Foundation
import UIKit

class SectionSpacingFlowLayout: UICollectionViewFlowLayout {
    fileprivate var sectionMaxYs = [CGFloat]()

    var decorationViewKind: String = "Spacing" {
        didSet(newSpacingHeight) {
            invalidateLayout()
        }
    }

    var spacingHeight: CGFloat = 50 {
        didSet(newSpacingHeight) {
            invalidateLayout()
        }
    }

    func register(viewClass: Swift.AnyClass?) {
        register(viewClass, forDecorationViewOfKind: decorationViewKind)
    }

    func register(nib: UINib?) {
        register(nib, forDecorationViewOfKind: decorationViewKind)
    }

    // MARK: UICollectionViewFlowLayout

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        scrollDirection = .vertical

        sectionMaxYs.removeAll()
        var y: CGFloat = 0

        for section in 0...collectionView.numberOfSections-1 {
            let insets = sectionInset(for: section)
            y += referenceSizeForHeader(in: section).height
            y += insets.top

            for row in 0...numberOfLine(in: section)-1 {
                y += sizeForItem(at: IndexPath(row: row, section: section)).height
                y += minimumLineSpacing(for: section)
            }

            y += insets.bottom
            y += referenceSizeForFooter(in: section).height
            sectionMaxYs.append(y)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superLayoutAttributes = super.layoutAttributesForElements(in: fixBugRect(rect)) else { return nil }

        var supplementaryAndCellAtrributes = updatedSupplementaryAndCellAtrributes(from: superLayoutAttributes)

        let indexes = orderedSectionIndexes(from: superLayoutAttributes)
        for section in indexes {
            supplementaryAndCellAtrributes.append(decoration(section: section))
        }

        return supplementaryAndCellAtrributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttribute = super.layoutAttributesForItem(at: indexPath) else { return nil }
        return updatedSupplementaryAndCellAtrributes(from: [layoutAttribute]).first
    }

    override var collectionViewContentSize: CGSize {
        guard
            let collectionView = collectionView,
            let lastSectionMaxY = sectionMaxYs.last else {
                return .zero
        }
        return CGSize(width: collectionView.frame.size.width,
                      height: lastSectionMaxY + CGFloat(collectionView.numberOfSections + 1) * spacingHeight)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: Private

extension SectionSpacingFlowLayout {
    fileprivate func fixBugRect(_ originalRect: CGRect) ->  CGRect {
        guard let collectionView = collectionView else { return originalRect }
        return originalRect.insetBy(dx: 0, dy: -collectionView.bounds.size.height)
    }

    fileprivate func updatedSupplementaryAndCellAtrributes(from layoutAttributes: [UICollectionViewLayoutAttributes]) -> [UICollectionViewLayoutAttributes] {
        var result = [UICollectionViewLayoutAttributes]()
        let supplementaryAndCellAtrributes = layoutAttributes.filter {
            return $0.representedElementCategory == .supplementaryView || $0.representedElementCategory == .cell
        }

        for layoutAttribute in supplementaryAndCellAtrributes {
            let offsetY = CGFloat(1 + layoutAttribute.indexPath.section) * spacingHeight
            layoutAttribute.frame = layoutAttribute.frame.offsetBy(dx: 0, dy: offsetY)
            result.append(layoutAttribute)
        }
        return result
    }

    fileprivate func numberOfLine(in section: Int) -> Int {
        let itemsCount = CGFloat(collectionView!.numberOfItems(inSection: section))
        let width: CGFloat = availableWidth(in: section)
        let itemWidth = sizeForItem(at: IndexPath(row: 0, section: section)).width
        let minInteritemSpacing = minimumInteritemSpacing(for: section)
        let itemsAcross = ((width + minInteritemSpacing) / (itemWidth + minInteritemSpacing))
        let result = itemsCount / itemsAcross.rounded(.down)
        return Int(result.rounded(.up))
    }

    fileprivate func orderedSectionIndexes(from layoutAttributes: [UICollectionViewLayoutAttributes]) -> [Int] {
        let indexes = layoutAttributes.map { return $0.indexPath.section }
        return Set(indexes).sorted()
    }

    fileprivate func availableWidth(in section: Int) -> CGFloat {
        guard let cv = collectionView else { return 0 }
        let inset = sectionInset(for: section)
        return cv.frame.size.width - cv.contentInset.left - cv.contentInset.right - inset.left - inset.right
    }

    fileprivate func decoration(section: Int) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: decorationViewKind, with: IndexPath(row: 0, section: section))

        let sectionMaxY = section == 0 ? 0 : (sectionMaxYs[section-1] + CGFloat(section) * spacingHeight)
        attr.frame = CGRect(x: 0, y: sectionMaxY, width: collectionView!.frame.size.width, height: spacingHeight)
        return attr
    }
}
