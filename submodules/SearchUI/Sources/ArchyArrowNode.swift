import AsyncDisplayKit

public final class ArchyArrowNode: ASDisplayNode {
    
    public override func _layoutSublayouts() {
        super._layoutSublayouts()

        layer.cornerRadius = bounds.size.width / 2
        layer.masksToBounds = true
    }
    
    public override class func draw(_ bounds: CGRect, withParameters parameters: Any?, isCancelled isCancelledBlock: () -> Bool, isRasterizing: Bool) {
        let rect = bounds
        
        // Draw the white circle
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
                
        context.addEllipse(in: rect)
        context.setFillColor(UIColor.white.cgColor)
        context.fillPath()
        
        // Calculate the arrow's parameters
        let arrowWidth: CGFloat = 13.0
        let arrowHeight: CGFloat = 8.0
        let arrowTopPoint = CGPoint(x: rect.midX - (arrowWidth / 2), y: rect.midY - 3.0) //(arrowHeight / 2))
        
        // Draw the arrow
        let arrowPath = UIBezierPath()
        arrowPath.move(to: arrowTopPoint)
        arrowPath.addLine(to: CGPoint(x: arrowTopPoint.x + arrowWidth, y: arrowTopPoint.y))
        arrowPath.addLine(to: CGPoint(x: arrowTopPoint.x + (arrowWidth / 2), y: arrowTopPoint.y + arrowHeight))
        arrowPath.close()
        
        context.addPath(arrowPath.cgPath)
        context.setFillColor(UIColor.lightGray.cgColor)
        context.fillPath()
    }
    
    public override init() {
        super.init()
        
        backgroundColor = .clear
    }
}
