import Anchorage
import SwiftExtensions
import UIKit

var menuButtomHeight: CGFloat {
    if UIDevice.type == .iPhoneSE || UIDevice.type == .iPhone8plus {
        75
    } else if UIDevice.type == .iPhone12 {
        96
    } else if UIDevice.type == .iPhone12Mini {
        90
    } else if UIDevice.type == .iPhone14Pro {
        90
    } else if UIDevice.type == .iPhone14ProMax {
        100
    } else if UIDevice.type == .iPhone11 {
        100
    } else if UIDevice.type == .iPad {
        120 //160
    } else if UIDevice.type == .iPhone11Pro {
        90
    } else {
        106
    }
}

protocol DRHDropDownDraggableMenuDelegate: AnyObject {
    func openingMenuProgress(_ progress: CGFloat)
    func didStartOpeningMenu()
    func didFinishClosingMenu()

    func didTapAffirmationButton()
    func didTapInfoButton()
    func didTapSettingsButton()
    func didTapStoreButton()
}

class DRHDropDownDraggableMenu: UIView {
    private enum Constants {
        static var gravity: CGFloat {
            #if targetEnvironment(simulator)
                return 2.5
            #else
                if !UIDevice.type.supportMenuAnimation {
                    return 12
                } else {
                    return 2.5
                }
            #endif
        }

        static var velocityMultiplier: CGFloat {
            #if targetEnvironment(simulator)
                return 0.05
            #else
                if !UIDevice.type.supportMenuAnimation {
                    return 0.5
                } else {
                    return 0.05
                }
            #endif
        }

        static var velocityThreshold: Float {
            #if targetEnvironment(simulator)
                return 250
            #else
                if !UIDevice.type.supportMenuAnimation {
                    return 10
                } else {
                    return 250
                }
            #endif
        }
    }

    weak var delegate: DRHDropDownDraggableMenuDelegate?

    fileprivate let menuView = DRHDropMenuView.nibInstance()

    fileprivate var animator = UIDynamicAnimator()
    fileprivate var contaiter = UICollisionBehavior()
    fileprivate var snap: UISnapBehavior?
    fileprivate var dynamicItem = UIDynamicItemBehavior()
    fileprivate var gravity = UIGravityBehavior()
    fileprivate let imageView = UIImageView()

    private var didSetup = false

    func setup() {
        guard !didSetup else {
            return
        }

        didSetup = true
        backgroundColor = .clear

        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear

        addSubview(imageView)
        imageView.edgeAnchors == edgeAnchors

        if let menuView {
            addSubview(menuView)
            menuView.edgeAnchors == edgeAnchors

            menuView.delegate = self
        }

        if let superview {
            animator = UIDynamicAnimator(referenceView: superview)
        }

        dynamicItem = UIDynamicItemBehavior(items: [self])
        gravity = UIGravityBehavior(items: [self])
        contaiter = UICollisionBehavior(items: [self])

        contaiter.action = { [weak self] in
            self?.getViewVelocityInSuperview()
        }

        dynamicItem.allowsRotation = false
        dynamicItem.elasticity = 0

        gravity.gravityDirection = CGVector(dx: 0, dy: -2.5)

        configureContainer()

        animator.addBehavior(gravity)
        animator.addBehavior(dynamicItem)
        animator.addBehavior(contaiter)
    }

    fileprivate func getViewVelocityInSuperview() {
        let zeroPosition: CGFloat = menuButtomHeight
        let maxPosition = UIScreen.main.bounds.size.height

        let currentPosition = frame.origin.y + frame.height

        let velocity = (currentPosition - zeroPosition) / maxPosition

        if velocity >= 0, velocity <= 0.4 {
            delegate?.openingMenuProgress(velocity)
        }
    }

    fileprivate func configureContainer() {
        let boundaryWidth = UIScreen.main.bounds.size.width
        let boundaryHeight = UIScreen.main.bounds.size.height + menuButtomHeight

        contaiter.addBoundary(withIdentifier: "upper" as NSCopying, from: CGPoint(x: 0, y: -frame.size.height + menuButtomHeight), to: CGPoint(x: boundaryWidth, y: -frame.size.height + menuButtomHeight))

        contaiter.addBoundary(withIdentifier: "lower" as NSCopying, from: CGPoint(x: 0, y: boundaryHeight), to: CGPoint(x: boundaryWidth, y: boundaryHeight))
    }

    fileprivate func panGestureEnded() {
        if let snap {
            animator.removeBehavior(snap)
        }

        let velocity = dynamicItem.linearVelocity(for: self)

        if abs(Float(velocity.y)) > Constants.velocityThreshold {
            if velocity.y < 0 {
                snapToTop()
            } else {
                snapToBottom()
            }
        } else {
            if let superviewHeight = superview?.bounds.size.height {
                if frame.origin.y > superviewHeight / 2 {
                    snapToBottom()
                } else {
                    snapToTop()
                }
            }
        }
    }

    fileprivate func snapToBottom() {
        gravity.gravityDirection = CGVector(dx: 0, dy: Constants.gravity)
    }

    fileprivate func snapToTop() {
        gravity.gravityDirection = CGVector(dx: 0, dy: -2.5)
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer _: UIGestureRecognizer) -> Bool {
        false
    }

    func close() {
        gravity.gravityDirection = CGVector(dx: 0, dy: -4)
    }
}

extension DRHDropDownDraggableMenu: DRHDropMenuViewDelegate {
    func didTapAffirmation() {
        delegate?.didTapAffirmationButton()
    }

    func didTapInfo() {
        delegate?.didTapInfoButton()
    }

    func didTapSettings() {
        delegate?.didTapSettingsButton()
    }

    func didTapVideo() {
        delegate?.didTapStoreButton()
    }

    func didTapMenuButton() {
        gravity.gravityDirection = CGVector(dx: 0, dy: 4)
    }

    func didDragMenuView(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: superview).y
        var movement = frame

        movement.origin.x = 0
        movement.origin.y = movement.origin.y + (velocity * Constants.velocityMultiplier)

        switch sender.state {
        case .ended:
            panGestureEnded()
        case .began:
            snapToBottom()
        default:
            if let snap {
                animator.removeBehavior(snap)
            }
            snap = UISnapBehavior(item: self, snapTo: CGPoint(x: movement.midX, y: movement.midY))
            if let snap {
                animator.addBehavior(snap)
            }
        }
    }

    func didTapDismissButton() {
        close()
    }
}

private extension DeviceType {
    var supportMenuAnimation: Bool {
        switch self {
        case .iPhone11, .iPhone11Pro, .iPhone11ProMax, .iPhone5, .iPhone8plus, .iPhoneSE, .unknown:
            true
        default:
            false
        }
    }
}
