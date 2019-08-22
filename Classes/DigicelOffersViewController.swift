//
//  DigicelOffersViewController.swift
//  DigicelLoginPlugin
//
//  Created by MSApps on 22/08/2019.
//

import UIKit

class DigicelOffersViewController: UIViewController {

    public var delegate: DigicelBaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func offersCloseBtnDidPress(_ sender: UIButton) {
        if let delegate = delegate{
            delegate.userDidSelectToClose()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}
