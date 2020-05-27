//
//  SyncEngine.swift
//  WWDC
//
//  Created by Guilherme Rambo on 22/04/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import os.log

extension Notification.Name {
    public static let SyncEngineDidSyncSessionsAndSchedule = Notification.Name("SyncEngineDidSyncSessionsAndSchedule")
    public static let SyncEngineDidSyncFeaturedSections = Notification.Name("SyncEngineDidSyncFeaturedSections")
}

public final class SyncEngine {

    private let log = OSLog(subsystem: "ConfCore", category: String(describing: SyncEngine.self))

    public let storage: Storage
    public let client: AppleAPIClient

    #if ICLOUD
    public let userDataSyncEngine: UserDataSyncEngine
    #endif

    private let disposeBag = DisposeBag()

    let transcriptIndexingClient: TranscriptIndexingClient

    public var transcriptLanguage: String {
        get { transcriptIndexingClient.transcriptLanguage }
        set { transcriptIndexingClient.transcriptLanguage = newValue }
    }

    public var isIndexingTranscripts: BehaviorRelay<Bool> { transcriptIndexingClient.isIndexing }
    public var transcriptIndexingProgress: BehaviorRelay<Float> { transcriptIndexingClient.indexingProgress }

    public init(storage: Storage, client: AppleAPIClient, transcriptLanguage: String) {
        self.storage = storage
        self.client = client
        self.transcriptIndexingClient = TranscriptIndexingClient(
            language: transcriptLanguage,
            storage: storage,
            appleClient: client
        )

        #if ICLOUD
        self.userDataSyncEngine = UserDataSyncEngine(storage: storage)
        #endif

        NotificationCenter.default.rx.notification(.SyncEngineDidSyncSessionsAndSchedule).observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] _ in
            self.transcriptIndexingClient.startIndexing(ignoringCache: false)

            #if ICLOUD
            self.userDataSyncEngine.start()
            #endif
        }).disposed(by: disposeBag)
    }

    public func syncContent() {
        client.fetchContent { [unowned self] scheduleResult in
            DispatchQueue.main.async {
                self.storage.store(contentResult: scheduleResult) { error in
                    NotificationCenter.default.post(name: .SyncEngineDidSyncSessionsAndSchedule, object: error)

                    guard error == nil else { return }

                    self.syncFeaturedSections()
                }
            }
        }
    }

    public func syncLiveVideos(completion: (() -> Void)? = nil) {
        client.fetchLiveVideoAssets { [weak self] result in
            DispatchQueue.main.async {
                self?.storage.store(liveVideosResult: result)
                completion?()
            }
        }
    }

    public func syncFeaturedSections() {
        client.fetchFeaturedSections { [weak self] result in
            DispatchQueue.main.async {
                self?.storage.store(featuredSectionsResult: result) { error in
                    NotificationCenter.default.post(name: .SyncEngineDidSyncFeaturedSections, object: error)
                }
            }
        }
    }

}
