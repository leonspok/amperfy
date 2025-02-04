//
//  Song.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 30.12.19.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
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

public class Song: AbstractPlayable, Identifyable {

    public let managedObject: SongMO

    public init(managedObject: SongMO) {
        self.managedObject = managedObject
        super.init(managedObject: managedObject)
    }

    public var album: Album? {
        get {
            guard let albumMO = managedObject.album else { return nil }
            return Album(managedObject: albumMO)
        }
        set {
            if managedObject.album != newValue?.managedObject { managedObject.album = newValue?.managedObject }
        }
    }
    public var artist: Artist? {
        get {
            guard let artistMO = managedObject.artist else { return nil }
            return Artist(managedObject: artistMO)
        }
        set {
            if managedObject.artist != newValue?.managedObject { managedObject.artist = newValue?.managedObject }
        }
    }
    public var genre: Genre? {
        get {
            guard let genreMO = managedObject.genre else { return nil }
            return Genre(managedObject: genreMO) }
        set {
            if managedObject.genre != newValue?.managedObject { managedObject.genre = newValue?.managedObject }
        }
    }
    public var isOrphaned: Bool {
        guard let album = album else { return true }
        return album.isOrphaned
    }

    override public var creatorName: String {
        return artist?.name ?? "Unknown Artist"
    }
    
    public var detailInfo: String {
        var info = displayString
        info += " ("
        let albumName = album?.name ?? "-"
        info += "album: \(albumName),"
        let genreName = genre?.name ?? "-"
        info += " genre: \(genreName),"
        
        info += " id: \(id),"
        info += " track: \(track),"
        info += " year: \(year),"
        info += " remote duration: \(remoteDuration),"
        let diskInfo =  disk ?? "-"
        info += " disk: \(diskInfo),"
        info += " size: \(size),"
        let contentTypeInfo = contentType ?? "-"
        info += " contentType: \(contentTypeInfo),"
        info += " bitrate: \(bitrate)"
        info += ")"
        return info
    }
    
    override public func infoDetails(for api: BackenApiType, type: DetailType) -> [String] {
        var infoContent = [String]()
        if type == .long {
            if track > 0 {
                infoContent.append("Track \(track)")
            }
            if duration > 0 {
                infoContent.append("\(duration.asDurationString)")
            }
            if year > 0 {
                infoContent.append("Year \(year)")
            } else if let albumYear = album?.year, albumYear > 0 {
                infoContent.append("Year \(albumYear)")
            }
            if let genre = genre {
                infoContent.append("Genre: \(genre.name)")
            }
            if bitrate > 0 {
                infoContent.append("Bitrate \(bitrate)")
            }
        }
        return infoContent
    }
    
    public var identifier: String {
        return title
    }

}

extension Array where Element: Song {
    
    public func filterServerDeleteUncachedSongs() -> [Element] {
        // See also SongMO.excludeServerDeleteUncachedSongsFetchPredicate()
        return self.filter{ (($0.size > 0) && ($0.album?.remoteStatus == .available)) || ($0.isCached) }
    }
    
    public func filterCached() -> [Element] {
        return self.filter{ $0.isCached }
    }
    
    public func filterCustomArt() -> [Element] {
        return self.filter{ $0.artwork != nil }
    }
    
    public var hasCachedSongs: Bool {
        return self.lazy.filter{ $0.isCached }.first != nil
    }
    
    public func sortByTrackNumber() -> [Element] {
        return self.sorted{ $0.track < $1.track }
    }
    
    public func sortByAlbum() -> [Element] {
        return self.sorted {
            if $0.album?.year != $1.album?.year {
                return $0.album?.year ?? 0 < $1.album?.year ?? 0
            } else if $0.album?.id != $1.album?.id {
                return $0.album?.id ?? "" < $1.album?.id ?? ""
            } else if $0.disk != $1.disk {
                return $0.disk ?? "" < $1.disk ?? ""
            } else if $0.track != $1.track {
                return $0.track < $1.track
            } else if $0.title != $1.title {
                return $0.title < $1.title
            } else {
                return $0.id < $1.id
            }
        }
    }

}
