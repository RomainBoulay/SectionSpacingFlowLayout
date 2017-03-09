import Foundation
import UIKit

open class SectionSpacingFlowLayout: UICollectionViewFlowLayout {
    fileprivate var sectionMaxYs = [CGFloat]()

    public var decorationViewKind: String = "SectionSpacingFlowLayout" {
        didSet {
            invalidateLayout()
        }
    }

    public var spacingHeight: CGFloat = 12 {
        didSet {
            invalidateLayout()
        }
    }

    public var collectionViewBottomInset: CGFloat = 12 {
        didSet {
            invalidateLayout()
        }
    }

    public func register(viewClass: AnyClass?) {
        register(viewClass, forDecorationViewOfKind: decorationViewKind)
    }

    public func register(nib: UINib?) {
        register(nib, forDecorationViewOfKind: decorationViewKind)
    }

    // MARK: UICollectionViewFlowLayout

    open override func prepare() {
        super.prepare()
        guard
            let collectionView = collectionView,
            collectionView.numberOfSections > 0,
            scrollDirection == .vertical else { return }

        sectionMaxYs.removeAll()
        for section in 0...collectionView.numberOfSections-1 {
            let previousY = sectionMaxYs.last ?? 0
            sectionMaxYs.append(sectionMaxY(section: section, previousY: previousY))
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superLayoutAttributes = super.layoutAttributesForElements(in: workaroundCellFlickering(rect)) else { return nil }

        var supplementaryAndCellAtrributes = updatedSupplementaryAndCellAtrributes(from: superLayoutAttributes)

        let indexes = orderedSectionIndexes(from: superLayoutAttributes)
        for section in indexes {
            supplementaryAndCellAtrributes.append(decoration(section: section))
        }

        return supplementaryAndCellAtrributes
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttribute = super.layoutAttributesForItem(at: indexPath) else { return nil }
        return updatedSupplementaryAndCellAtrributes(from: [layoutAttribute]).first
    }

    open override var collectionViewContentSize: CGSize {
        guard
            let collectionView = collectionView,
            let lastSectionMaxY = sectionMaxYs.last else {
                return .zero
        }
        return CGSize(width: collectionView.frame.size.width,
                      height: lastSectionMaxY + bottomExtraSpace)
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: Private

extension SectionSpacingFlowLayout {

    fileprivate func sectionMaxY(section: Int, previousY: CGFloat) -> CGFloat {
        var y = previousY

        let insets = sectionInset(for: section)
        let sectionMinimumLineSpacing = minimumLineSpacing(for: section)
        y += referenceSizeForHeader(in: section).height
        y += insets.top

        for row in 0...max(numberOfLines(in: section)-1, 0) {
            y += sizeForItem(at: IndexPath(row: row, section: section)).height
            y += sectionMinimumLineSpacing
        }

        y += insets.bottom
        y += referenceSizeForFooter(in: section).height
        return y
    }

    fileprivate var bottomExtraSpace: CGFloat {
        guard let collectionView = collectionView else { return collectionViewBottomInset }
        return CGFloat(collectionView.numberOfSections) * spacingHeight + collectionViewBottomInset
    }

    fileprivate func workaroundCellFlickering(_ originalRect: CGRect) -> CGRect {
        // See: http://stackoverflow.com/a/33824851
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

    fileprivate func numberOfLines(in section: Int) -> Int {
        let itemsCount = CGFloat(collectionView!.numberOfItems(inSection: section))
        let width: CGFloat = availableWidth(in: section)
        let itemWidth = sizeForItem(at: IndexPath(row: 0, section: section)).width
        let minInteritemSpacing = minimumInteritemSpacing(for: section)
        let itemsAcross = ((width + minInteritemSpacing) / (itemWidth + minInteritemSpacing))
        let result = itemsCount / itemsAcross.rounded(.down)
        return Int(result.rounded(.up))
    }

    fileprivate func orderedSectionIndexes(from layoutAttributes: [UICollectionViewLayoutAttributes]) -> [Int] {
        let indexes = layoutAttributes.map { $0.indexPath.section }
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
