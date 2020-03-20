//
//  PhotoCell.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-18.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit

protocol DeleteCell {
    func delete(index: IndexPath)
}

class PhotoCell: UICollectionViewCell {
    
    //Custom xib file to create the cell
    
    @IBOutlet weak var image: UIImageView!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    //Containing the actual image
    func cellWithImage(imageFetched: UIImage) {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        image.contentMode = .scaleToFill
        image.image = imageFetched
    }
    
    //Sets cell with placeholder while images load
    func cellWithPlaceHolder() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        image.contentMode = .scaleToFill
        image.image = UIImage(named: "placeholder")

    }
    
    var index: IndexPath?
    var delegate: DeleteCell?
    
    @IBAction func buttonTapped(_ sender: Any) {
        delegate!.delete(index: index!)
    }
    
}
