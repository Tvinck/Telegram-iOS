import Foundation
import UIKit
import Display

public final class TeleXLockScreen: UIViewController, UITextFieldDelegate {
    
    private let blurEffectView: UIVisualEffectView
    private let textField: UITextField
    private let titleLabel: UILabel
    
    public init() {
        let blurEffect = UIBlurEffect(style: .dark)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        self.textField = UITextField()
        self.titleLabel = UILabel()
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        
        self.blurEffectView.frame = self.view.bounds
        self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.blurEffectView)
        
        self.titleLabel.text = "Введите пароль"
        self.titleLabel.textColor = .white
        self.titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        self.titleLabel.textAlignment = .center
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.titleLabel)
        
        self.textField.isSecureTextEntry = true
        self.textField.keyboardType = .numberPad
        self.textField.textAlignment = .center
        self.textField.textColor = .white
        self.textField.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        self.textField.tintColor = .white
        self.textField.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        self.textField.layer.cornerRadius = 12
        self.textField.clipsToBounds = true
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.textField.delegate = self
        self.view.addSubview(self.textField)
        
        NSLayoutConstraint.activate([
            self.titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -60),
            
            self.textField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.textField.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20),
            self.textField.widthAnchor.constraint(equalToConstant: 160),
            self.textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.becomeFirstResponder()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField.text == "2580" {
            UserDefaults.standard.set(true, forKey: "TeleXUnlocked")
            UserDefaults.standard.synchronize()
            textField.resignFirstResponder()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
