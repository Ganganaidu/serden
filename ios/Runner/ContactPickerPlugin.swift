import ContactsUI
import Flutter
import UIKit

class ContactPickerPlugin: NSObject, FlutterPlugin, CNContactPickerDelegate {
  private var pendingResult: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ContactPickerPlugin()
    let channel = FlutterMethodChannel(
      name: "com.serden/contact_picker",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickContact" else {
      result(FlutterMethodNotImplemented)
      return
    }
    pendingResult = result

    let picker = CNContactPickerViewController()
    picker.delegate = self

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      // Use the scene-based API (iOS 13+) to find the key window
      let keyWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }

      guard let window = keyWindow else {
        self.pendingResult?(nil)
        self.pendingResult = nil
        return
      }

      // Walk the presented-VC chain to find the topmost visible controller
      var topVC = window.rootViewController
      while let presented = topVC?.presentedViewController {
        topVC = presented
      }

      guard let presentingVC = topVC else {
        self.pendingResult?(nil)
        self.pendingResult = nil
        return
      }

      presentingVC.present(picker, animated: true)
    }
  }

  // MARK: - CNContactPickerDelegate

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }

  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    // Fetch full details so phones/emails/addresses are populated
    let keysToFetch: [CNKeyDescriptor] = [
      CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
      CNContactEmailAddressesKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactPostalAddressesKey as CNKeyDescriptor,
    ]

    var fullContact = contact
    if !contact.areKeysAvailable(keysToFetch) {
      let store = CNContactStore()
      fullContact = (try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch)) ?? contact
    }

    var data: [String: Any] = [:]
    data["displayName"] = CNContactFormatter.string(from: fullContact, style: .fullName) ?? ""

    if let email = fullContact.emailAddresses.first {
      data["email"] = email.value as String
    }

    var phones: [[String: String]] = []
    for phone in fullContact.phoneNumbers {
      let label = phone.label ?? ""
      phones.append(["label": label, "number": phone.value.stringValue])
    }
    data["phones"] = phones

    if let addr = fullContact.postalAddresses.first {
      data["street"] = addr.value.street
      data["subLocality"] = addr.value.subLocality
      data["city"] = addr.value.city
      data["state"] = addr.value.state
      data["postalCode"] = addr.value.postalCode
    }

    pendingResult?(data)
    pendingResult = nil
  }
}
