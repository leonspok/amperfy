//
//  BackgroundFetchTriggeredSyncer.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 13.07.21.
//  Copyright (c) 2021 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIKit
import os.log
import PromiseKit

public class BackgroundFetchTriggeredSyncer {
    
    private let storage: PersistentStorage
    private let librarySyncer: LibrarySyncer
    private let notificationManager: LocalNotificationManager
    private let playableDownloadManager: DownloadManageable
    private let log = OSLog(subsystem: "Amperfy", category: "BackgroundFetchTriggeredSyncer")
    
    init(storage: PersistentStorage, librarySyncer: LibrarySyncer, notificationManager: LocalNotificationManager, playableDownloadManager: DownloadManageable) {
        self.storage = storage
        self.librarySyncer = librarySyncer
        self.notificationManager = notificationManager
        self.playableDownloadManager = playableDownloadManager
    }
    
    public func syncAndNotifyPodcastEpisodes() -> Promise<Void> {
        os_log("Perform podcast episode sync", log: self.log, type: .info)
        return firstly {
            self.librarySyncer.syncDownPodcastsWithoutEpisodes()
        }.then { () -> Promise<Void> in
            let podcasts = self.storage.main.library.getPodcasts()
            let podcastNotificationPromises = podcasts.compactMap { podcast in return {
                self.createPodcastNotificationPromise(podcast: podcast)
            }}
            return podcastNotificationPromises.resolveSequentially()
        }
    }
    
    private func createPodcastNotificationPromise(podcast: Podcast) -> Promise<Void> {
        return firstly {
            AutoDownloadLibrarySyncer(storage: self.storage,
                                      librarySyncer: self.librarySyncer,
                                      playableDownloadManager: self.playableDownloadManager)
            .syncLatestPodcastEpisodes(podcast: podcast)
        }.then { addedPodcasts -> Guarantee<Void> in
            for episodeToNotify in addedPodcasts {
                os_log("Podcast: %s, New Episode: %s", log: self.log, type: .info, podcast.title, episodeToNotify.title)
                self.notificationManager.notify(podcastEpisode: episodeToNotify)
            }
            return Guarantee<Void>.value
        }
    }

}
