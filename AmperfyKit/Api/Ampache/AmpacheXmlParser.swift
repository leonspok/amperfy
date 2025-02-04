//
//  AmpacheXmlParser.swift
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

class AmpacheXmlParser: GenericXmlParser {
    
    var error: ResponseError?
    private var statusCode: Int = 0
    private var message = ""

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        
        switch(elementName) {
        case "error":
            statusCode = Int(attributeDict["errorCode"] ?? "0") ?? 0
        default:
            break
        }
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch(elementName) {
        case "errorMessage":
            message = buffer
        case "error":
            error = ResponseError(statusCode: statusCode, message: message)
        default:
            break
        }
        
        super.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
    }

}

class AmpacheNotifiableXmlParser: AmpacheXmlParser {
    
    var parseNotifier: ParsedObjectNotifiable?
    
    init(parseNotifier: ParsedObjectNotifiable? = nil) {
        self.parseNotifier = parseNotifier
    }
    
}

class AmpacheXmlLibParser: AmpacheNotifiableXmlParser {
    
    var library: LibraryStorage
    
    init(library: LibraryStorage, parseNotifier: ParsedObjectNotifiable? = nil) {
        self.library = library
        super.init(parseNotifier: parseNotifier)
    }
    
    func parseArtwork(urlString: String) -> Artwork? {
        guard let artworkRemoteInfo = AmpacheXmlServerApi.extractArtworkInfoFromURL(urlString: urlString) else { return nil }
        if let foundArtwork = library.getArtwork(remoteInfo: artworkRemoteInfo) {
            return foundArtwork
        } else {
            let createdArtwork = library.createArtwork()
            createdArtwork.remoteInfo = artworkRemoteInfo
            createdArtwork.url = urlString
            return createdArtwork
        }
    }
    
}
