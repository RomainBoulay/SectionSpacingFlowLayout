import UIKit

extension UICollectionViewFlowLayout {
    func minimumLineSpacing(for section: Int) -> CGFloat {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let minimumLineSpacingForSection = flowDelegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) else {
                return minimumLineSpacing
        }
        return minimumLineSpacingForSection
    }

    func minimumInteritemSpacing(for section: Int) -> CGFloat {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let minimumSpacing = flowDelegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) else {
                return minimumInteritemSpacing
        }
        return minimumSpacing
    }

    func sectionInset(for section: Int) -> UIEdgeInsets {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let insetForSection = flowDelegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) else {
                return sectionInset
        }
        return insetForSection
    }

    func referenceSizeForHeader(in section: Int) -> CGSize {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let headerSize = flowDelegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) else {
                return headerReferenceSize
        }
        return headerSize
    }

    func referenceSizeForFooter(in section: Int) -> CGSize {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let footerSize = flowDelegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) else {
                return footerReferenceSize
        }
        return footerSize
    }

    func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard
            let collectionView = collectionView,
            let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            let size = flowDelegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) else {
                return itemSize
        }
        return size
    }
}
