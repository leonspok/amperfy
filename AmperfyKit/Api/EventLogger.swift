//
//  EventLogger.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 16.05.21.
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

public enum AmperfyLogStatusCode: Int {
    case downloadError = 1
    case playerError = 2
    case emailError = 3
    case internalError = 4
    case connectionError = 5
    case commonError = 6
    case info
}

/// Must be called from main thread
public protocol AlertDisplayable {
    func display(notificationBanner popupVC: UIViewController)
    func display(popup popupVC: UIViewController)
    func createPopupVC(topic: String, message: String, logType: LogEntryType) -> UIViewController
}

public class EventLogger {
    public var supressAlerts = false
    
    private let log = OSLog(subsystem: "Amperfy", category: "EventLogger")
    public var alertDisplayer: AlertDisplayable?
    private let storage: PersistentStorage
    
    init(storage: PersistentStorage) {
        self.storage = storage
    }
    
    public func info(topic: String, message: String, displayPopup: Bool = true) {
        report(topic: topic, statusCode: .info, message: message, logType: .info, displayPopup: displayPopup)
    }
    
    public func info(topic: String, statusCode: AmperfyLogStatusCode, message: String, displayPopup: Bool) {
        report(topic: topic, statusCode: statusCode, message: message, logType: .info, displayPopup: displayPopup)
    }
    
    public func error(topic: String, statusCode: AmperfyLogStatusCode, message: String, displayPopup: Bool) {
        report(topic: topic, statusCode: statusCode, message: message, logType: .error, displayPopup: displayPopup)
    }
     
    private func report(topic: String, statusCode: AmperfyLogStatusCode, message: String, logType: LogEntryType, displayPopup: Bool) {
        saveAndDisplay(topic: topic,
            logType: logType,
            errorType: statusCode,
            statusCode: statusCode.rawValue,
            errorMessage: topic + ": " + message,
            displayPopup: displayPopup,
            popupMessage: message)
    }
    
    public func report(topic: String, error: Error, displayPopup: Bool = true) {
        if let apiError = error as? ResponseError {
            return report(error: apiError, displayPopup: displayPopup)
        }
        saveAndDisplay(topic: topic,
            logType: .error,
            errorType: .commonError,
            statusCode: 0,
            errorMessage: topic + ": " + error.localizedDescription,
            displayPopup: displayPopup,
            popupMessage: error.localizedDescription)
    }
    
    public func report(error: ResponseError, displayPopup: Bool) {
        var alertMessage = ""
        alertMessage += "Status code: \(error.statusCode)"
        alertMessage += "\n\(error.message)"
        
        saveAndDisplay(topic: "API Error",
            logType: .apiError,
            errorType: .connectionError,
            statusCode: error.statusCode,
            errorMessage: "API Error " + error.statusCode.description + ": " + error.message,
            displayPopup: displayPopup,
            popupMessage: alertMessage)
    }
    
    private func saveAndDisplay(topic: String, logType: LogEntryType, errorType: AmperfyLogStatusCode, statusCode: Int, errorMessage: String, displayPopup: Bool, popupMessage: String) {
        os_log("%s", log: self.log, type: .error, errorMessage)
        storage.async.perform { asynCompanion in
            let logEntry = asynCompanion.library.createLogEntry()
            logEntry.type = logType
            logEntry.statusCode = statusCode
            logEntry.message = errorMessage
            asynCompanion.saveContext()
            
            if displayPopup {
                self.displayAlert(topic: topic, message: popupMessage, logType: logType)
            }
        }.catch { error in }
    }
    
    private func displayAlert(topic: String, message: String, logType: LogEntryType) {
        guard let displayer = self.alertDisplayer else { return }
        DispatchQueue.main.async {
            guard !self.supressAlerts else { return }
            let popupVC = displayer.createPopupVC(topic: topic, message: message, logType: logType)
            displayer.display(notificationBanner: popupVC)
        }
    }
    
}
