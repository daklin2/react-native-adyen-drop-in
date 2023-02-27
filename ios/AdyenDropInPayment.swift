//
//  AdyenDropInPayment.swift
//  ReactNativeAdyenDropin
//
//  Created by 罗立树 on 2019/9/27.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Adyen
import Foundation
import SafariServices
import PassKit

@objc(AdyenDropInPayment)
class AdyenDropInPayment: RCTEventEmitter {
  func dispatch(_ closure: @escaping () -> Void) {
    if Thread.isMainThread {
      closure()
    } else {
      DispatchQueue.main.async(execute: closure)
    }
  }

    func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    var dropInComponent: DropInComponent?
    var applePayComponent: ApplePayComponent?
    var threeDS2Component: ThreeDS2Component?
    var apiContext: APIContext?
    var configuration: DropInComponent.Configuration?
    var publicKey: String?
    var merchantIdentifier: String?
    var env: Environment?
    var isDropIn:Bool?
    var envName: String?

    override func supportedEvents() -> [String]! {
        return [
          "onPaymentFail",
          "onPaymentProvide",
          "onPaymentSubmit",
        ]
    }
    
    private var presentingController: UIViewController?
}

extension AdyenDropInPayment: DropInComponentDelegate {
    func didComplete(from component: DropInComponent) {}
    
    @objc func configPayment(_ publicKey: String, env: String, showsStorePaymentMethodField: Bool = false, merchantIdentifier: String = "") {
      self.publicKey = publicKey
      self.merchantIdentifier = merchantIdentifier
      envName = env
      
      let applePayConfiguration = ApplePayComponent.Configuration(summaryItems: [], merchantIdentifier: merchantIdentifier)
        
      switch env {
        case "live":
          self.env = .live
          apiContext = APIContext(environment: Environment.live, clientKey: publicKey)
        default:
          self.env = .test
          apiContext = APIContext(environment: Environment.test, clientKey: publicKey)
      }
      configuration = DropInComponent.Configuration(apiContext: apiContext!)
      configuration?.card.showsStorePaymentMethodField = showsStorePaymentMethodField
      configuration?.applePay = applePayConfiguration
    }

    @objc func setApplePayPaymentSummaryItem(_ totalValue: String, label: String) {
      let decimalValue = Decimal(Double(totalValue) ?? 0)
      let summaryItems = [
          PKPaymentSummaryItem(label: label, amount: decimalValue as NSDecimalNumber, type: .final),
      ]
      self.configuration?.applePay?.summaryItems = summaryItems
    }
    
    @objc func setPaymentAmount(_ totalValue: String, currencyIso: String, countryCode: String) {
      let decimalValue = Decimal(Double(totalValue) ?? 0)
      let payment = Payment(amount: Amount(value: decimalValue , currencyCode: currencyIso),
                                  countryCode: countryCode)
      self.configuration?.payment = payment
    }
    
   @objc func encryptCard(_ cardNumber: String,expiryMonth:Int, expiryYear:Int,securityCode:String,resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock)  {
//       let card = CardEncryptor.Card(number: cardNumber,
//                                     securityCode: securityCode,
//                                     expiryMonth:  String(expiryMonth),
//                                     expiryYear: "20" + String(expiryYear))
//    let encryptedCard = try? CardEncryptor.encryptedCard(for: card, publicKey: self.publicKey!)
//
//
//    if (encryptedCard != nil) {
//         let resultMap:Dictionary? = [
//            "encryptedNumber":encryptedCard?.number,
//           "encryptedExpiryMonth":encryptedCard?.expiryMonth,
//           "encryptedExpiryYear":encryptedCard?.expiryYear,
//           "encryptedSecurityCode":encryptedCard?.securityCode,
//         ]
//         resolve(resultMap)
//    }
   }

