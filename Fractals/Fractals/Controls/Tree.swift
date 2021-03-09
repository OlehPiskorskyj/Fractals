//
//  Tree.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 08/03/2021.
//

import UIKit
import MetalKit
import GLKit

class Tree: BaseMetalView {
    
    // MARK: - consts
    public struct Consts {
        static let FRACTAL_SIZE =                                   300
        static let FRACTAL_MAX_VERTICES =                           FRACTAL_SIZE * FRACTAL_SIZE * 4
        static let FRACTAL_MAX_INDICES =                            FRACTAL_SIZE * FRACTAL_SIZE * 10    //FRACTAL_MAX_VERTICES * 3
    }
    
    // MARK: - props
    public var imageData: UIImage? = nil
    
    private var fractalZoom: Float = 0.0
    private var zx: Float = 0.0
    private var zy: Float = 0.0
    private var tmp: Float = 0.0
    
    // MARK: - ctors
    override public init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.internalInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self.internalInit()
    }
    
    deinit {
        super.tearDownMetal()
    }
    
    // MARK: - utility methods
    public func pixelHeight(image: UIImage, positionX: Int, positionY: Int) -> Int {
        var returnValue = 0
        guard let cgImage = image.cgImage else { return returnValue }
        let provider = cgImage.dataProvider
        let providerData = provider!.data
        if let data = CFDataGetBytePtr(providerData) {
            let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
            let offset = (positionY * cgImage.bytesPerRow) + (positionX * bytesPerPixel)
            returnValue = Int(data[offset])
        }
        return returnValue
    }
    
    private func image(with path: UIBezierPath, size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setStroke()
            //UIColor.blue.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    func createBeizePath() -> UIBezierPath
    {
        let path = UIBezierPath()
        //Rectangle path Trace
        path.move(to: CGPoint(x: 20, y: 100) )
        path.addLine(to: CGPoint(x: 50 , y: 100))
        path.addLine(to: CGPoint(x: 50, y: 150))
        path.addLine(to: CGPoint(x: 20, y: 150))
        return path
      }
    
    // MARK: - fractal logic
    func createJulia() {
        angle = Float.pi / 2.0
        vertexCount = 0
        indexCount = 0

        fractalZoom = 1.0
        
        let imageRendererFormat = UIGraphicsImageRendererFormat()
        imageRendererFormat.scale = 1
        
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300), format: imageRendererFormat)
        let image = imageRenderer.image { ctx in
            /*
            let rectangle = CGRect(x: 20, y: 20, width: 50, height: 50)

            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(2)
            
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            */
            
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            
            //let bezier = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 300, height: 300))
            let bezier = UIBezierPath()
            var angleInRadians: CGFloat = -CGFloat.pi / 4
            let length: CGFloat = 100
            //bezier.move(to: .zero)
            
            //bezier.addLine(to: CGPoint(x: 0, y: 1))
            //bezier.apply(.init(rotationAngle: angleInRadians))
            //bezier.apply(.init(scaleX: length, y: length))
            
            var x: CGFloat = 100.0
            var y: CGFloat = 0.0
            
            bezier.move(to: CGPoint(x: x, y: y))
            //bezier.addLine(to: CGPoint(x: 100, y: 100))
            //bezier.addLine(to: CGPoint(x: 125, y: 125))
            
            x += -sin(angleInRadians) * length
            y += cos(angleInRadians) * length
            
            bezier.addLine(to: CGPoint(x: x, y: y))
            
            angleInRadians = 2 * CGFloat.pi
            
            x += -sin(angleInRadians) * length
            y += cos(angleInRadians) * length
            
            bezier.addLine(to: CGPoint(x: x, y: y))
            
            bezier.lineWidth = 3.0
            bezier.lineJoinStyle = .bevel
            bezier.stroke()
            ctx.cgContext.addPath(bezier.cgPath)
            
            /*
            let angleInRadians: CGFloat = CGFloat.pi / 2
            let length: CGFloat = 50
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.beginPath()
            ctx.cgContext.move(to: CGPoint.init(x: 100, y:0))
            ctx.cgContext.addLine(to: CGPoint.init(x: 100, y: 100))
            ctx.cgContext.addLine(to: CGPoint(x: -sin(angleInRadians) * length, y: cos(angleInRadians) * length))
            //ctx.cgContext.closePath()
            
            //ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            ctx.cgContext.drawPath(using: CGPathDrawingMode.stroke)
            */
            
            /*
            UIColor.blue.setStroke()
            
            let path = UIBezierPath()
            path.lineWidth = 2
            path.stroke()
            
            let angleInRadians: CGFloat = 3.14
            let length: CGFloat = 50
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 0, y: 1))
            path.apply(.init(rotationAngle: angleInRadians))
            path.apply(.init(scaleX: length, y: length))
            */
            
        }
        
        self.imageData = image

        let delta = 1.0 / Float(Consts.FRACTAL_SIZE)
        
        for x in 0..<Consts.FRACTAL_SIZE {
            for y in 0..<Consts.FRACTAL_SIZE {
                
                let v1m = self.tree(x: x, y: y + 1)
                let v2m = self.tree(x: x, y: y)
                let v3m = self.tree(x: x + 1, y: y + 1)
                let v4m = self.tree(x: x + 1, y: y)
                
                var v1 = Vertex(x: Float(x) * delta, y: Float(v1m) / 255.0, z: Float(y + 1) * delta, r: 0.0, g: 0.4, b: 0.0)
                var v2 = Vertex(x: Float(x) * delta, y: Float(v2m) / 255.0, z: Float(y) * delta, r: 0.0, g: 0.4, b: 0.0)
                var v3 = Vertex(x: Float(x + 1) * delta, y: Float(v3m) / 255.0, z: Float(y + 1) * delta, r: 0.0, g: 0.4, b: 0.0)
                var v4 = Vertex(x: Float(x + 1) * delta, y: Float(v4m) / 255.0, z: Float(y) * delta, r: 0.0, g: 0.4, b: 0.0)
                
                var index1 = vertexCount
                var index2 = vertexCount + 1
                var index3 = vertexCount + 1
                var index4 = vertexCount + 2
                var index5 = vertexCount + 2
                var index6 = vertexCount
                
                var index7 = vertexCount + 1
                var index8 = vertexCount + 3
                var index9 = vertexCount + 3
                var index10 = vertexCount + 2
                
                self.addIndex(index: &index1)
                self.addIndex(index: &index2)
                self.addIndex(index: &index3)
                self.addIndex(index: &index4)
                self.addIndex(index: &index5)
                self.addIndex(index: &index6)
                
                self.addIndex(index: &index7)
                self.addIndex(index: &index8)
                self.addIndex(index: &index9)
                self.addIndex(index: &index10)
                
                self.addVertex(vertex: &v1)
                self.addVertex(vertex: &v2)
                self.addVertex(vertex: &v3)
                self.addVertex(vertex: &v4)
            }
        }
    }

    func tree(x: Int, y: Int) -> Int {
        guard let imageData = self.imageData else { return 0 }
        let height = self.pixelHeight(image: imageData, positionX: x, positionY: y)
        return height
    }

    // MARK: - other methods
    override func internalInit() {
        maxVertexCount = Consts.FRACTAL_MAX_VERTICES
        maxIndexCount = Consts.FRACTAL_MAX_INDICES
        
        super.internalInit()
        self.delegate = self
        
        DispatchQueue.global().async {
            self.createJulia()
        }
    }
}

