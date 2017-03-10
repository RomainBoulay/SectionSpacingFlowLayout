import Foundation
import UIKit

open class SectionSpacingFlowLayout: UICollectionViewFlowLayout {
    fileprivate var sectionPositions = [SectionAttribute]()

    public var decorationViewKind: String = "SectionSpacingFlowLayout" {
        didSet { invalidateLayout() }
    }

    public var spacingHeight: CGFloat = 50 {
        didSet { invalidateLayout() }
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

        sectionPositions.removeAll()
        for section in 0...collectionView.numberOfSections-1 {
            let itemsCount = collectionView.numberOfItems(inSection: section)
            let previousAggregatedVerticalOffset = sectionPositions.last?.aggregatedVerticalOffset ?? 0

            if
                itemsCount > 0,
                let layoutAttributesForFirstItem = super.layoutAttributesForItem(at: IndexPath(row: 0, section: section)),
                let lastIndexPath = lastIndexPath(in: section, collectionView: collectionView),
                let layoutAttributesForLastItem = super.layoutAttributesForItem(at: lastIndexPath) {

                let sectionPosition = buildSectionPosition(firstLayoutAttribute: layoutAttributesForFirstItem,
                                                           lastLayoutAttribute: layoutAttributesForLastItem,
                                                           section: section,
                                                           itemsCount: itemsCount,
                                                           previousAggregatedVerticalOffset: previousAggregatedVerticalOffset)
                sectionPositions.append(sectionPosition)
            } else {
                let sectionPosition = SectionAttribute.empty(previousAggregatedVerticalOffset: previousAggregatedVerticalOffset,
                                                             headerHeight: sectionTopY(section: section),
                                                             footerHeigth: sectionBottomY(section: section))
                sectionPositions.append(sectionPosition)
            }
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superLayoutAttributes = super.layoutAttributesForElements(in: workaroundCellFlickering(rect)) else { return nil }

        var returnedLayoutAttributes = updatedSupplementaryAndCellAtrributes(from: superLayoutAttributes)
        let sectionIndexes = orderedSectionIndexes(from: returnedLayoutAttributes)

        for section in sectionIndexes {
            if let decorationViewLayoutAttribute = decorationLayoutAttribute(section: section) {
                returnedLayoutAttributes.append(decorationViewLayoutAttribute)
            }
        }

        return returnedLayoutAttributes
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttribute = super.layoutAttributesForItem(at: indexPath) else { return nil }
        return updatedSupplementaryAndCellAtrributes(from: [layoutAttribute]).first
    }

    open override var collectionViewContentSize: CGSize {
        guard
            let collectionView = collectionView,
            let lastSectionPosition = sectionPositions.last else {
                return .zero
        }
        let totalContentHeight = lastSectionPosition.newMaxY + spacingHeight
        return CGSize(width: collectionView.frame.size.width,
                      height: totalContentHeight)
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: Private

extension SectionSpacingFlowLayout {

    fileprivate func buildSectionPosition(firstLayoutAttribute: UICollectionViewLayoutAttributes,
                                          lastLayoutAttribute: UICollectionViewLayoutAttributes,
                                          section: Int,
                                          itemsCount: Int,
                                          previousAggregatedVerticalOffset: CGFloat) -> SectionAttribute {
        let minY = firstLayoutAttribute.frame.minY - sectionTopY(section: section)
        let maxY = lastLayoutAttribute.frame.maxY + sectionBottomY(section: section)
        return SectionAttribute(
            minY: minY,
            maxY: maxY,
            itemsCount: itemsCount,
            spacingHeight: spacingHeight,
            previousAggregatedVerticalOffset: previousAggregatedVerticalOffset
        )
    }

    fileprivate func lastIndexPath(in section: Int, collectionView: UICollectionView) -> IndexPath? {
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        return numberOfItems > 0 ? IndexPath(row: numberOfItems - 1, section: section) : nil
    }

    fileprivate func sectionBottomY(section: Int) -> CGFloat {
        var y: CGFloat = 0
        y += minimumLineSpacing(for: section)
        y += sectionInset(for: section).bottom
        y += referenceSizeForFooter(in: section).height
        return y
    }

    fileprivate func sectionTopY(section: Int) -> CGFloat {
        var y: CGFloat = 0
        y += referenceSizeForHeader(in: section).height
        y += sectionInset(for: section).top
        return y
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
            let section = layoutAttribute.indexPath.section
            let supplementaryAndCellAtrribute = updatedSupplementaryAndCellAtrribute(section: section,
                                                                                     originalLayoutAttribute: layoutAttribute)
            result.append(supplementaryAndCellAtrribute)
        }

        if let lastDecoration = lastDecorationLayoutAttribute() {
            result.append(lastDecoration)
        }

        return result
    }

    fileprivate func updatedSupplementaryAndCellAtrribute(section: Int, originalLayoutAttribute: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let returnedLayoutAttribute = originalLayoutAttribute
        let verticalOffset = sectionPositions[section].aggregatedVerticalOffset
        returnedLayoutAttribute.frame = returnedLayoutAttribute.frame.offsetBy(dx: 0, dy: verticalOffset)
        returnedLayoutAttribute.isHidden = !sectionPositions[section].hasItems
        return returnedLayoutAttribute
    }

    fileprivate func numberOfLines(in section: Int) -> Int {
        let itemsCount = CGFloat(sectionPositions[section].itemsCount)
        let width = availableWidth(in: section)
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

    fileprivate func decorationLayoutAttribute(section: Int, row: Int = 0) -> UICollectionViewLayoutAttributes? {
        let sectionPosition = sectionPositions[section]
        guard sectionPosition.hasItems else { return nil }

        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: decorationViewKind, with: IndexPath(row: row, section: section))
        let sectionMinY = sectionPosition.decorationViewMinY
        attr.frame = CGRect(x: 0, y: sectionMinY, width: collectionView!.frame.size.width, height: spacingHeight)
        return attr
    }

    fileprivate func lastDecorationLayoutAttribute() -> UICollectionViewLayoutAttributes? {
        guard let sectionPosition = sectionPositions.last else { return nil }

        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: decorationViewKind, with: IndexPath(row: 1, section: sectionPositions.count-1))
        let sectionMinY = sectionPosition.newMaxY
        attr.frame = CGRect(x: 0, y: sectionMinY, width: collectionView!.frame.size.width, height: spacingHeight)
        return attr
    }
}
