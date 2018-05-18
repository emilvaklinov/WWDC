//
//  RelatedSessionsViewController.swift
//  WWDC
//
//  Created by Guilherme Rambo on 13/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

private extension NSUserInterfaceItemIdentifier {
    static let sessionItem = NSUserInterfaceItemIdentifier("sessionCell")
}

protocol RelatedSessionsViewControllerDelegate: class {
    func relatedSessionsViewController(_ controller: RelatedSessionsViewController, didSelectSession viewModel: SessionViewModel)
}

final class RelatedSessionsViewController: NSViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct Metrics {
        static let height: CGFloat = 96
        static let itemHeight: CGFloat = 64
        static let itemWidth: CGFloat = 360
        static let padding: CGFloat = 24
    }

    private let disposeBag = DisposeBag()

    var sessions: [SessionViewModel] = [] {
        didSet {
            collectionView.reloadData()
            view.isHidden = sessions.count == 0
        }
    }

    weak var delegate: RelatedSessionsViewControllerDelegate?

    override var title: String? {
        didSet {
            titleLabel.stringValue = title ?? ""
        }
    }

    private lazy var titleLabel: WWDCTextField = {
        let l = WWDCTextField(labelWithString: "")
        l.cell?.backgroundStyle = .dark
        l.lineBreakMode = .byTruncatingTail
        l.maximumNumberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .secondaryText
        l.font = .systemFont(ofSize: 20, weight: .semibold)

        return l
    }()

    private lazy var scrollView: NSScrollView = {
        let v = NSScrollView(frame: view.bounds)

        v.hasHorizontalScroller = true
        v.horizontalScroller?.alphaValue = 0

        return v
    }()

    private lazy var collectionView: NSCollectionView = {
        var rect = view.bounds
        rect.size.height = Metrics.itemHeight

        let v = NSCollectionView(frame: rect)

        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: Metrics.itemWidth, height: Metrics.itemHeight)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = Metrics.padding

        v.collectionViewLayout = layout
        v.dataSource = self
        v.delegate = self
        v.autoresizingMask = [.width, .minYMargin]

        return v
    }()

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: Metrics.height))
        view.wantsLayer = true

        scrollView.frame = NSRect(x: 0, y: 0, width: view.bounds.width, height: Metrics.itemHeight)
        scrollView.autoresizingMask = [.width, .minYMargin]
        view.addSubview(scrollView)
        scrollView.documentView = collectionView

        view.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(SessionCollectionViewItem.self, forItemWithIdentifier: .sessionItem)
    }

    override func scrollToBeginningOfDocument(_ sender: Any?) {
        let beginningSet = Set([IndexPath(item: 0, section: 0)])
        collectionView.scrollToItems(at: beginningSet, scrollPosition: .leadingEdge)
    }

}

extension RelatedSessionsViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: .sessionItem, for: indexPath) as? SessionCollectionViewItem else {
            return NSCollectionViewItem()
        }

        item.viewModel = sessions[indexPath.item]
        item.doubleClicked = { [unowned self] viewModel in
            self.delegate?.relatedSessionsViewController(self, didSelectSession: viewModel)
        }

        return item
    }

    func collectionView(_ collectionView: NSCollectionView, shouldChangeItemsAt indexPaths: Set<IndexPath>, to highlightState: NSCollectionViewItem.HighlightState) -> Set<IndexPath> {
        return Set<IndexPath>()
    }

}
