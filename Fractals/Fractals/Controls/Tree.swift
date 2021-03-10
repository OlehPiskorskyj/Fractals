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
    func addColor2Vertex(vertex: inout Vertex, n: Int) {
        var color = simd_float3.zero
        if (n < 30) {
            color.x = 1.0
            color.y = 0.0
            color.z = 0.0
        } else if (n > 255 - 12) {
            //color = simd_float3.zero
        } else {
            let c = Float((n * n + n) % 256)
            color.x = 0.0
            color.y = c / 255.0 - 0.3
            color.z = 0.0
        }
        
        vertex.r = color.x
        vertex.g = color.y
        vertex.b = color.z
    }
    
    func pixelHeight(image: UIImage, positionX: Int, positionY: Int) -> Int {
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
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    func addBrunch(length: CGFloat, angle: Double) -> CGPoint {
        var returnValue = CGPoint.zero
        var preparedAngle = angle
        var angleChanged = false
        if (angle > 90.0) {
            preparedAngle = angle - 90.0
            angleChanged = true
        }
        
        let radAngle = CGFloat(self.deg2rad(preparedAngle))
        if (!angleChanged) {
            returnValue.x = -sin(radAngle) * length
            returnValue.y = cos(radAngle) * length
        } else {
            returnValue.x = -cos(radAngle) * length
            returnValue.y = -sin(radAngle) * length
        }
        return returnValue
    }
    
    func createBrunches(start: CGPoint, length: CGFloat, angle: Double, path: inout UIBezierPath) {
        let newPosition = start + self.addBrunch(length: length, angle: angle)
        path.addLine(to: newPosition)
        
        if (length > 4) {
            self.createBrunches(start: newPosition, length: length - 6, angle: angle + 18.0, path: &path)
            path.move(to: newPosition)
            
            self.createBrunches(start: newPosition, length: length - 6, angle: angle - 18.0, path: &path)
            path.move(to: newPosition)
        }
    }
    
    // MARK: - fractal logic
    func createTreeFractal() {
        let imageRendererFormat = UIGraphicsImageRendererFormat()
        imageRendererFormat.scale = 1
        
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300), format: imageRendererFormat)
        let image = imageRenderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            
            var bezier = UIBezierPath()
            let startPosition = CGPoint(x: 150.0, y: 0.0)
            bezier.move(to: startPosition)
            self.createBrunches(start: startPosition, length: 60, angle: 0.0, path: &bezier)
            
            bezier.lineWidth = 3.0
            bezier.lineJoinStyle = .bevel
            bezier.stroke()
            ctx.cgContext.addPath(bezier.cgPath)
        }
        
        self.imageData = image
        self.create3DShape()
    }
    
    func create3DShape() {
        angle = Float.pi
        vertexCount = 0
        indexCount = 0
        
        let delta = 1.0 / Float(Consts.FRACTAL_SIZE)
        for x in 0..<Consts.FRACTAL_SIZE {
            for y in 0..<Consts.FRACTAL_SIZE {
                
                let v1m = self.tree(x: x, y: y + 1)
                let v2m = self.tree(x: x, y: y)
                let v3m = self.tree(x: x + 1, y: y + 1)
                let v4m = self.tree(x: x + 1, y: y)
                
                var v1 = Vertex(x: Float(x) * delta, y: Float(v1m) / 255.0, z: Float(y + 1) * delta, r: 0.0, g: 0.4, b: 0.0)
                self.addColor2Vertex(vertex: &v1, n: v1m)
                var v2 = Vertex(x: Float(x) * delta, y: Float(v2m) / 255.0, z: Float(y) * delta, r: 0.0, g: 0.4, b: 0.0)
                self.addColor2Vertex(vertex: &v2, n: v2m)
                var v3 = Vertex(x: Float(x + 1) * delta, y: Float(v3m) / 255.0, z: Float(y + 1) * delta, r: 0.0, g: 0.4, b: 0.0)
                self.addColor2Vertex(vertex: &v3, n: v3m)
                var v4 = Vertex(x: Float(x + 1) * delta, y: Float(v4m) / 255.0, z: Float(y) * delta, r: 0.0, g: 0.4, b: 0.0)
                self.addColor2Vertex(vertex: &v4, n: v4m)
                
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
            self.createTreeFractal()
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
