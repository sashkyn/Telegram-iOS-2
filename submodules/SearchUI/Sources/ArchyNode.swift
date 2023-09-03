import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import SearchBarNode
import TelegramCore

public class ArchyNode: ASDisplayNode {
    
    public var requestToShowArchive: Bool = false
    
    public var theme: PresentationTheme? {
        didSet {
            let backgroundColors = theme?.chatList.pinnedArchiveAvatarColor.backgroundColors.colors
            let colors = [backgroundColors?.0, backgroundColors?.1]
            
            guard let archivedBackgroundImage = generateGradientImage(
                size: .init(width: 1000, height: 300),
                colors: colors.compactMap { $0 },
                locations: [0.0, 1.0]
            ) else {
                return
            }
            frontNode.image = archivedBackgroundImage
            backNode.image = archivedBackgroundImage.grayscale()
        }
    }
    
    private var state: State = .hidden {
        didSet {
            guard state != oldValue else {
                return
            }
            
            changeFlagToShowArchive()
            
            switch state {
            case .expanded:
                share()
            case .hidden:
                hide()
            }
        }
    }
    
    private let immediateTransition: ContainedViewLayoutTransition = .immediate
    
    private let animatedTransition: ContainedViewLayoutTransition = .animated(
        duration: 0.5,
        curve: .spring
    )
    
    private lazy var containerNode: ASDisplayNode = {
        let view = ASDisplayNode()
        return view
    }()
    
    private lazy var backNode: ASImageNode = {
        let view = ASImageNode()
        return view
    }()
    
    private lazy var frontNode: ASImageNode = {
        let view = ASImageNode()
        view.isHidden = true
        return view
    }()
    
    private lazy var arrowNode: ASDisplayNode = {
        let view = ArchyArrowNode()
        return view
    }()
    
    public override init() {
        super.init()
        
        self.addSubnode(containerNode)
        containerNode.addSubnode(backNode)
        containerNode.addSubnode(frontNode)
        containerNode.addSubnode(arrowNode)
    }
    
    public func updateLayout(
        size: CGSize,
        transition: ContainedViewLayoutTransition
    ) {
        let containerFrame = CGRect(
            origin: .zero,
            size: .init(
                width: size.width,
                height: size.height
            )
        )
        
        if size.height > 40 {
            arrowNode.isHidden = false
        } else {
            arrowNode.isHidden = true
        }
        
        // HINT: обновляем фрейм контейнера
        transition.updateFrame(
            node: containerNode,
            frame: containerFrame
        )
        
        transition.updateFrame(
            node: backNode,
            frame: containerFrame
        )
        
        let arrowNodeFrame = CGRect(
            origin: .init(
                x: 16.0,
                y: max(containerFrame.center.y - Constants.arrowSize.height / 2, containerFrame.maxY - 50.0)
            ),
            size: Constants.arrowSize
        )
        
        transition.updateFrame(
            node: arrowNode,
            frame: arrowNodeFrame
        )
        
        transition.updateFrame(
            node: frontNode,
            frame: containerFrame
        )
        
        if size.height >= ContestHelper.shared.chatItemHeight {
            state = .expanded
        } else {
            state = .hidden
        }
        
        switchStateIfNeeded(
            height: size.height,
            transition: animatedTransition
        )
    }
    
    private func switchStateIfNeeded(
        height: CGFloat,
        transition: ContainedViewLayoutTransition
    ) {
        if height > ContestHelper.shared.chatItemHeight {
            state = .expanded
        } else {
            state = .hidden
        }
    }
    
    private func changeFlagToShowArchive() {
        switch state {
        case .expanded:
            self.requestToShowArchive = true
        case .hidden:
            if ContestHelper.shared.isUserLeaveChatListScroll && requestToShowArchive {
                ContestHelper.shared.needToShowArchiveInChat = true
                self.requestToShowArchive = true
                
                DispatchQueue.main.asyncAfter(
                    deadline: DispatchTime.now() + 1,
                    execute: { [weak self] in
                        self?.requestToShowArchive = false
                        // TODO: make animation
                        self?.removeFromSupernode()
                        
                        ContestHelper.shared.needToShowArchiveInChat = false // временно
                    }
                )
            } else {
                self.requestToShowArchive = false
            }
        }
    }
    
    private func share() {
        animatedTransition.updateTransformRotation(
            node: arrowNode,
            angle: CGFloat.pi
        )
        animateInFrontNode()
    }
    
    private func hide() {
        animatedTransition.updateTransformRotation(
            node: arrowNode,
            angle: 0.0
        )
        animateOutFrontNode()
    }
    
    private func animateInFrontNode() {
        self.frontNode.isHidden = false
        let transition: ContainedViewLayoutTransition = .animated(duration: 0.4, curve: .easeInOut)
        let fromRect = convert(arrowNode.frame, to: containerNode)
    
        let maskLayer = CAShapeLayer()
        maskLayer.frame = fromRect
    
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(origin: CGPoint(), size: fromRect.size))
        maskLayer.path = path
    
        frontNode.layer.mask = maskLayer
        
        transition.updateTransformScale(
            layer: maskLayer,
            scale: 100,
            completion: { [weak self] _ in
                self?.frontNode.layer.mask = nil
            }
        )
    }
        
    private func animateOutFrontNode() {
        let transition: ContainedViewLayoutTransition = .animated(duration: 0.2, curve: .spring)
        let fromRect = convert(arrowNode.frame, to: containerNode)
    
        let maskLayer = CAShapeLayer()
        maskLayer.frame = fromRect
    
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(origin: CGPoint(), size: fromRect.size))
        maskLayer.path = path
    
        frontNode.layer.mask = maskLayer
        
        immediateTransition.updateTransformScale(
            layer: maskLayer,
            scale: 100,
            completion: { [weak self] _ in
                transition.updateTransformScale(
                    layer: maskLayer,
                    scale: 0.1,
                    completion: { _ in
                        self?.frontNode.isHidden = true
                        self?.frontNode.layer.mask = nil
                    }
                )
            }
        )
    }
}

// MARK: State

public extension ArchyNode {
    
    enum State {
        case expanded
        case hidden
    }
}

// MARK: Private

private extension ArchyNode {
    
    enum Constants {
        static let arrowSize: CGSize = .init(width: 24.0, height: 24.0)
    }
}

// MARK: ChatGPT

private extension UIImage {
    
    func grayscale() -> UIImage? {
        // Convert the UIImage to a CIImage
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        
        // Apply a grayscale filter
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey) // Set saturation to 0 for grayscale
        
        // Get the output image from the filter
        if let outputImage = filter?.outputImage {
            // Create a CIContext and convert CIImage to UIImage
            let context = CIContext(options: nil)
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}
