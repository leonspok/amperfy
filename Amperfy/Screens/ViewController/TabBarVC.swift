//
//  TabBarVC.swift
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
import Foundation
import LNPopupController
import AmperfyKit

class TabBarVC: UITabBarController {
    
    var appDelegate: AppDelegate!
    var popupPlayer: PopupPlayerVC?
    var isPopupPlayerInitialized = false
    var isPopupBarDisplayed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        appDelegate.player.addNotifier(notifier: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.popupPlayer = PopupPlayerVC.instantiateFromAppStoryboard()
        popupPlayer?.hostingTabBarVC = self
        self.popupBar.tintColor = UIColor.defaultBlue
        self.popupBar.imageView.layer.cornerRadius = 5
        self.popupBar.progressViewStyle = .bottom
        self.popupBar.barStyle = .compact
        self.popupBar.standardAppearance.marqueeScrollEnabled = true
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.firstLineHeadIndent = 40.0
        self.popupBar.standardAppearance.titleTextAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        self.popupBar.standardAppearance.subtitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.defaultBlue,
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        self.popupContentView.popupCloseButtonStyle = .chevron
        self.popupInteractionStyle = .snap
        displayPopupBar()
        
        if !appDelegate.storage.isLibrarySyncInfoReadByUser {
            displaySyncInfo()
        } else {
            displayNotificationAuthorization()
        }
    }
    
    private func handlePopupBar() {
        if appDelegate.player.isPopupBarAllowedToHide {
            hidePopupPlayer()
        } else {
            displayPopupBar()
        }
    }
    
    private func displayPopupBar() {
        guard let popupPlayer = popupPlayer, !isPopupBarDisplayed, !appDelegate.player.isPopupBarAllowedToHide else { return }
        isPopupBarDisplayed = true
        if isPopupPlayerInitialized {
            popupPlayer.reloadData()
        }
        self.presentPopupBar(withContentViewController: popupPlayer, animated: true, completion: nil)
        isPopupPlayerInitialized = true
    }
    
    private func hidePopupPlayer() {
        guard let popupPlayer = popupPlayer, isPopupBarDisplayed else { return }
        isPopupBarDisplayed = false
        popupPlayer.reloadData()
        self.dismissPopupBar(animated: false, completion: nil)
    }
    
    private func displaySyncInfo() {
        let popupVC = LibrarySyncPopupVC.instantiateFromAppStoryboard()
        popupVC.setContent(
            topic: "Synchronization",
            message: "Your music collection is constantly updating. Already synced library items are offline available. If library items (artists/albums/songs) are not shown in your  collection please use the various search functionalities to synchronize with the server.",
            type: .info,
            customIcon: .Sync,
            customAnimation: .rotate,
            onClosePressed: { _ in
                self.appDelegate.storage.isLibrarySyncInfoReadByUser = true
                self.displayNotificationAuthorization()
            }
        )
        appDelegate.display(popup: popupVC)
    }
    
    private func displayNotificationAuthorization() {
        self.appDelegate.localNotificationManager.executeIfAuthorizationHasNotBeenAskedYet {
            DispatchQueue.main.async {
                let popupVC = LibrarySyncPopupVC.instantiateFromAppStoryboard()
                popupVC.setContent(
                    topic: "Notifications",
                    message: "Amperfy can inform you about the latest podcast episodes. If you want to, please authorize Amperfy to send you notifications.",
                    type: .info,
                    customIcon: .Bell,
                    customAnimation: .swing,
                    onClosePressed: { _ in
                        self.appDelegate.localNotificationManager.requestAuthorization()
                    }
                )
                self.appDelegate.display(popup: popupVC)
            }
        }
    }

}

extension TabBarVC: MusicPlayable {
    func didStartPlaying() {
        handlePopupBar()
    }
    func didPause() {
        handlePopupBar()
    }
    func didStopPlaying() {
        handlePopupBar()
    }
    func didElapsedTimeChange() { }
    func didPlaylistChange() {
        handlePopupBar()
    }
    func didArtworkChange() { }
    func didShuffleChange() { }
    func didRepeatChange() { }
}
