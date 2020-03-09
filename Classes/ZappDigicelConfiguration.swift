//
//  ZappDigicelConfiguration.swift
//  DigicelLoginPlugin
//
//  Created by Miri on 26/07/2019.
//

import UIKit
import ZappPlugins

public struct ZappDigicelConfiguration {
    let helpURL: URL?
    let facebookLoginSupported: Bool
    let restoreSupported: Bool
    let couponRedeemAvailable: Bool
    let localization: ZappDigicelLoginLocalization
    
    public let cleengOfferId: String?
    public let premiumAuthId: String?

    public init(configuration: [String: Any]) {
        if let help = (configuration["cleeng_login_help_url"] as? String), help.isEmpty == false {
            self.helpURL = URL(string: help)
        }
        else { self.helpURL = nil }
        
        self.facebookLoginSupported = Bool(configuration["cleeng_login_facebook_login_available"]) ?? true
        self.restoreSupported = Bool(configuration["cleeng_login_purchase_restore_available"]) ?? true
        self.couponRedeemAvailable = Bool(configuration["cleeng_login_redeem_coupon_available"]) ?? false
        
        self.cleengOfferId = configuration["Sportsmax_offer_id"] as? String
        self.premiumAuthId = configuration["digicel_user_access_auth_id"] as? String
                
        self.localization = ZappDigicelLoginLocalization(configuration: configuration)
    }
    
    public enum AssetKey : String {
        case logo = "cleeng_login_logo"
        case loginBackground_default = "cleeng_login_background_image_default"
        case loginBackground_height568 = "cleeng_login_background_image_568h"
        case loginBackground_height667 = "cleeng_login_background_image_667h"
        case loginBackground_height736 = "cleeng_login_background_image_736h"
        case loginBackground_height812 = "cleeng_login_background_image_812h"
        case loginBackground_height1366 = "cleeng_login_background_image_1366h"
        case loginBackground_iPadLandscape = "cleeng_login_background_image_landscape"
        case backIcon = "cleeng_login_back_button"
        case closeIcon = "cleeng_login_close_button"
        case subscriptionBackground = "cleeng_login_subscription_component"
        case subscriptionPromotion = "cleeng_login_promotion_icon"
        case alertBackground = "cleeng_login_alert_component"
        case confirmButtonBackground = "cleeng_login_confirm_button"
        case overlayBackground = "cleeng_login_overlay"
        case subscriptionShadow = "cleeng_login_subscription_shadow"
        case buttonDisabledState = "cleeng_login_non_selected_state_button"
    }
    
    public enum ColorKey : String {
        case backgroundColor = "cleeng_login_bg_color"
        case bottomBackgroundColor = "cleeng_login_bottom_background_color"
        case bottomLegalBackgroundColor = "cleeng_login_bottom_legal_background_color"
        case offersListGradientVerticalColor = "cleeng_login_offers_gradient_color"
        case loadingIndicatorColor = "cleeng_login_loading_indicator_color"
    }
    
    public enum StyleKey : String {
        case defaultText = "cleeng_login_default_text"
        case actionDescription = "cleeng_login_action_description_text"
        case actionText = "cleeng_login_action_text"
        case actionAlternativeText = "cleeng_login_action_alternative_text"
        case loginTitle = "cleeng_login_title"
        case loginDetails = "cleeng_login_details"
        case loginDescription = "cleeng_login_description_text"
        case subscriptionTitle = "cleeng_login_subscription_title"
        case subscriptionText = "cleeng_login_subscription_text"
        case subscriptionTagText = "cleeng_login_subscription_tag_text"
        case moreDetails = "cleeng_login_more_details_text"
        case legalText = "cleeng_login_legal_text"
        case subscriptionDetails = "cleeng_login_subsription_details_text"
        case alertTitle = "cleeng_login_alert_title"
        case alertDescription = "cleeng_login_alert_description"
        case confirmButton = "cleeng_login_confirm_button_text"
        case buttonDisabledState = "cleeng_login_non_selected_state_button_text"
        case cleengLoginVoucher = "cleeng_login_voucher"
    }
}

public struct ZappDigicelLoginLocalization {
    public enum Key : String {
        case subscriptionTitle = "cleeng_login_subscription_title_text"
        case legal = "cleeng_login_legal"
        case alertConfirmTitle = "cleeng_login_confirm_title"
        case alertConfirmMessage = "cleeng_login_confirm_message"
        case alertConfirmAction = "cleeng_login_confirm_button_title"
        case subscribeAction = "cleeng_login_subscribe"
        
