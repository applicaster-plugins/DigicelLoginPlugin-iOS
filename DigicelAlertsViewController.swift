//
//  DigicelAlertsViewController.swift
//  DigicelLoginPlugin
//
//  Created by MSApps on 05/08/2019.
//

import UIKit
import ZappPlugins

class DigicelAlertsViewController: UIViewController,UIViewControllerTransitioningDelegate {
    
    @objc @IBOutlet weak var alertBackgroundImageView: UIImageView!
    @objc @IBOutlet weak var alertViewComponent: UIView!
    @objc @IBOutlet weak var alertsTitleText: UILabel!
    @objc @IBOutlet weak var alertsDescriptionText: UILabel!
    @objc @IBOutlet weak var alertsActionButton: UIButton!
    
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    @IBAction func alertsActionDidPress(_ sender: UIButton) {
        
    }
    
    
    private func configureViews() {
        guard let stylesManager = ZAAppConnector.sharedInstance().layoutsStylesDelegate else {
            return
        }
        
        alertBackgroundImageView.setZappStyle(using: stylesManager,
                                              withAsset: .alertBackground,
                                              stretchableImage: true)
        alertsTitleText.setZappStyle(using: stylesManager, style: .alertTitle)
        alertsDescriptionText.setZappStyle(using: stylesManager, style: .alertDescription)
        
        
    }
   

}