  @objc func paymentMethods(_ paymentMethodsJson: String) {
    self.isDropIn = true
    let jsonData: Data? = paymentMethodsJson.data(using: String.Encoding.utf8) ?? Data()
    let paymentMethods: PaymentMethods? = try? JSONDecoder().decode(PaymentMethods.self, from: jsonData!)
    let dropInComponent = DropInComponent(paymentMethods: paymentMethods!, configuration: self.configuration!)
    self.dropInComponent = dropInComponent
    dropInComponent.delegate = self
    
    dispatch {
        if let controller = UIApplication.getTopViewController() {
            self.presentingController = controller
            controller.present(dropInComponent.viewController, animated: true)
        }
    }
  }
    
    func didSubmit(_ data: PaymentComponentData, for paymentMethod: PaymentMethod, from component: DropInComponent) {
        let jsonData = try? JSONEncoder().encode(data.paymentMethod.encodable)
        var paymentMethodDictionaryData = try? JSONSerialization.jsonObject(with: jsonData!, options: .mutableContainers) as? [String:AnyObject]
        
        paymentMethodDictionaryData!["recurringDetailReference"] = paymentMethodDictionaryData!["storedPaymentMethodId"]
        let resultData = [
            "paymentMethod": paymentMethodDictionaryData,
            "storePaymentMethod": data.storePaymentMethod
        ] as [String: Any]

        sendEvent(
          withName: "onPaymentSubmit",
          body: [
            "isDropIn": self.isDropIn,
            "env": self.envName,
            "data": resultData,
          ]
        )
    }

  /// Invoked when additional details have been provided for a payment method.
  ///
  /// - Parameters:
  ///   - data: The additional data supplied by the drop in component..
  ///   - component: The drop in component from which the additional details were provided.
  func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
    component.viewController.dismiss(animated: true)
      let details = try? JSONSerialization.jsonObject(with: try JSONEncoder().encode(data.details.encodable), options: [])
      
      if let paymentDetails = details {
        let resultData = [
            "details": paymentDetails,
            "paymentData": data.paymentData
        ] as [String: Any]
        
        sendEvent(
          withName: "onPaymentProvide",
          body: [
            "isDropIn": self.isDropIn,
            "env": self.envName,
            "data": resultData,
          ]
        )
      }
  }

  /// Invoked when the drop in component failed with an error.
  ///
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - component: The drop in component that failed.
  func didFail(with error: Error, from component: DropInComponent) {
    component.viewController.dismiss(animated: true)
    sendEvent(
      withName: "onPaymentFail",
      body: [
        "isDropIn": self.isDropIn,
        "env": self.envName,
        "msg": error.localizedDescription,
        "error": String(describing: error),
      ]
    )
  }

  func didCancel() {
    sendEvent(
      withName: "onPaymentFail",
      body: [
        "isDropIn": self.isDropIn as Any,
        "env": self.envName as Any,
        "msg": "cancelled",
        "error": "cancelled",
      ]
    )
  }
}

extension AdyenDropInPayment: PaymentComponentDelegate {
  func getStoredCardPaymentMethod(_ paymentMethods: PaymentMethods, index: Int) -> StoredCardPaymentMethod {
    var paymentMethod: StoredCardPaymentMethod?
    if paymentMethods.stored.count == 1 {
      return paymentMethods.stored[0] as! StoredCardPaymentMethod
    }
    if paymentMethods.stored.count > 1 {
      paymentMethod = paymentMethods.stored[index] as! StoredCardPaymentMethod
    }
    return paymentMethod!
  }

  func getCardPaymentMethodByName(_ paymentMethods: PaymentMethods, name _: String) -> CardPaymentMethod {
    var paymentMethod: CardPaymentMethod?
    if paymentMethods.regular.count == 1 {
      return paymentMethods.regular[0] as! CardPaymentMethod
    }
    if paymentMethods.regular.count > 1 {
      for p in paymentMethods.regular {
        if p.name == "Credit Card" {
          paymentMethod = (p as! CardPaymentMethod)
          break
        }
      }
    }
    return paymentMethod!
  }

  /// Invoked when the payment component finishes, typically by a user submitting their payment details.
  ///
  /// - Parameters:
  ///   - data: The data supplied by the payment component.
  ///   - component: The payment component from which the payment details were submitted.
  func didSubmit(_ data: PaymentComponentData, from _: PaymentComponent) {
      let resultData = ["paymentMethod": data.paymentMethod, "storePaymentMethod": data.storePaymentMethod] as [String: Any]

      sendEvent(
        withName: "onPaymentSubmit",
        body: [
          "isDropIn": self.isDropIn,
          "env": self.envName,
          "data": resultData,
        ]
      )
      
    
  }