        case alertCancelAction = "cleeng_login_alert_cancel_action"
        case alertContactUsAction = "cleeng_login_alert_contact_us_action"
        case alertRetryAction = "cleeng_login_alert_retry_action"
        case alertOKAction = "cleeng_login_alert_ok_action"
        
        case logutSuccessfully = "logout_successfully_message"
        case alreadyLogin = "already_login_error_message"
        case alreadyLogout = "already_logout_error_message"
        case errorInternalTitle = "cleeng_login_error_internal_title"
        case errorInvalideCustomerDataOrPasswordMissingTitle = "cleeng_login_error_credentials_title"
        case errorExpiredTokenTitle = "cleeng_login_error_expired_title"
        case errorUserAlreadyExistTitle = "cleeng_login_error_existing_user_credentials_title"
        case errorBadEmailOrPasswordTitle = "cleeng_login_error_invalid_credentials_title"
        
        case errorInternalMessage = "cleeng_login_error_internal_message"
        case errorInvalideEmailFormatMessage = "cleeng_login_invalide_email_entered_message"
        case errorEmailRequiredMessage = "cleeng_login_error_email_required_message"
        case errorPasswordRequiredMessage = "cleeng_login_error_password_required_message"
        case errorInvalidEmailOrUserNotExistMessage = "cleeng_login_error_invalid_email_credentials_message"
        case errorInvalideCustomerDataOrPasswordMissingMessage = "cleeng_login_error_credentials_message"
        case errorExpiredTokenMessage = "cleeng_login_error_expired_message"
        case errorUserAlreadyExistMessage = "cleeng_login_error_existing_user_credentials_message"
        
        case welcomeScreenDigicelTitle = "digicel_welcome_screen_title"
        case welcomeScreenDigicelSecondTitle = "digicel_welcome_screen_second_title"
        case welcomeScreenDigicelSecondTitleColor = "digicel_welcome_screen_second_title_color"
        case welcomeScreenDigicelTitleSize = "digicel_welcome_screen_title_size"
        case welcomeScreenDigicelTitleColor = "digicel_welcome_screen_title_color"
        case welcomeScreenDigicelTitleFont = "digicel_welcome_screen_title_font"
        case welcomeScreenDigicelDescription = "digicel_welcome_screen_description"
        case welcomeScreenDigicelDescriptionSize = "digicel_welcome_screen_description_size"
        case welcomeScreenDigicelDescriptionColor = "digicel_welcome_screen_description_color"
        case welcomeScreenDigicelDescriptionFont = "digicel_welcome_screen_description_font"
        case welcomeScreenDigicelLoginBtn = "digicel_welcome_screen_login_button_text"
        case welcomeScreenDigicelRegisterBtn = "digicel_welcome_screen_create_account_button_text"
        case welcomeScreenDigicelBtnSize = "digicel_welcome_screen_button_text_size"
        case welcomeScreenDigicelBtnColor = "digicel_welcome_screen_button_text_color"
        case welcomeScreenDigicelBtnFont = "digicel_welcome_screen_button_text_font"
    }
    
    public  func setLabelStyle(label: UILabel, colorForKey: ZappDigicelLoginLocalization.Key, fontSizeKey: ZappDigicelLoginLocalization.Key, fontNameKey: ZappDigicelLoginLocalization.Key){
           if let colorKey = configuration[colorForKey.rawValue] as? String, !colorKey.isEmptyOrWhitespace(){
               let color = UIColor(argbHexString: colorKey)
               label.textColor = color
           }
           
           if let fontSizeString = configuration[fontSizeKey.rawValue] as? String, let fontName = configuration[fontNameKey.rawValue] as? String
           , let fontSize = CGFloat(fontSizeString), let font = UIFont(name: fontName, size: CGFloat(fontSize)){
             label.font = font
           }
       }
       
       //set text to label from plugin configuration
       public  func setLabelText(label: UILabel, textKey: ZappDigicelLoginLocalization.Key){
           if let labelText = configuration[textKey.rawValue] as? String, !labelText.isEmptyOrWhitespace(){
               label.text = labelText
           }
       }
       
