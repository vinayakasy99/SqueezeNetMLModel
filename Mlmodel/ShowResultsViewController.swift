//
//  ShowResultsViewController.swift
//  Mlmodel
//
//  Created by vinayaka s yattinahalli on 18/05/20.
//  Copyright © 2020 vinayaka s yattinahalli. All rights reserved.
//

import Foundation
import UIKit

class ShowResultsViewController: UIViewController {
    
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage!
    var prediction: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
        predictionLabel.text = prediction
    }
}
