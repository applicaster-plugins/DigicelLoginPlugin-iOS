//
//  DigicelSubscriptionViewController.swift
//  DigicelLoginPlugin
//
//  Created by MSApps on 01/08/2019.
//

import UIKit

class DigicelSubscriptionViewController: UIViewController {

   
    public var delegate: DigicelBaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

      
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    @IBAction func closeBtnDidPress(_ sender: UIButton) {
        delegate?.userDidSelectToClose()
    }
}
