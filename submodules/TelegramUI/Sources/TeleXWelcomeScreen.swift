import Foundation
import UIKit
import Display

public final class TeleXWelcomeScreen: UIViewController {
    
    private let backgroundView: UIView
    private let flowerLabel: UILabel
    private let titleLabel: UILabel
    private let subtitleLabel: UILabel
    private let betaLabel: UILabel
    private let codeField: UITextField
    private let enterButton: UIButton
    private let footerLabel: UILabel
    private let particleLayer: CAEmitterLayer
    
    // ICQ Classic Colors
    private let icqGreen = UIColor(red: 126/255, green: 178/255, blue: 59/255, alpha: 1.0)
    private let icqDarkGreen = UIColor(red: 91/255, green: 168/255, blue: 24/255, alpha: 1.0)
    private let icqBg = UIColor(red: 18/255, green: 22/255, blue: 30/255, alpha: 1.0)
    private let icqBgLight = UIColor(red: 28/255, green: 34/255, blue: 45/255, alpha: 1.0)
    
    public init() {
        self.backgroundView = UIView()
        self.flowerLabel = UILabel()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.betaLabel = UILabel()
        self.codeField = UITextField()
        self.enterButton = UIButton(type: .system)
        self.footerLabel = UILabel()
        self.particleLayer = CAEmitterLayer()
        
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupParticles()
        setupFlower()
        setupTitle()
        setupSubtitle()
        setupBetaBadge()
        setupCodeField()
        setupEnterButton()
        setupFooter()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }
    
    // MARK: - Setup
    
