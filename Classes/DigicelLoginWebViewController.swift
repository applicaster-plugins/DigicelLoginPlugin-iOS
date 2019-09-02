//
//  DigicelLoginWebViewController.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 20 15/07/2019.
//

import Foundation
import ZappPlugins
import UIKit

class DigicelLoginWebViewController : UIViewController {

    @objc @IBOutlet public weak var webContainerView: UIView!

    @objc @IBOutlet fileprivate weak var backButton: UIButton!
    @objc @IBOutlet fileprivate weak var closeButton: UIButton!
    
    @objc @IBOutlet fileprivate weak var backgroundImageView: UIImageView!
    
    @objc @IBOutlet private weak var logoImageView: UIImageView!
  
    public var delegate: DigicelBaseProtocol?

    public var webLoginVC: UIViewController?
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        return  false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle(nil, for: .normal)
        backButton.backgroundColor = UIColor.clear
        self.navigationController?.delegate = self
        closeButton.setTitle(nil, for: .normal)
        closeButton.backgroundColor = UIColor.clear
        
        addChildViewController(self.webLoginVC ,to:webContainerView)
        
        signConfigureViews()
    }
    
    //MARK: - Setup views
    private func signConfigureViews() {
        guard let stylesManager = ZAAppConnector.sharedInstance().layoutsStylesDelegate else {
            return
        }
        
        backgroundImageView.setupDigicelBackground(with: stylesManager)
        closeButton.setZappStyle(using: stylesManager, withIconAsset: .closeIcon)
        backButton.setZappStyle(using: stylesManager, withIconAsset: .backIcon)
        logoImageView.setZappStyle(using: stylesManager, withAsset: .logo)
    }
    
    @objc @IBAction fileprivate func close() {
        if let delegate = delegate {
            delegate.userDidSelectToClose()
        }
    }
}


extension UIViewController: UINavigationControllerDelegate {
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
