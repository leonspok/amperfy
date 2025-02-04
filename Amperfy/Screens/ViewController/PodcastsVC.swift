//
//  PodcastsVC.swift
//  Amperfy
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

import UIKit
import CoreData
import AmperfyKit
import PromiseKit

class PodcastsVC: BasicTableViewController {

    private var podcastsFetchedResultsController: PodcastFetchedResultsController!
    private var episodesFetchedResultsController: PodcastEpisodesReleaseDateFetchedResultsController!
    private var sortButton: UIBarButtonItem!
    private var showType: PodcastsShowType = .podcasts
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.userStatistics.visited(.podcasts)
        
        podcastsFetchedResultsController = PodcastFetchedResultsController(coreDataCompanion: appDelegate.storage.main, isGroupedInAlphabeticSections: false)
        podcastsFetchedResultsController.delegate = self
        episodesFetchedResultsController = PodcastEpisodesReleaseDateFetchedResultsController(coreDataCompanion: appDelegate.storage.main, isGroupedInAlphabeticSections: false)
        episodesFetchedResultsController.delegate = self

        configureSearchController(placeholder: "Search in \"Podcasts\"", scopeButtonTitles: ["All", "Cached"])
        tableView.register(nibName: GenericTableCell.typeName)
        tableView.register(nibName: PodcastEpisodeTableCell.typeName)
        
        swipeDisplaySettings.playContextTypeOfElements = .podcast
        containableAtIndexPathCallback = { (indexPath) in
            switch self.showType {
            case .podcasts:
                return self.podcastsFetchedResultsController.getWrappedEntity(at: indexPath)
            case .episodesSortedByReleaseDate:
                return self.episodesFetchedResultsController.getWrappedEntity(at: indexPath)
            }
        }
        swipeCallback = { (indexPath, completionHandler) in
            switch self.showType {
            case .podcasts:
                let podcast = self.podcastsFetchedResultsController.getWrappedEntity(at: indexPath)
                firstly {
                    podcast.fetch(storage: self.appDelegate.storage, librarySyncer: self.appDelegate.librarySyncer, playableDownloadManager: self.appDelegate.playableDownloadManager)
                }.catch { error in
                    self.appDelegate.eventLogger.report(topic: "Podcast Sync", error: error)
                }.finally {
                    completionHandler(SwipeActionContext(containable: podcast))
                }
            case .episodesSortedByReleaseDate:
                let episode = self.episodesFetchedResultsController.getWrappedEntity(at: indexPath)
                completionHandler(SwipeActionContext(containable: episode))
            }
        }
        
        showType = appDelegate.storage.settings.podcastsShowSetting
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRightBarButtonItems()
        syncFromServer()
    }
    
    func updateRightBarButtonItems() {
        sortButton = UIBarButtonItem(title: "Sort", primaryAction: nil, menu: createSortButtonMenu())
        navigationItem.rightBarButtonItem = sortButton
    }
    
    func syncFromServer() {
        if appDelegate.storage.settings.isOnlineMode {
            switch self.showType {
            case .podcasts:
                firstly {
                    self.appDelegate.librarySyncer.syncDownPodcastsWithoutEpisodes()
                }.catch { error in
                    self.appDelegate.eventLogger.report(topic: "Podcasts Sync", error: error)
                }
            case .episodesSortedByReleaseDate:
                firstly {
                    self.appDelegate.librarySyncer.syncDownPodcastsWithoutEpisodes()
                }.then { () -> Promise<Void> in
                    let podcasts = self.appDelegate.storage.main.library.getPodcasts().filter{ $0.remoteStatus == .available }
                    let podcastFetchPromises = podcasts.compactMap { podcast in return {
                        podcast.fetch(storage: self.appDelegate.storage, librarySyncer: self.appDelegate.librarySyncer, playableDownloadManager: self.appDelegate.playableDownloadManager)
                    }}
                    return podcastFetchPromises.resolveSequentially()
                }.catch { error in
                    self.appDelegate.eventLogger.report(topic: "Podcasts Sync", error: error)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.showType {
        case .podcasts:
            return podcastsFetchedResultsController.sections?[0].numberOfObjects ?? 0
        case .episodesSortedByReleaseDate:
            return episodesFetchedResultsController.sections?[0].numberOfObjects ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.showType {
        case .podcasts:
            let cell: GenericTableCell = dequeueCell(for: tableView, at: indexPath)
            let podcast = podcastsFetchedResultsController.getWrappedEntity(at: indexPath)
            cell.display(container: podcast, rootView: self)
            return cell
        case .episodesSortedByReleaseDate:
            let cell: PodcastEpisodeTableCell = dequeueCell(for: tableView, at: indexPath)
            let episode = episodesFetchedResultsController.getWrappedEntity(at: indexPath)
            cell.display(episode: episode, rootView: self)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.showType {
        case .podcasts:
            return GenericTableCell.rowHeight
        case .episodesSortedByReleaseDate:
            return PodcastEpisodeTableCell.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.showType {
        case .podcasts:
            let podcast = podcastsFetchedResultsController.getWrappedEntity(at: indexPath)
            performSegue(withIdentifier: Segues.toPodcastDetail.rawValue, sender: podcast)
        case .episodesSortedByReleaseDate:
            break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.toPodcastDetail.rawValue {
            let vc = segue.destination as! PodcastDetailVC
            let podcast = sender as? Podcast
            vc.podcast = podcast
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        switch self.showType {
        case .podcasts:
            let searchText = searchController.searchBar.text ?? ""
            podcastsFetchedResultsController.search(searchText: searchText, onlyCached: searchController.searchBar.selectedScopeButtonIndex == 1)
            tableView.reloadData()
        case .episodesSortedByReleaseDate:
            let searchText = searchController.searchBar.text ?? ""
            episodesFetchedResultsController.search(searchText: searchText, onlyCachedSongs: searchController.searchBar.selectedScopeButtonIndex == 1)
            tableView.reloadData()
        }
    }
    
    private func createSortButtonMenu() -> UIMenu {
        let podcastsSortByName = UIAction(title: "Podcasts sorted by name", image: showType == .podcasts ? .check : nil, handler: { _ in
            self.showType = .podcasts
            self.appDelegate.storage.settings.podcastsShowSetting = .podcasts
            self.syncFromServer()
            self.updateRightBarButtonItems()
            self.updateSearchResults(for: self.searchController)
        })
        let episodesSortByReleaseDate = UIAction(title: "Episodes sorted by release date", image: showType == .episodesSortedByReleaseDate ? .check : nil, handler: { _ in
            self.showType = .episodesSortedByReleaseDate
            self.appDelegate.storage.settings.podcastsShowSetting = .episodesSortedByReleaseDate
            self.syncFromServer()
            self.updateRightBarButtonItems()
            self.updateSearchResults(for: self.searchController)
        })
        return UIMenu(children: [podcastsSortByName, episodesSortByReleaseDate])
    }

}
