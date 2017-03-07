import Foundation
import UIKit

class SectionSpacingFlowLayout: UICollectionViewFlowLayout {
    private var sectionMaxYs = [CGFloat]()

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

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

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
        guard
            let collectionView = collectionView,
            let superLayoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var supplementaryAndCellAtrributes = superLayoutAttributes.filter {
            return $0.representedElementCategory == .supplementaryView || $0.representedElementCategory == .cell
        }

        for layoutAttribute in supplementaryAndCellAtrributes {
            let offsetY = CGFloat(1 + layoutAttribute.indexPath.section) * spacingHeight
            layoutAttribute.frame = layoutAttribute.frame.offsetBy(dx: 0, dy: offsetY)
        }

        for section in 0...collectionView.numberOfSections-1 {
            supplementaryAndCellAtrributes.append(decoration(section: section))
        }

        return Array(supplementaryAndCellAtrributes)
    }

    func register(viewClass: Swift.AnyClass?) {
        register(viewClass, forDecorationViewOfKind: decorationViewKind)
    }

    func register(nib: UINib?) {
        register(nib, forDecorationViewOfKind: decorationViewKind)
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

    private func numberOfLine(in section: Int) -> Int {
        let itemsCount = CGFloat(collectionView!.numberOfItems(inSection: section))
        let width: CGFloat = availableWidth(in: section)
        let itemWidth = sizeForItem(at: IndexPath(row: 0, section: section)).width
        let minInteritemSpacing = minimumInteritemSpacing(for: section)
        let itemsAcross = ((width + minInteritemSpacing) / (itemWidth + minInteritemSpacing))
        let result = itemsCount / itemsAcross.rounded(.down)
        return Int(result.rounded(.up))
    }

    private func availableWidth(in section: Int) -> CGFloat {
        guard let cv = collectionView else { return 0 }
        let inset = sectionInset(for: section)
        return cv.frame.size.width - cv.contentInset.left - cv.contentInset.right - inset.left - inset.right
    }

    private func decoration(section: Int) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: decorationViewKind, with: IndexPath(row: 0, section: section))

        let sectionMaxY = section == 0 ? 0 : (sectionMaxYs[section-1] + CGFloat(section) * spacingHeight)
        attr.frame = CGRect(x: 0, y: sectionMaxY, width: collectionView!.frame.size.width, height: spacingHeight)
        return attr
    }
}