       //set color, font and size to button from plugin configuration
       public  func setButtonStyle(button: UIButton, colorForKey: ZappDigicelLoginLocalization.Key, fontSizeKey: ZappDigicelLoginLocalization.Key, fontNameKey: ZappDigicelLoginLocalization.Key){
           if let colorKey = configuration[colorForKey.rawValue] as? String, !colorKey.isEmptyOrWhitespace(){
               let color = UIColor(argbHexString: colorKey)
               button.setTitleColor(color, for: .normal)
           }
           
           if let fontSizeString = configuration[fontSizeKey.rawValue] as? String, let fontName = configuration[fontNameKey.rawValue] as? String
               , let fontSize = CGFloat(fontSizeString) ,let font = UIFont(name: fontName, size: CGFloat(fontSize)){
              button.titleLabel?.font = font
           }
       }
       
       //set text to label from plugin configuration
       public  func setButtonText(button: UIButton, textKey: ZappDigicelLoginLocalization.Key){
           if let labelText = configuration[textKey.rawValue] as? String, !labelText.isEmptyOrWhitespace(){
               button.setTitle(labelText, for: .normal)
           }
       }
       
       //set color to view from plugin configuration
       public  func setViewColor(view: UIView, colorKey:ZappDigicelLoginLocalization.Key){
           if let colorString = configuration[colorKey.rawValue] as? String , let color = UIColor(argbHexString: colorString){
               view.backgroundColor = color
           }
       }
       
       //set image to imageView from plugin configuration
       public  func setImageView(imageView: UIImageView, bundle: Bundle,key: ZappDigicelLoginLocalization.Key){
           if let image = UIImage(named: key.rawValue, in: bundle, compatibleWith: nil){
               imageView.image = image
           }
       }
       
       //set image to button from plugin configuration
       public  func setButtonImage(button: UIButton, bundle: Bundle,key: ZappDigicelLoginLocalization.Key){
           if let image = UIImage(named: key.rawValue, in: bundle, compatibleWith: nil){
              button.setImage(image, for: .normal)
           }
       }
       
       //set image BG to button from plugin configuration
       public  func setButtonBGImage(button: UIButton, bundle: Bundle,key: ZappDigicelLoginLocalization.Key){
           if let image = UIImage(named: key.rawValue, in: bundle, compatibleWith: nil){
               button.setBackgroundImage(image, for: .normal)
           }
       }
    
    private let configuration: [String:Any]
    init(configuration: [String:Any]) {
        self.configuration = configuration
    }
    
    public func localizedString(for key: Key, defaultString: String? = nil) -> String? {
        return (configuration[key.rawValue] as? String) ?? defaultString
    }
    
    public func offerLocalizedTagString(for offerIdOrCoupon: String) -> String? {
        guard let dict = (configuration["cleeng_login_offer_id_to_tag_text"] as? String)?.toDicationaryOfStrings else {
            return nil
        }
        
        return dict[offerIdOrCoupon]
    }
    
    public static func errorTitleLocalizationKey(forCode errorCode: Int) -> Key {
        switch errorCode {
        case 10: return .errorInvalidEmailOrUserNotExistMessage
        case 11: return .errorInvalideCustomerDataOrPasswordMissingTitle
        case 12: return .errorExpiredTokenTitle
        case 13: return .errorUserAlreadyExistTitle
        default: return .errorInternalTitle
        }
    }
    
    public static func errorMessageLocalizationKey(forCode errorCode: Int) -> Key {
        switch errorCode {
        case 10: return .errorInvalidEmailOrUserNotExistMessage
        case 11: return .errorInvalideCustomerDataOrPasswordMissingMessage
        case 12: return .errorExpiredTokenMessage
        case 13: return .errorUserAlreadyExistMessage
        default: return .errorInternalMessage
        }
    }
}

extension ZAAppConnector {
    func image(forAsset asset: ZappDigicelConfiguration.AssetKey?) -> UIImage? {
        guard let asset = asset else {
            return nil
        }
        
        if let image = UIImage(named: asset.rawValue) {
            return image
        } else if let image = UIImage(named: asset.rawValue, in: self.layoutsStylesDelegate.zappLayoutsStylesBundle(), compatibleWith: nil) {
            return image
        } else if let url = self.urlDelegate.fileUrl(withName: asset.rawValue, extension: "png") {
            if let image = UIImage(contentsOfFile: url.path) ?? UIImage(contentsOfFile: url.absoluteString) {
                return image
            } else if let data = try? Data(contentsOf: url) , let image = UIImage(data: data, scale: 0) {
                return image
            } else {
                return nil
            }
        }
        else { return nil }
    }
}

