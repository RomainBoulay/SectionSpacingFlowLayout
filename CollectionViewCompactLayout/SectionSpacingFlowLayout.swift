import Foundation
import UIKit

fileprivate enum DividerViewPositionInSection: Int {
    case top = 0
    case bottom = 1

    func yPosition(in sectionAttribute: SectionAttribute, dividerHeight: CGFloat) -> CGFloat {
        switch self {
        case .top: return sectionAttribute.newMinY - dividerHeight
        case .bottom: return sectionAttribute.newMaxY - dividerHeight
        }
    }
}

open class SectionSpacingFlowLayout: UICollectionViewFlowLayout {
    fileprivate var sectionPositions = [SectionAttribute]()

    public var spacingViewKind: String = "SectionSpacingDecorationView" {
        didSet { invalidateLayout() }
    }

    public var spacingHeight: CGFloat = 12 {
        didSet { invalidateLayout() }
    }

    public var dividerViewKind: String = "SectionSpacingDividerView" {
        didSet { invalidateLayout() }
    }

    public var dividerHeight: CGFloat = 1.0/UIScreen.main.scale {
        didSet { invalidateLayout() }
    }

    public func registerSpacingView(viewClass: AnyClass?) {
        register(viewClass, forDecorationViewOfKind: spacingViewKind)
    }

    public func registerSpacingView(nib: UINib?) {
        register(nib, forDecorationViewOfKind: spacingViewKind)
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
                let firstLayoutAttribute = super.layoutAttributesForItem(at: IndexPath(row: 0, section: section)),
                let lastIndexPath = lastIndexPath(in: section, collectionView: collectionView),
                let lastLayoutAttribute = super.layoutAttributesForItem(at: lastIndexPath) {

                let sectionPosition = SectionAttribute(
                    initialMinY: firstLayoutAttribute.frame.minY - sectionTopHeight(section: section),
                    initialMaxY: lastLayoutAttribute.frame.maxY + sectionBottomHeight(section: section),
                    itemsCount: itemsCount,
                    spacingHeight: spacingHeight,
                    previousAggregatedVerticalOffset: previousAggregatedVerticalOffset
                )
                sectionPositions.append(sectionPosition)
            } else {
                let sectionPosition = SectionAttribute.empty(previousAggregatedVerticalOffset: previousAggregatedVerticalOffset,
                                                             sectionTopHeight: sectionTopHeight(section: section),
                                                             sectionBottomHeight: sectionBottomHeight(section: section))
                sectionPositions.append(sectionPosition)
            }
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superLayoutAttributes = super.layoutAttributesForElements(in: workaroundCellFlickering(rect)) else { return nil }

        var returnedLayoutAttributes = updatedSupplementaryAndCellAtrributes(from: superLayoutAttributes)
        let sectionIndexes = orderedSectionIndexes(from: returnedLayoutAttributes)

        for section in sectionIndexes {
            if let topDividerAttribute = dividerViewAttribute(section: section, dividerViewPosition: .top) {
                returnedLayoutAttributes.append(topDividerAttribute)
            }

            if let decorationViewLayoutAttribute = spacingViewAttribute(section: section) {
                returnedLayoutAttributes.append(decorationViewLayoutAttribute)
            }

            if let bottomDividerAttribute = dividerViewAttribute(section: section, dividerViewPosition: .bottom) {
                returnedLayoutAttributes.append(bottomDividerAttribute)
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
        guard let collectionView = collectionView else { return true }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }

    open override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        guard let flowContext = context as? UICollectionViewFlowLayoutInvalidationContext else {
            return context
        }

        flowContext.invalidateFlowLayoutDelegateMetrics = true
        flowContext.invalidateFlowLayoutAttributes = true
        return flowContext
    }
}

// MARK: Private

extension SectionSpacingFlowLayout {

    fileprivate func lastIndexPath(in section: Int, collectionView: UICollectionView) -> IndexPath? {
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        return numberOfItems > 0 ? IndexPath(row: numberOfItems - 1, section: section) : nil
    }

    fileprivate func sectionBottomHeight(section: Int) -> CGFloat {
        var y = minimumLineSpacing(for: section)
        y += sectionInset(for: section).bottom
        y += referenceSizeForFooter(in: section).height
        return y
    }

    fileprivate func sectionTopHeight(section: Int) -> CGFloat {
        var y = referenceSizeForHeader(in: section).height
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

        if let lastDecoration = lastSpacingViewAttribute() {
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
        let width = collectionView!.availableWidth(in: section)
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

    fileprivate func spacingViewAttribute(section: Int, row: Int = 0) -> UICollectionViewLayoutAttributes? {
        let sectionPosition = sectionPositions[section]
        guard sectionPosition.hasItems else { return nil }

        return buildSpacingViewAttribute(indexPath: IndexPath(row: row, section: section),
                                         y: sectionPosition.decorationViewMinY)
    }

    fileprivate func dividerViewAttribute(section: Int, dividerViewPosition: DividerViewPositionInSection) -> UICollectionViewLayoutAttributes? {
        let sectionPosition = sectionPositions[section]
        guard sectionPosition.hasItems else { return nil }

        return buildDividerViewAttribute(indexPath: IndexPath(row: dividerViewPosition.rawValue, section: section),
                                         y: dividerViewPosition.yPosition(in: sectionPosition, dividerHeight: dividerHeight))
    }

    fileprivate func lastSpacingViewAttribute() -> UICollectionViewLayoutAttributes? {
        guard let sectionPosition = sectionPositions.last else { return nil }

        return buildSpacingViewAttribute(indexPath: IndexPath(row: 1, section: sectionPositions.endIndex-1),
                                         y: sectionPosition.newMaxY)
    }

    fileprivate func buildSpacingViewAttribute(indexPath: IndexPath, y: CGFloat) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: spacingViewKind, with: indexPath)
        attr.frame = CGRect(x: 0, y: y, width: collectionView!.frame.size.width, height: spacingHeight)
        return attr
    }

    fileprivate func buildDividerViewAttribute(indexPath: IndexPath, y: CGFloat) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: dividerViewKind, with: indexPath)
        attr.frame = CGRect(x: 0, y: y, width: collectionView!.frame.size.width, height: dividerHeight)
        return attr
    }
}
