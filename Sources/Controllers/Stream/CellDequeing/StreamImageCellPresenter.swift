//
//  StreamImageCellPresenter.swift
//  Ello
//
//  Created by Sean on 2/18/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation

public struct StreamImageCellPresenter {
    private static let padding: CGFloat = 15

    static func configure(
        cell:UICollectionViewCell,
        streamCellItem:StreamCellItem,
        streamKind: StreamKind,
        indexPath: NSIndexPath,
        currentUser: User?)
    {
        if let cell = cell as? StreamImageCell {
            if let photoData = streamCellItem.data as? ImageRegion {
                cell.imageLeftContraint.constant = 0
                cell.imageRightConstraint.constant = 0
                var photoToLoad: NSURL?
                if let asset = photoData.asset where asset.isGif && !asset.isLargeGif {
                    photoToLoad = asset.optimized?.url
                }
                else if streamKind.isGridLayout {
                    photoToLoad = photoData.asset?.gridLayoutAttachment?.url

                    var screenWidth = (UIScreen.screenWidth() - 10.0) / 2
                    if let assetWidth = photoData.asset?.gridLayoutAttachment?.width {
                        let width = CGFloat(assetWidth)
                        if width < screenWidth {
                            cell.imageRightConstraint.constant = screenWidth - width
                        }
                    }
                }
                else {
                    photoToLoad = photoData.asset?.oneColumnAttachment?.url

                    var screenWidth = UIScreen.screenWidth()
                    if let assetWidth = photoData.asset?.oneColumnAttachment?.width {
                        let width = CGFloat(assetWidth)
                        if width < (screenWidth - padding * 2) {
                            cell.imageLeftContraint.constant = padding
                            cell.imageRightConstraint.constant = screenWidth - width - padding
                        }
                    }
                }

                if let photoURL = photoToLoad {
                    cell.serverProvidedAspectRatio = StreamImageCellSizeCalculator.aspectRatioForImageRegion(photoData)
                    cell.setImageURL(photoURL)
                }
                else if let photoURL = photoData.url {
                    cell.setImageURL(photoURL)
                }
                cell.hideBorder()
                // Repost specifics
                if streamCellItem.data?.isRepost == true {
                    cell.leadingConstraint.constant = 30.0
                    cell.showBorder()
                }
                else if let comment = streamCellItem.jsonable as? Comment {
                    cell.leadingConstraint.constant = StreamTextCellPresenter.commentMargin
                }
                else {
                    cell.leadingConstraint.constant = 0.0
                }
            }
        }
    }

}