extension UIView {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      withBackgroundColor color: ZappDigicelConfiguration.ColorKey) {
        manager.setViewStyle?(self, withKeys: [kZappLayoutStylesBackgroundColorKey : color.rawValue])
    }
}

extension UIImageView {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      withAsset asset: ZappDigicelConfiguration.AssetKey,
                      stretchableImage: Bool = false) {
        manager.setViewStyle?(self, withKeys: [kZappLayoutStylesBackgroundImageKey : asset.rawValue])
        if stretchableImage , let image = self.image {
            let halfSize = CGSize(width: (image.size.width * 0.5) - 0.5, height: (image.size.height * 0.5) - 0.5)
            self.image = image.resizableImage(withCapInsets: UIEdgeInsets(top: halfSize.height, left: halfSize.width, bottom: halfSize.height, right: halfSize.width))
        }
    }
}

extension UILabel {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      text: String? = nil,
                      style: ZappDigicelConfiguration.StyleKey? = nil) {
        
        var keys: [String:String] = [:]
        if let style = style { keys[kZappLayoutStylesFontKey] = style.rawValue }
        
        manager.setLabelStyle?(self, withKeys: keys)
        self.text = text
    }
    
    func setAttributedZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                                attributedText: [(style: ZappDigicelConfiguration.StyleKey?, string: String, additionalAttributes: [NSAttributedString.Key : Any]?)]) {
        let str = NSMutableAttributedString(string: "")
        for index in 0..<attributedText.count {
            let subText = attributedText[index]
            
            var attrs: [NSAttributedString.Key : Any] = subText.additionalAttributes ?? [:]
            if let style = subText.style?.rawValue , let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: style) as? [String:Any] {
                if let font = dict["font"] as? UIFont { attrs[.font] = font }
                if let color = dict["color"] as? UIColor { attrs[.foregroundColor] = color }
            }
            
            let space = (index + 1 < attributedText.count ? " " : "")
            str.append(NSAttributedString(string: "\(subText.string)\(space)", attributes: attrs))
        }
        
        self.attributedText = str
    }
}

extension UIButton {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      withIconAsset iconAsset: ZappDigicelConfiguration.AssetKey? = nil,
                      backgroundAsset: ZappDigicelConfiguration.AssetKey? = nil,
                      title: String? = nil,
                      style: ZappDigicelConfiguration.StyleKey? = nil,
                      forState state: UIControl.State = .normal) {
        
        if let iconAsset = iconAsset , let imageIcon = ZAAppConnector.sharedInstance().image(forAsset: iconAsset) {
            self.setImage(imageIcon, for: state)
        }
        
        
        if let style = style?.rawValue , let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: style) as? [String:Any] {
            if state == .normal , let font = dict["font"] as? UIFont {
                self.titleLabel?.font = font
            }
            
            if let color = dict["color"] as? UIColor {
                self.setTitleColor(color, for: state)
            }
        }
        
        self.setTitle(title, for: state)
        
        if var image = ZAAppConnector.sharedInstance().image(forAsset: backgroundAsset) {
            let halfSize = CGSize(width: (image.size.width * 0.5) - 0.5, height: (image.size.height * 0.5) - 0.5)
            image = image.resizableImage(withCapInsets: UIEdgeInsets(top: halfSize.height, left: halfSize.width, bottom: halfSize.height, right: halfSize.width))
            self.setBackgroundImage(image, for: state)
        }
    }
    
    func setAttributedZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      withIconAsset iconAsset: ZappDigicelConfiguration.AssetKey? = nil,
                      backgroundAsset: ZappDigicelConfiguration.AssetKey? = nil,
                      attributedTitle: [(style: ZappDigicelConfiguration.StyleKey?, string: String, additionalAttributes: [NSAttributedString.Key : Any]?)]? = nil,
                      forState state: UIControl.State = .normal) {
        
        if let iconAsset = iconAsset , let imageIcon = ZAAppConnector.sharedInstance().image(forAsset: iconAsset) {
            self.setImage(imageIcon, for: state)
        }
        
        let str = NSMutableAttributedString(string: "")
        if let attributedTitle = attributedTitle {
            for index in 0..<attributedTitle.count {
                let subTitle = attributedTitle[index]
                
                var attrs: [NSAttributedString.Key : Any] = subTitle.additionalAttributes ?? [:]
                if let style = subTitle.style?.rawValue , let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: style) as? [String:Any] {
                    if let font = dict["font"] as? UIFont { attrs[.font] = font }
                    if let color = dict["color"] as? UIColor { attrs[.foregroundColor] = color }
                }
                
                let space = (index + 1 < attributedTitle.count ? " " : "")
                str.append(NSAttributedString(string: "\(subTitle.string)\(space)", attributes: attrs))
            }
        }
        
        setAttributedTitle(str, for: state)
        
        if var image = ZAAppConnector.sharedInstance().image(forAsset: backgroundAsset) {
            let halfSize = CGSize(width: (image.size.width * 0.5) - 0.5, height: (image.size.height * 0.5) - 0.5)
            image = image.resizableImage(withCapInsets: UIEdgeInsets(top: halfSize.height, left: halfSize.width, bottom: halfSize.height, right: halfSize.width))
            self.setBackgroundImage(image, for: state)
        }
    }
}