  /// Invoked when the payment component fails.
  ///
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - component: The payment component that failed.
  func didFail(with error: Error, from _: PaymentComponent) {
//    customCardComponent?.viewController.dismiss(animated: true)

    sendEvent(
      withName: "onPaymentFail",
      body: [
        "isDropIn": self.isDropIn,
        "env": self.envName,
        "msg": error.localizedDescription,
        "error": String(describing: error),
      ]
    )
  }
}

extension AdyenDropInPayment: ActionComponentDelegate {
    func didComplete(from component: ActionComponent) {
        
    }
    
  @objc func handleAction(_ actionJson: String) {
    if(actionJson == nil||actionJson.count<=0){
        return;
    }
    var parsedJson = actionJson.replacingOccurrences(of: "THREEDS2FINGERPRINT", with: "threeDS2Fingerprint")
    parsedJson = actionJson.replacingOccurrences(of: "THREEDS2CHALLENGE", with: "threeDS2Challenge")
    parsedJson = actionJson.replacingOccurrences(of: "REDIRECT", with: "redirect")
    if(self.isDropIn!){
        let actionData: Data? = parsedJson.data(using: String.Encoding.utf8) ?? Data()
        let action = try? JSONDecoder().decode(Action.self, from: actionData!)
        DispatchQueue.main.sync {
            self.dropInComponent?.handle(action!)
        }
      return;
    }
    let actionData: Data? = parsedJson.data(using: String.Encoding.utf8) ?? Data()
    let action:Action? = try! JSONDecoder().decode(Action.self, from: actionData!)

    switch action {
    /// Indicates the user should be redirected to a URL.
    case .redirect(let executeAction):
        let redirectComponent:RedirectComponent = RedirectComponent(apiContext: apiContext!)
       redirectComponent.delegate = self
      break;
      /// Indicates a 3D Secure device fingerprint should be taken.
    case .threeDS2Fingerprint(let executeAction):
      if(self.threeDS2Component == nil){
          self.threeDS2Component = ThreeDS2Component(apiContext: apiContext!)
        self.threeDS2Component!.delegate = self
      }
      self.threeDS2Component!.handle(executeAction)
      break;
      /// Indicates a 3D Secure challenge should be presented.
    case .threeDS2Challenge(let executeAction):
      if(self.threeDS2Component == nil){
          self.threeDS2Component = ThreeDS2Component(apiContext: apiContext!)
        self.threeDS2Component!.delegate = self
      }
      self.threeDS2Component?.handle(executeAction)
      break;
    default :
      break;
    }
  }

  @objc func handlePaymentResult(_ paymentResult: String) {
    
    dispatch {
        if let controller = self.presentingController {
            controller.dismiss(animated: true, completion: nil)
        }
    }
  }

  /// Invoked when the action component finishes
  /// and provides the delegate with the data that was retrieved.
  ///
  /// - Parameters:
  ///   - data: The data supplied by the action component.
  ///   - component: The component that handled the action.
  func didProvide(_ data: ActionComponentData, from _: ActionComponent) {
      let details = try? JSONSerialization.jsonObject(with: try JSONEncoder().encode(data.details.encodable), options: [])
      let resultData = ["details": details, "paymentData": data.paymentData] as [String: Any]
      sendEvent(
        withName: "onPaymentProvide",
        body: [
            "isDropIn": self.isDropIn as Any,
            "env": self.envName as Any,
            "data": resultData,
        ]
    )
  }

  /// Invoked when the action component fails.
  ///
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - component: The component that failed.
  func didFail(with error: Error, from _: ActionComponent) {
    sendEvent(
      withName: "onPaymentFail",
      body: [
        "isDropIn": self.isDropIn as Any,
        "env": self.envName as Any,
        "msg": error.localizedDescription,
        "error": String(describing: error),
      ]
    )
  }
}


extension  UIApplication {
    
    
    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
