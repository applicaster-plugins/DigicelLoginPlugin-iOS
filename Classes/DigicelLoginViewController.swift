//
//  DigicelLoginViewController.swift
//  DigicelLoginPlugin
//
//  Created by MSApps on 20/11/2019.
//

import UIKit

class DigicelLoginViewController: UIViewController {
    
    var loginProtocol:LoginProtocol?
    var configuration:ZappDigicelConfiguration?

    @IBOutlet weak var BGimage: UIImageView!
    @IBOutlet weak var loginTitle: UILabel!
    @IBOutlet weak var loginSecondTitle: UILabel!
    @IBOutlet weak var loginDescription: UILabel!
    @IBOutlet weak var logoImge: UIImageView!
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var LogInBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView(){
        if let config = configuration {
            config.localization.setLabelText(label: loginTitle, textKey: .welcomeScreenDigicelTitle)
            config.localization.setLabelText(label: loginSecondTitle, textKey: .welcomeScreenDigicelSecondTitle)
            config.localization.setLabelStyle(label: loginSecondTitle, colorForKey:.welcomeScreenDigicelSecondTitleColor, fontSizeKey: .welcomeScreenDigicelTitleSize, fontNameKey: .welcomeScreenDigicelTitleFont)
            config.localization.setLabelStyle(label: loginTitle, colorForKey:.welcomeScreenDigicelTitleColor, fontSizeKey: .welcomeScreenDigicelTitleSize, fontNameKey: .welcomeScreenDigicelTitleFont)
            config.localization.setLabelText(label: loginDescription, textKey: .welcomeScreenDigicelDescription)
            config.localization.setLabelStyle(label: loginDescription, colorForKey:.welcomeScreenDigicelDescriptionColor, fontSizeKey: .welcomeScreenDigicelDescriptionSize, fontNameKey: .welcomeScreenDigicelDescriptionFont)
            config.localization.setButtonText(button: LogInBtn, textKey: .welcomeScreenDigicelLoginBtn)
            config.localization.setButtonText(button: createAccountBtn, textKey: .welcomeScreenDigicelRegisterBtn)
            config.localization.setButtonStyle(button: LogInBtn, colorForKey: .welcomeScreenDigicelBtnColor, fontSizeKey: .welcomeScreenDigicelBtnSize, fontNameKey: .welcomeScreenDigicelBtnFont)
            config.localization.setButtonStyle(button: createAccountBtn, colorForKey: .welcomeScreenDigicelBtnColor, fontSizeKey: .welcomeScreenDigicelBtnSize, fontNameKey: .welcomeScreenDigicelBtnFont)
            BGimage.image = UIImage(named: "login_bg")
            logoImge.image = UIImage(named: "login_logo")
            LogInBtn.setBackgroundImage(UIImage(named: "button_bg"), for: .normal)
            createAccountBtn.setBackgroundImage(UIImage(named: "button_bg"), for: .normal)
            closeBtn.setImage(UIImage(named: "cleeng_login_close_button"), for: .normal)
            closeBtn.tintColor = UIColor.black
        }
    }
    
    @IBAction func closeBtnDidPress(_ sender: UIButton) {
        if let delegate = loginProtocol {
            delegate.closeLoginScreen()
        }
    }
    
    @IBAction func createAccountDidPress(_ sender: UIButton) {
        if let delegate = loginProtocol {
            delegate.actionSelected(register: true)
        }
    }
    
    @IBAction func LogInDidPress(_ sender: UIButton) {
        if let delegate = loginProtocol {
            delegate.actionSelected(register: false)
        }
    }
}

protocol LoginProtocol {
    func actionSelected(register: Bool)
    func closeLoginScreen()
}
