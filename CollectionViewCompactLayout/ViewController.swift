import UIKit

class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!

    let data = [["1.1", "1.2", "1.3"], ["2.1","2.2", "2.3"], ["3.1","3.2"], ["4.1"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        let cellNib = UINib(nibName: "Cell", bundle: nil)
        let headerNib = UINib(nibName: "Header", bundle: nil)
        let footerNib = UINib(nibName: "Footer", bundle: nil)
        let decorationNib = UINib(nibName: "Decoration", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "Cell")
        collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.register(footerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView.collectionViewLayout.register(decorationNib, forDecorationViewOfKind: "Decoration")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

