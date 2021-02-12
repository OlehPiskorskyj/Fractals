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
    private var mAngle: Float = 0.0
    private var mFractalIterationsCount: Int = 0
    
    public var zoom: Float = -5.0
    
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
    
    // MARK: - fractal logic
    func createJulia() {
        mAngle = Float.pi / 2.0
        mVertexCount = 0
        mIndexCount = 0

        //mFractalZoom = 1.0
        //mFractalX = -0.5
        //mFractalY = 0.0
        mFractalIterationsCount = 250
        
        let delta = 1.0 / Float(Consts.FRACTAL_SIZE)
        
        for x in 0..<Consts.FRACTAL_SIZE {
            for y in 0..<Consts.FRACTAL_SIZE {
                
                let v1m = self.julia(x: x, y: y + 1)
                let v2m = self.julia(x: x, y: y)
                let v3m = self.julia(x: x + 1, y: y + 1)
                let v4m = self.julia(x: x + 1, y: y)
                
                var v1 = Vertex(x: Float(x) * delta, y: Float(v1m) / 255.0, z: Float(y + 1) * delta, r: 1.0, g: 0.0, b: 0.0)
                //self.addColor2Vertex(vertex: &v1, n: v1m)
                var v2 = Vertex(x: Float(x) * delta, y: Float(v2m) / 255.0, z: Float(y) * delta, r: 1.0, g: 0.0, b: 0.0)
                //self.addColor2Vertex(vertex: &v2, n: v2m)
                var v3 = Vertex(x: Float(x + 1) * delta, y: Float(v3m) / 255.0, z: Float(y + 1) * delta, r: 1.0, g: 0.0, b: 0.0)
                //self.addColor2Vertex(vertex: &v3, n: v3m)
                var v4 = Vertex(x: Float(x + 1) * delta, y: Float(v4m) / 255.0, z: Float(y) * delta, r: 1.0, g: 0.0, b: 0.0)
                //self.addColor2Vertex(vertex: &v4, n: v4m)
                
                var index1 = mVertexCount
                var index2 = mVertexCount + 1
                var index3 = mVertexCount + 1
                var index4 = mVertexCount + 2
                var index5 = mVertexCount + 2
                var index6 = mVertexCount
                
                var index7 = mVertexCount + 1
                var index8 = mVertexCount + 3
                var index9 = mVertexCount + 3
                var index10 = mVertexCount + 2
                
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
        return mFractalIterationsCount
    }

    // MARK: - other methods
    override func internalInit() {
        mMaxVertexCount = Consts.FRACTAL_MAX_VERTICES
        mMaxIndexCount = Consts.FRACTAL_MAX_INDICES
        
        super.internalInit()
        self.delegate = self
        
        DispatchQueue.global().async {
            self.createJulia()
        }
    }
}

extension Julia: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(Float(view.frame.width / view.frame.height)), 0.1, 100.0);
        mSceneMatrices.projectionMatrix = projectionMatrix
        mTextureDepth = nil
        mTexture = nil
    }
    
    func draw(in view: MTKView) {
        #if targetEnvironment(simulator)
        return
        #else
        
        guard let drawable = view.currentDrawable else { return }
        
        if (mTexture == nil) {
            mTexture = self.createAliasingTexture(texture: drawable.texture)
        }
        
        if (mTextureDepth == nil) {
            mTextureDepth = self.createDepthTexture(texture: drawable.texture)
        }
        
        let depthAttachementTexureDescriptor = MTLRenderPassDepthAttachmentDescriptor()
        depthAttachementTexureDescriptor.clearDepth = 1.0
        depthAttachementTexureDescriptor.loadAction = .clear
        depthAttachementTexureDescriptor.storeAction = .dontCare
        depthAttachementTexureDescriptor.texture = mTextureDepth
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = mTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        renderPassDescriptor.depthAttachment = depthAttachementTexureDescriptor
        
        guard let commandBuffer = mCommandQueue.makeCommandBuffer() else { return }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        mLookAt = GLKMatrix4MakeLookAt(0.0, 2.0 - self.zoom, 4.0 - self.zoom, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        
        var modelView = GLKMatrix4Multiply(GLKMatrix4MakeScale(10.0, 1.0, 10.0), GLKMatrix4MakeRotation(mAngle, 0.0, 1.0, 0.0))
        modelView = GLKMatrix4Multiply(modelView, GLKMatrix4MakeTranslation(-0.5, 0.0, -0.5))
        mSceneMatrices.modelviewMatrix = GLKMatrix4Multiply(mLookAt, modelView)
        let uniformBufferSize = MemoryLayout.size(ofValue: mSceneMatrices)
        mUniformBuffer = mDevice.makeBuffer(bytes: &mSceneMatrices, length: uniformBufferSize, options: .storageModeShared)
        renderEncoder.setVertexBuffer(mUniformBuffer, offset: 0, index: 1)
        renderEncoder.setDepthStencilState(mDepthStencilState)
        renderEncoder.setRenderPipelineState(mPipelineState)
        
        if (mVertexCount > 0) {
            renderEncoder.setVertexBuffer(mVertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .line, indexCount: Int(mIndexCount), indexType: .uint32, indexBuffer: mIndexBuffer, indexBufferOffset: 0)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        mAngle += 0.01
        
        #endif
    }
}