    private func setupBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            icqBg.cgColor,
            icqBgLight.cgColor,
            UIColor(red: 15/255, green: 30/255, blue: 20/255, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = UIScreen.main.bounds
        self.view.layer.addSublayer(gradientLayer)
        
        // Subtle green glow in the center
        let glowView = UIView()
        glowView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        glowView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 60)
        glowView.backgroundColor = icqGreen.withAlphaComponent(0.06)
        glowView.layer.cornerRadius = 150
        glowView.layer.masksToBounds = true
        let glowBlur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        glowBlur.frame = glowView.bounds
        glowView.addSubview(glowBlur)
        self.view.addSubview(glowView)
    }
    
    private func setupParticles() {
        particleLayer.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: -10)
        particleLayer.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        particleLayer.emitterShape = .line
        
        let cell = CAEmitterCell()
        cell.birthRate = 2
        cell.lifetime = 12
        cell.velocity = 15
        cell.velocityRange = 8
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        cell.scale = 0.04
        cell.scaleRange = 0.02
        cell.alphaRange = 0.4
        cell.alphaSpeed = -0.03
        cell.contents = makeCircleImage(color: icqGreen.withAlphaComponent(0.5))?.cgImage
        
        particleLayer.emitterCells = [cell]
        self.view.layer.addSublayer(particleLayer)
    }
    
    private func setupFlower() {
        flowerLabel.text = "🌼"
        flowerLabel.font = UIFont.systemFont(ofSize: 72)
        flowerLabel.textAlignment = .center
        flowerLabel.translatesAutoresizingMaskIntoConstraints = false
        flowerLabel.alpha = 0
        flowerLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        self.view.addSubview(flowerLabel)
        
        NSLayoutConstraint.activate([
            flowerLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            flowerLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 80)
        ])
    }
    
    private func setupTitle() {
        titleLabel.text = "TeleX"
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: flowerLabel.bottomAnchor, constant: 16)
        ])
    }
    
    private func setupSubtitle() {
        subtitleLabel.text = "Готовы погрузиться\nв ностальгию?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            subtitleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)
        ])
    }
    
    private func setupBetaBadge() {
        betaLabel.text = "  🧪 Приложение в режиме тестирования  "
        betaLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        betaLabel.textColor = icqGreen
        betaLabel.textAlignment = .center
        betaLabel.backgroundColor = icqGreen.withAlphaComponent(0.12)
        betaLabel.layer.cornerRadius = 16
        betaLabel.layer.borderWidth = 1
        betaLabel.layer.borderColor = icqGreen.withAlphaComponent(0.3).cgColor
        betaLabel.clipsToBounds = true
        betaLabel.alpha = 0
        betaLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(betaLabel)
        
        NSLayoutConstraint.activate([
            betaLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            betaLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            betaLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupCodeField() {
        codeField.placeholder = "Код для тестирования"
        codeField.keyboardType = .numberPad
        codeField.textAlignment = .center
        codeField.textColor = .white
        codeField.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .semibold)
        codeField.tintColor = icqGreen
        codeField.attributedPlaceholder = NSAttributedString(
            string: "Введите код",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.3),
                .font: UIFont.systemFont(ofSize: 18, weight: .regular)
            ]
        )
        
        // Glassmorphism field style
        codeField.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        codeField.layer.cornerRadius = 16
        codeField.layer.borderWidth = 1
        codeField.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        codeField.clipsToBounds = true
        codeField.alpha = 0
        codeField.isSecureTextEntry = true
        codeField.translatesAutoresizingMaskIntoConstraints = false
        codeField.addTarget(self, action: #selector(codeFieldChanged(_:)), for: .editingChanged)
        self.view.addSubview(codeField)
        
        NSLayoutConstraint.activate([
            codeField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            codeField.topAnchor.constraint(equalTo: betaLabel.bottomAnchor, constant: 32),
            codeField.widthAnchor.constraint(equalToConstant: 220),
            codeField.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupEnterButton() {
        enterButton.setTitle("Войти →", for: .normal)
        enterButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        enterButton.setTitleColor(.white, for: .normal)
        enterButton.backgroundColor = icqGreen
        enterButton.layer.cornerRadius = 16
        enterButton.alpha = 0
        enterButton.transform = CGAffineTransform(translationX: 0, y: 20)
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        enterButton.addTarget(self, action: #selector(enterTapped), for: .touchUpInside)
        
        // Shadow
        enterButton.layer.shadowColor = icqGreen.cgColor
        enterButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        enterButton.layer.shadowRadius = 12
        enterButton.layer.shadowOpacity = 0.4
        enterButton.layer.masksToBounds = false
        
        self.view.addSubview(enterButton)
        
        NSLayoutConstraint.activate([
            enterButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            enterButton.topAnchor.constraint(equalTo: codeField.bottomAnchor, constant: 24),
            enterButton.widthAnchor.constraint(equalToConstant: 220),
            enterButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    private func setupFooter() {
        footerLabel.text = "Разработчик: artykosh"
        footerLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        footerLabel.textColor = UIColor.white.withAlphaComponent(0.25)
        footerLabel.textAlignment = .center
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(footerLabel)
        
        NSLayoutConstraint.activate([
            footerLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Animations
    
    private func animateEntrance() {
        // Flower bounce in
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            self.flowerLabel.alpha = 1
            self.flowerLabel.transform = .identity
        }, completion: nil)
        
        // Title fade in
        UIView.animate(withDuration: 0.6, delay: 0.5, options: .curveEaseOut, animations: {
            self.titleLabel.alpha = 1
        }, completion: nil)
        
        // Subtitle
        UIView.animate(withDuration: 0.6, delay: 0.7, options: .curveEaseOut, animations: {
            self.subtitleLabel.alpha = 1
        }, completion: nil)
        
        // Beta badge
        UIView.animate(withDuration: 0.6, delay: 0.9, options: .curveEaseOut, animations: {
            self.betaLabel.alpha = 1
        }, completion: nil)
        
        // Code field
        UIView.animate(withDuration: 0.6, delay: 1.1, options: .curveEaseOut, animations: {
            self.codeField.alpha = 1
        }, completion: nil)
        
        // Button slides up
        UIView.animate(withDuration: 0.6, delay: 1.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.enterButton.alpha = 1
            self.enterButton.transform = .identity
        }, completion: nil)
        
        // Pulse the flower continuously
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.pulseFlower()
        }
    }
    
    private func pulseFlower() {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            self.flowerLabel.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }, completion: nil)
    }
    
    private func animateSuccess() {
        // Flash green
        let flashView = UIView(frame: self.view.bounds)
        flashView.backgroundColor = icqGreen.withAlphaComponent(0.15)
        flashView.alpha = 0
        self.view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, animations: {
                flashView.alpha = 0
                self.view.alpha = 0
                self.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }) { _ in
                flashView.removeFromSuperview()
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    private func animateError() {
        // Shake the code field
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-12, 12, -8, 8, -4, 4, 0]
        codeField.layer.add(animation, forKey: "shake")
        
        // Flash red border
        UIView.animate(withDuration: 0.2, animations: {
            self.codeField.layer.borderColor = UIColor.red.withAlphaComponent(0.6).cgColor
            self.codeField.backgroundColor = UIColor.red.withAlphaComponent(0.08)
        }) { _ in
            UIView.animate(withDuration: 0.5) {
                self.codeField.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
                self.codeField.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func codeFieldChanged(_ textField: UITextField) {
        let text = textField.text ?? ""
        if text.count >= 4 {
            // Auto-check when 4 digits entered
            if text == "2580" {
                codeField.resignFirstResponder()
                UserDefaults.standard.set(true, forKey: "TeleXUnlocked")
                UserDefaults.standard.synchronize()
                animateSuccess()
            } else {
                animateError()
                textField.text = ""
            }
        }
    }
    
    @objc private func enterTapped() {
        let text = codeField.text ?? ""
        if text == "2580" {
            codeField.resignFirstResponder()
            UserDefaults.standard.set(true, forKey: "TeleXUnlocked")
            UserDefaults.standard.synchronize()
            animateSuccess()
        } else {
            animateError()
            codeField.text = ""
        }
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    // MARK: - Helpers
    
    private func makeCircleImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 12, height: 12)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
