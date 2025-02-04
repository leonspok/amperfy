//
//  UtilitiesExtensions.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 06.06.22.
//  Copyright (c) 2022 Maximilian Bauer. All rights reserved.
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
import AmperfyKit
import SwiftUI

extension MarqueeLabel {
    func applyAmperfyStyle() {
        if trailingBuffer != 30.0 {
            self.trailingBuffer = 30.0
        }
        if leadingBuffer != 0.0 {
            self.leadingBuffer = 0.0
        }
        if animationDelay != 2.0 {
            self.animationDelay = 2.0
        }
        if type != .continuous {
            self.type = .continuous
        }
        if speed.value != 30.0 {
            self.speed = .rate(30.0)
        }
        if fadeLength != 10.0 {
            self.fadeLength = 10.0
        }
    }
}

extension Color {
    static let error = Color.red
    static let success = Color.green
    
    // MARK: - Text Colors
    static let lightText = Color(UIColor.lightText)
    static let darkText = Color(UIColor.darkText)
    static let placeholderText = Color(UIColor.placeholderText)

    // MARK: - Label Colors
    static let label = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)

    // MARK: - Background Colors
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Fill Colors
    static let systemFill = Color(UIColor.systemFill)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)
    
    // MARK: - Grouped Background Colors
    static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
    
    // MARK: - Gray Colors
    static let systemGray = Color(UIColor.systemGray)
    static let systemGray2 = Color(UIColor.systemGray2)
    static let systemGray3 = Color(UIColor.systemGray3)
    static let systemGray4 = Color(UIColor.systemGray4)
    static let systemGray5 = Color(UIColor.systemGray5)
    static let systemGray6 = Color(UIColor.systemGray6)
    
    // MARK: - Other Colors
    static let separator = Color(UIColor.separator)
    static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    static let link = Color(UIColor.link)
    
    // MARK: System Colors
    static let systemBlue = Color(UIColor.systemBlue)
    static let systemPurple = Color(UIColor.systemPurple)
    static let systemGreen = Color(UIColor.systemGreen)
    static let systemYellow = Color(UIColor.systemYellow)
    static let systemOrange = Color(UIColor.systemOrange)
    static let systemPink = Color(UIColor.systemPink)
    static let systemRed = Color(UIColor.systemRed)
    static let systemTeal = Color(UIColor.systemTeal)
    static let systemIndigo = Color(UIColor.systemIndigo)
}

extension Image {
    static let plus = Image(systemName: "plus")
    static let checkmark = Image(systemName: "checkmark")
}

public func withPopupAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
    try withAnimation(.easeInOut(duration: 0.2)) {
        try body()
    }
}

extension View {
    var appDelegate: AppDelegate {
        return (UIApplication.shared.delegate as! AppDelegate)
    }
}

extension UIView {
    static let forceTouchClickLimit: Float = 1.0

    func normalizedForce(touches: Set<UITouch>) -> Float? {
        guard is3DTouchAvailable, let touch = touches.first else { return nil }
        let maximumForce = touch.maximumPossibleForce
        let force = touch.force
        let normalizedForce = (force / maximumForce)
        return Float(normalizedForce)
    }
    
    func isForceClicked(_ touches: Set<UITouch>) -> Bool {
        guard let force = normalizedForce(touches: touches) else { return false }
        if force < UIView.forceTouchClickLimit {
            return false
        } else {
            return true
        }
    }
    
    var is3DTouchAvailable: Bool {
        return  forceTouchCapability() == .available
    }
    
    func forceTouchCapability() -> UIForceTouchCapability {
        return UIApplication.shared.mainWindow?.rootViewController?.traitCollection.forceTouchCapability ?? .unknown
    }
    
    public func setBackgroundBlur(style: UIBlurEffect.Style, alpha: CGFloat = 1.0) {
        self.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = alpha
        blurEffectView.frame = self.frame
        self.insertSubview(blurEffectView, at: 0)
    }
}

extension UITableView {
    func register(nibName: String) {
        self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: nibName)
    }
    
    func dequeueCell<CellType: UITableViewCell>(for tableView: UITableView, at indexPath: IndexPath) -> CellType {
        guard let cell = self.dequeueReusableCell(withIdentifier: CellType.typeName, for: indexPath) as? CellType else {
            os_log(.error, "The dequeued cell is not an instance of %s", CellType.typeName)
            return CellType()
        }
        return cell
    }
}

extension UITableViewController {
    func dequeueCell<CellType: UITableViewCell>(for tableView: UITableView, at indexPath: IndexPath) -> CellType {
        return self.tableView.dequeueCell(for: tableView, at: indexPath)
    }
    
    func refreshAllVisibleCells() {
        let visibleIndexPaths = tableView.visibleCells.compactMap{ tableView.indexPath(for: $0) }
        tableView.reloadRows(at: visibleIndexPaths, with: .none)
    }
    
    func exectueAfterAnimation(body: @escaping () -> Void) {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                body()
            }
        }
    }
}

extension UIViewController {
    var typeName: String {
        return Self.typeName
    }
}

extension UIApplication {
    var mainWindow: UIWindow? {
        return windows.first(where: \.isKeyWindow)
    }
}

extension UIImage {
    static let plus = UIImage(systemName: "plus") ?? UIImage()
    static let check = UIImage(systemName: "checkmark") ?? UIImage()
    static let backwardFill = UIImage(systemName: "backward.fill") ?? UIImage()
    static let forwardFill = UIImage(systemName: "forward.fill") ?? UIImage()
    static let goBackward15 = UIImage(systemName: "gobackward.15") ?? UIImage()
    static let goForward30 = UIImage(systemName: "goforward.30") ?? UIImage()
    static let redo = UIImage(systemName: "gobackward") ?? UIImage()
    static let clear = UIImage(systemName: "clear") ?? UIImage()
    static let cancleDownloads = UIImage(systemName: "xmark.icloud") ?? UIImage()
    
    private static func createEmptyImage(with size: CGSize) -> UIImage?
    {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    static func numberToImage(number: Int) -> UIImage {
        let fontSize = 40.0
        let textFont = UIFont(name: "Helvetica Bold", size: fontSize)!

        let image = createEmptyImage(with: CGSize(width: 100.0, height: 100.0)) ?? UIImage()
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: UIColor.lightGray,
        ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

        let textPoint = CGPoint(x: 0.0, y: 50.0-(fontSize/2))
        let rect = CGRect(origin: textPoint, size: image.size)
        number.description.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}

extension UITraitCollection {
    static let maxDisplayScale = UITraitCollection(displayScale: 3.0)
}

extension UIImage {
    func carPlayImage(carTraitCollection traits: UITraitCollection) -> UIImage {
        let imageAsset = UIImageAsset()
        imageAsset.register(self, with: traits)
        return imageAsset.image(with: traits)
    }
}

/// This fixes in swiftui mutliple picker views side by side to overlapp their touch areas
/// This is effective in addition to use .clipped() which only fixes the overlapping area visually
extension UIPickerView {
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric , height: 150)
    }
}
