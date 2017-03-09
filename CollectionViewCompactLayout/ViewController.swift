import UIKit

class ViewController: UIViewController, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!

//    let data = [["1.1", "1.2", "1.3"], ["2.1","2.2", "2.3", "2.4"], [], ["3.1","3.2"], ["4.1"]]
    let data = [["1.1", "1.2", "1.3"], ["2.1","2.2", "2.3", "2.4"], ["3.1","3.2"], ["4.1"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        spacingFlowLayout.decorationViewKind = "Spacing"
        let cellNib = UINib(nibName: "Cell", bundle: nil)
        let headerNib = UINib(nibName: "Header", bundle: nil)
        let footerNib = UINib(nibName: "Footer", bundle: nil)
        let decorationNib = UINib(nibName: "Spacing", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "Cell")
        collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.register(footerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView.collectionViewLayout.register(decorationNib, forDecorationViewOfKind: "Spacing")
    }


    var spacingFlowLayout: SectionSpacingFlowLayout {
        return collectionView.collectionViewLayout as! SectionSpacingFlowLayout
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }) { (_) in

        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupDefaults(collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        collectionView.reloadData()
    }

    func setupDefaults(_ collectionViewLayout: UICollectionViewFlowLayout) {
        collectionViewLayout.minimumLineSpacing = 1.0 / UIScreen.main.scale
        collectionViewLayout.sectionInset.top = 1.0 / UIScreen.main.scale
        collectionViewLayout.sectionInset.bottom = 1.0 / UIScreen.main.scale
        let width = itemWidth(collectionViewLayout)
        collectionViewLayout.headerReferenceSize = .init(width: width, height: 50)
        collectionViewLayout.footerReferenceSize = .init(width: width, height: 50)
        collectionViewLayout.itemSize = CGSize(width: width, height: 30)
    }

    func itemWidth(_ collectionViewLayout: UICollectionViewFlowLayout) -> CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.frame.width - collectionViewLayout.sectionInset.left - collectionViewLayout.sectionInset.right - collectionView.contentInset.left - collectionView.contentInset.right
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    @IBAction func didTap(_ sender: Any) {
        spacingFlowLayout.spacingHeight = spacingFlowLayout.spacingHeight == 20 ? 100 : 20
    }

    // MARK: - DataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        cell.label.text = data[indexPath.section][indexPath.row]
        return cell
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "Header",
                                                                             for: indexPath) as! Header
            return headerView

        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "Footer",
                                                                             for: indexPath) as! Footer
            return footerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/2.0 - 5, height: 50)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0: return .zero
        case 1: return UIEdgeInsets(top: 25, left: 5, bottom: 25, right: 5)
        case 2: return .zero

        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0 / UIScreen.main.scale
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0: return CGSize(width: collectionView.frame.width, height: 10)
        case 1: return CGSize(width: collectionView.frame.width, height: 20)
        case 2: return CGSize(width: collectionView.frame.width, height: 30)
        case 3: return CGSize(width: collectionView.frame.width, height: 40)
        default: return CGSize(width: collectionView.frame.width, height: 10)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch section {
        case 0: return CGSize(width: collectionView.frame.width, height: 10)
        case 1: return CGSize(width: collectionView.frame.width, height: 20)
        case 2: return CGSize(width: collectionView.frame.width, height: 30)
        case 3: return CGSize(width: collectionView.frame.width, height: 40)
        default: return CGSize(width: collectionView.frame.width, height: 10)
        }
    }
}
