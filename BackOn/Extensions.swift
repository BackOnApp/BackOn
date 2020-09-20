//
//  Extensions.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 13/04/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import CoreLocation

extension URL {
    init?(string: String?) {
        if string != nil {
            self.init(string: string!)
        } else {
            return nil
        }
    }
}

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }
}

class ViewWrapper<Content:View>: UIView {
    let body: UIHostingController<Content>
    init(_ rootView: Content) {
        body = UIHostingController(rootView: rootView)
        super.init(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoder init not implemented!!")
    }
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        body.view.translatesAutoresizingMaskIntoConstraints = false
        body.view.frame = bounds
        body.view.backgroundColor = nil
        addSubview(body.view)
        NSLayoutConstraint.activate([
            body.view.topAnchor.constraint(equalTo: topAnchor),
            body.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            body.view.leftAnchor.constraint(equalTo: leftAnchor),
            body.view.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        sizeToFit()
    }
}

class HostingController<Content:View>: UIHostingController<Content>, UIAdaptivePresentationControllerDelegate {
    let hideStatusBar: Bool
    
    init(
        _ contentView: Content,
        hideStatusBar: Bool = false,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        preventModalDismiss: Bool = false
    ) {
        self.hideStatusBar = hideStatusBar
        super.init(rootView: contentView)
        self.modalPresentationStyle = modalPresentationStyle
        self.isModalInPresentation = preventModalDismiss
        self.presentationController?.delegate = PresentationDelegate.shared
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
}

class PresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
    static let shared = PresentationDelegate()
    override private init() {
        super.init()
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        let alertToPresent = UIAlertController(title: "You edited some fields", message: "Do you do want to discard changes?", preferredStyle: .alert)
        let action = UIAlertAction(title: "Discard", style: .destructive) { _ in
            presentationController.presentedViewController.dismiss()
        }
        alertToPresent.view.tintColor = .systemOrange
        alertToPresent.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertToPresent.addAction(action)
        presentationController.presentedViewController.present(alertToPresent)
    }
}

extension UIViewController {
    func toggleEditMode(observedVar: Binding<Bool>) {
        isEditing ? setEditing(false, animated: true) : setEditing(true, animated: true)
        observedVar.wrappedValue.toggle()
        isModalInPresentation = isEditing
    }
    
    func setEditMode(observedVar: Binding<Bool>, value: Bool) {
        setEditing(value, animated: true)
        observedVar.wrappedValue = value
        isModalInPresentation = value
    }
    
    func present(_ toPresent: UIViewController) {
        DispatchQueue.main.async { self.present(toPresent, animated: true, completion: nil) }
    }
    
    func dismiss() {
        DispatchQueue.main.async { self.dismiss(animated: true, completion: nil) }
    }
    
    static var main: UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
    
    static var foremost: UIViewController {
        var toReturn = UIViewController.main
        while toReturn.presentedViewController != nil {
            toReturn = toReturn.presentedViewController!
        }
        return toReturn
    }
}

extension Binding where Value == PresentationMode {
    func dismiss() {
        wrappedValue.dismiss()
    }
}
