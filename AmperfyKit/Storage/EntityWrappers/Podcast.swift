//
//  Podcast.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 25.06.21.
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
import CoreData
import UIKit
import PromiseKit

public class Podcast: AbstractLibraryEntity {
    
    public let managedObject: PodcastMO
    
    public init(managedObject: PodcastMO) {
        self.managedObject = managedObject
        super.init(managedObject: managedObject)
    }
    
    public var identifier: String {
        return title
    }
    public var title: String {
        get { return managedObject.title ?? "Unknown Podcast" }
        set {
            if managedObject.title != newValue {
                managedObject.title = newValue
                updateAlphabeticSectionInitial(section: newValue)
            }
        }
    }
    public var depiction: String {
        get { return managedObject.depiction ?? "" }
        set { if managedObject.depiction != newValue { managedObject.depiction = newValue } }
    }
    public var episodes: [PodcastEpisode] {
        guard let episodesSet = managedObject.episodes, let episodesMO = episodesSet.array as? [PodcastEpisodeMO] else { return [PodcastEpisode]() }
        return episodesMO.compactMap{ PodcastEpisode(managedObject: $0) }.filter{ $0.userStatus != .deleted }.sortByPublishDate()
    }
    override public var defaultImage: UIImage {
        return UIImage.podcastArtwork
    }

}

extension Podcast: PlayableContainable  {
    public var name: String { return title }
    public var subtitle: String? { return nil }
    public var subsubtitle: String? { return nil }
    public func infoDetails(for api: BackenApiType, type: DetailType) -> [String] {
        var infoContent = [String]()
        if episodes.count == 1 {
            infoContent.append("1 Episode")
        } else if episodes.count > 1 {
            infoContent.append("\(episodes.count) Episodes")
        }
        if type == .long {
            if isCompletelyCached {
                infoContent.append("Cached")
            }
            let completeDuration = episodes.reduce(0, {$0 + $1.duration})
            if completeDuration > 0 {
                infoContent.append("\(completeDuration.asDurationString)")
            }
        }
        return infoContent
    }
    public var playables: [AbstractPlayable] {
        return episodes
    }
    public var playContextType: PlayerMode { return .podcast }
    public func fetchFromServer(storage: PersistentStorage, librarySyncer: LibrarySyncer, playableDownloadManager: DownloadManageable) -> Promise<Void> {
        AutoDownloadLibrarySyncer(storage: storage,
                                  librarySyncer: librarySyncer,
                                  playableDownloadManager: playableDownloadManager)
        .syncLatestPodcastEpisodes(podcast: self).asVoid()
    }
    public func remoteToggleFavorite(syncer: LibrarySyncer) -> Promise<Void> {
        return Promise<Void>(error: BackendError.notSupported)
    }
    public var artworkCollection: ArtworkCollection {
        return ArtworkCollection(defaultImage: defaultImage, singleImageEntity: self)
    }
}

extension Podcast: Hashable, Equatable {
    public static func == (lhs: Podcast, rhs: Podcast) -> Bool {
        return lhs.managedObject == rhs.managedObject && lhs.managedObject == rhs.managedObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(managedObject)
    }
}
