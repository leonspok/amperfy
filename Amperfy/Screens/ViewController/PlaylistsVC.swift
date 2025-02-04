//
//  PlaylistsVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 09.03.19.
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

import UIKit
import CoreData
import AmperfyKit
import PromiseKit

class PlaylistsVC: SingleFetchedResultsTableViewController<PlaylistMO> {

    private var fetchedResultsController: PlaylistFetchedResultsController!
    private var sortButton: UIBarButtonItem!
    private var sortType: PlaylistSortType = .name
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.userStatistics.visited(.playlists)
        
        change(sortType: appDelegate.storage.settings.playlistsSortSetting)

        var searchTiles: [String]? = nil
        if appDelegate.backendApi.selectedApi == .ampache {
            searchTiles = ["All", "Cached", "User", "Smart"]
        } else if appDelegate.backendApi.selectedApi == .subsonic {
            searchTiles = ["All", "Cached"]
        }
        configureSearchController(placeholder: "Search in \"Playlists\"", scopeButtonTitles: searchTiles)
        tableView.register(nibName: PlaylistTableCell.typeName)
        tableView.rowHeight = PlaylistTableCell.rowHeight
        
        self.refreshControl?.addTarget(self, action: #selector(Self.handleRefresh), for: UIControl.Event.valueChanged)
        
        containableAtIndexPathCallback = { (indexPath) in
            return self.fetchedResultsController.getWrappedEntity(at: indexPath)
        }
        swipeCallback = { (indexPath, completionHandler) in
            let playlist = self.fetchedResultsController.getWrappedEntity(at: indexPath)
            firstly {
                playlist.fetch(storage: self.appDelegate.storage, librarySyncer: self.appDelegate.librarySyncer, playableDownloadManager: self.appDelegate.playableDownloadManager)
            }.catch { error in
                self.appDelegate.eventLogger.report(topic: "Playlist Sync", error: error)
            }.finally {
                completionHandler(SwipeActionContext(containable: playlist))
            }
        }
    }
    
    func change(sortType: PlaylistSortType) {
        self.sortType = sortType
        appDelegate.storage.settings.playlistsSortSetting = sortType
        singleFetchedResultsController?.clearResults()
        tableView.reloadData()
        fetchedResultsController = PlaylistFetchedResultsController(coreDataCompanion: appDelegate.storage.main, sortType: sortType, isGroupedInAlphabeticSections: sortType == .name)
        singleFetchedResultsController = fetchedResultsController
        tableView.reloadData()
        updateRightBarButtonItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRightBarButtonItems()
        guard appDelegate.storage.settings.isOnlineMode else { return }
        firstly {
            self.appDelegate.librarySyncer.syncDownPlaylistsWithoutSongs()
        }.catch { error in
            self.appDelegate.eventLogger.report(topic: "Playlists Sync", error: error)
        }
    }
    
    func updateRightBarButtonItems() {
        sortButton = UIBarButtonItem(title: "Sort", primaryAction: nil, menu: createSortButtonMenu())
        navigationItem.rightBarButtonItems = [editButtonItem, sortButton]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PlaylistTableCell = dequeueCell(for: tableView, at: indexPath)
        let playlist = fetchedResultsController.getWrappedEntity(at: indexPath)
        cell.display(playlist: playlist, rootView: self)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlist = fetchedResultsController.getWrappedEntity(at: indexPath)
        performSegue(withIdentifier: Segues.toPlaylistDetail.rawValue, sender: playlist)
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let playlist = fetchedResultsController.getWrappedEntity(at: indexPath)
        let playlistId = playlist.id
        self.appDelegate.storage.main.library.deletePlaylist(playlist)
        self.appDelegate.storage.main.saveContext()
        firstly {
            self.appDelegate.librarySyncer.syncUpload(playlistIdToDelete: playlistId)
        }.catch { error in
            self.appDelegate.eventLogger.report(topic: "Playlist Upload Deletion", error: error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.toPlaylistDetail.rawValue {
            let vc = segue.destination as! PlaylistDetailVC
            let playlist = sender as? Playlist
            vc.playlist = playlist
        }
    }
    
    private func createSortButtonMenu() -> UIMenu {
        let sortByName = UIAction(title: "Name", image: sortType == .name ? .check : nil, handler: { _ in
            self.change(sortType: .name)
            self.updateSearchResults(for: self.searchController)
        })
        let sortByLastTimePlayed = UIAction(title: "Last time played", image: sortType == .lastPlayed ? .check : nil, handler: { _ in
            self.change(sortType: .lastPlayed)
            self.updateSearchResults(for: self.searchController)
        })
        let sortByChangeDate = UIAction(title: "Change date", image: sortType == .lastChanged ? .check : nil, handler: { _ in
            self.change(sortType: .lastChanged)
            self.updateSearchResults(for: self.searchController)
        })
        return UIMenu(children: [sortByName, sortByLastTimePlayed, sortByChangeDate])
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        firstly {
            self.appDelegate.librarySyncer.syncDownPlaylistsWithoutSongs()
        }.catch { error in
            self.appDelegate.eventLogger.report(topic: "Playlists Sync", error: error)
        }.finally {
            self.refreshControl?.endRefreshing()
        }
    }

    override func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        let playlistSearchCategory = PlaylistSearchCategory(rawValue: searchController.searchBar.selectedScopeButtonIndex) ?? PlaylistSearchCategory.defaultValue
        fetchedResultsController.search(searchText: searchText, playlistSearchCategory: playlistSearchCategory)
        tableView.reloadData()
    }
    
}