extension UITextField {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      textStyle: ZappDigicelConfiguration.StyleKey? = nil,
                      placeholder: String? = nil) {
        
        var placeholderStyle: [String:Any]?
        if let style = textStyle?.rawValue , let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: style) as? [String:Any] {
            placeholderStyle = dict
            self.font = dict["font"] as? UIFont
            self.textColor = dict["color"] as? UIColor
        }
        
        if let placeholder = placeholder {
            if let placeholderStyle = placeholderStyle {
                var attrs: [NSAttributedString.Key : Any] = [:]
                if let font = placeholderStyle["font"] as? UIFont { attrs[.font] = font }
                if let color = placeholderStyle["color"] as? UIColor { attrs[.foregroundColor] = color.withAlphaComponent(0.6) }
                attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attrs)
            } else {
                self.placeholder = placeholder
            }
        } else {
            self.placeholder = nil
        }
    }
}

extension UITextView {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      text: String? = nil,
                      style: ZappDigicelConfiguration.StyleKey? = nil) {
        
        let temp = self.isEditable
        self.isEditable = true
        if let style = style?.rawValue , let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: style) as? [String:Any] {
            self.font = dict["font"] as? UIFont
            self.textColor = dict["color"] as? UIColor
        }
        
        self.text = text
        self.isEditable = temp
    }
    
    func setAttributedZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                                attributedText: [(style: ZappDigicelConfiguration.StyleKey?, string: String, additionalAttributes: [NSAttributedString.Key : Any]?)]) {
        
        let temp = self.isEditable
        self.isEditable = true
        
        let str = NSMutableAttributedString(string: "")
        for index in 0..<attributedText.count {
            let subText = attributedText[index]
            
            var attrs: [NSAttributedString.Key : Any] = subText.additionalAttributes ?? [:]
            if let style = subText.style?.rawValue , let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: style) as? [String:Any] {
                if let font = dict["font"] as? UIFont { attrs[.font] = font }
                if let color = dict["color"] as? UIColor { attrs[.foregroundColor] = color }
            }
            
            let space = (index + 1 < attributedText.count ? " " : "")
            str.append(NSAttributedString(string: "\(subText.string)\(space)", attributes: attrs))
        }
        
        self.attributedText = str
        self.isEditable = temp
    }
}

extension UIActivityIndicatorView {
    func setZappStyle(using manager: ZAAppDelegateConnectorLayoutsStylesProtocol,
                      withColor color: ZappDigicelConfiguration.ColorKey) {
        if let dict = ZAAppConnector.sharedInstance().layoutsStylesDelegate.styleParams?(byStyleName: color.rawValue) as? [String:Any] , let color = dict["color"] as? UIColor {
            self.color = color
        }
        else { self.color = nil }
    }
}

fileprivate extension String {
    
    var toDicationaryOfStrings: [String:String]? {
        let list = self.components(separatedBy: ";").map({ (str) -> String in
            return str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }).filter({ (str) -> Bool in return !(str.isEmpty) })
        
        if list.isEmpty { return nil }
        
        var map: [String:String] = [:]
        for item in list {
            let arr = item.components(separatedBy: "=").map({ (str) -> String in
                return str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }).filter({ (str) -> Bool in return !(str.isEmpty) })
            
            guard arr.count == 2 else { continue }
            
            let key = arr[0]
            let value = arr[1]
            map[key] = value
        }
        
        return map
    }
}

extension Bool {
    init?(_ val: Any?) {
        if let value = val as? Bool {
            self = value
        } else if let num = val as? Int {
            self = (num == 1)
        } else if let str = val as? String {
            self = (str == "1")
        }
        else { return nil }
    }
}