extension Tree: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        super.updateProjectionMatrix(aspectRatio: Float(view.frame.width / view.frame.height))
    }
    
    func draw(in view: MTKView) {
        #if targetEnvironment(simulator)
        return
        #else
        
        guard let drawable = view.currentDrawable else { return }
        let renderPassDescriptor = super.createRenderPassDescriptor(drawable: drawable)
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        lookAt = GLKMatrix4MakeLookAt(0.0, 2.0 - self.zoom, 4.0 - self.zoom, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        
        var modelView = GLKMatrix4Multiply(GLKMatrix4MakeScale(10.0, 1.0, 10.0), GLKMatrix4MakeRotation(angle, 0.0, 1.0, 0.0))
        modelView = GLKMatrix4Multiply(modelView, GLKMatrix4MakeTranslation(-0.5, 0.0, -0.5))
        sceneMatrices.modelview = GLKMatrix4Multiply(lookAt, modelView)
        let uniformBufferSize = MemoryLayout.size(ofValue: sceneMatrices)
        uniformBuffer = metalDevice.makeBuffer(bytes: &sceneMatrices, length: uniformBufferSize, options: .storageModeShared)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if (vertexCount > 0) {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .line, indexCount: Int(indexCount), indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        if (self.rotating) {
            angle += 0.01
        }
        
        #endif
    }
}
