//
//  Julia.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 12/02/2021.
//

import UIKit
import MetalKit
import GLKit

class Julia: BaseMetalView {
    
    // MARK: - consts
    public struct Consts {
        static let FRACTAL_SIZE =                                   300
        static let FRACTAL_MAX_VERTICES =                           FRACTAL_SIZE * FRACTAL_SIZE * 4
        static let FRACTAL_MAX_INDICES =                            FRACTAL_SIZE * FRACTAL_SIZE * 10    //FRACTAL_MAX_VERTICES * 3
    }
    
    // MARK: - props
    private var fractalZoom: Float = 0.0
    private var moveX: Float = 0.0
    private var moveY: Float = 0.0
    private var zx: Float = 0.0
    private var zy: Float = 0.0
    private var cx: Float = 0.0
    private var cy: Float = 0.0
    private var tmp: Float = 0.0
    private var iterationsCount: Int = 0
    
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
        } else if (n > iterationsCount - 12) {
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
    
    // MARK: - fractal logic
    func createJulia() {
        angle = Float.pi / 2.0
        vertexCount = 0
        indexCount = 0

        fractalZoom = 1.0
        moveX = 0.0
        moveY = 0.0
        cx = -0.7
        cy = 0.27015
        iterationsCount = 255
        
        let delta = 1.0 / Float(Consts.FRACTAL_SIZE)
        
        for x in 0..<Consts.FRACTAL_SIZE {
            for y in 0..<Consts.FRACTAL_SIZE {
                
                let v1m = self.julia(x: x, y: y + 1)
                let v2m = self.julia(x: x, y: y)
                let v3m = self.julia(x: x + 1, y: y + 1)
                let v4m = self.julia(x: x + 1, y: y)
                
                var v1 = Vertex(x: Float(x) * delta, y: Float(v1m) / 255.0, z: Float(y + 1) * delta, r: 1.0, g: 0.0, b: 0.0)
                self.addColor2Vertex(vertex: &v1, n: v1m)
                var v2 = Vertex(x: Float(x) * delta, y: Float(v2m) / 255.0, z: Float(y) * delta, r: 1.0, g: 0.0, b: 0.0)
                self.addColor2Vertex(vertex: &v2, n: v2m)
                var v3 = Vertex(x: Float(x + 1) * delta, y: Float(v3m) / 255.0, z: Float(y + 1) * delta, r: 1.0, g: 0.0, b: 0.0)
                self.addColor2Vertex(vertex: &v3, n: v3m)
                var v4 = Vertex(x: Float(x + 1) * delta, y: Float(v4m) / 255.0, z: Float(y) * delta, r: 1.0, g: 0.0, b: 0.0)
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

    func julia(x: Int, y: Int) -> Int {
        zx = 1.5 * Float(x - Consts.FRACTAL_SIZE / 2) / (0.5 * fractalZoom * Float(Consts.FRACTAL_SIZE)) + moveX
        zy = 1.0 * Float(y - Consts.FRACTAL_SIZE / 2) / (0.5 * fractalZoom * Float(Consts.FRACTAL_SIZE)) + moveY
        
        var i = iterationsCount
        while (i > 1) {
            if ((zx * zx + zy * zy) > 4.0) {
                break
            }
            
            tmp = zx * zx - zy * zy + cx
            zy = 2.0 * zx * zy + cy
            zx = tmp
            i -= 1
        }
        
        /*
        var i = 0
        while (i < iterationsCount) {
            i += 1
            
            tmp = zx * zx - zy * zy + cx
            zy = 2.0 * zx * zy + cy
            zx = tmp
            
            if ((zx * zx + zy * zy) > 4.0) {
                break
            }
        }
        */
        
        return i
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

extension Julia: MTKViewDelegate {
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

