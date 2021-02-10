//
//  BaseMetalView.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 10/02/2021.
//

import UIKit
import MetalKit
import GLKit

struct Vertex {
    var x: GLfloat
    var y: GLfloat
    var z: GLfloat
    var r: GLfloat
    var g: GLfloat
    var b: GLfloat
    public static func zero() -> Vertex {
        return Vertex.init(x: 0, y: 0, z: 0, r: 0, g: 0, b: 0)
    }
}

struct SceneMatrices {
    var projectionMatrix: GLKMatrix4 = GLKMatrix4Identity
    var modelviewMatrix: GLKMatrix4 = GLKMatrix4Identity
}


class BaseMetalView: MTKView {
    
    // MARK: - props
    public var mDevice: MTLDevice!
    public var mCommandQueue: MTLCommandQueue!
    public var mPipelineState: MTLRenderPipelineState!
    public var mDepthStencilState: MTLDepthStencilState!
    public var mTextureDepth: MTLTexture? = nil
    public var mTexture: MTLTexture? = nil
    
    public var mSceneMatrices = SceneMatrices()
    public var mUniformBuffer: MTLBuffer!
    public var mLookAt: GLKMatrix4 = GLKMatrix4Identity
    
    public var mVertexBuffer: MTLBuffer!
    public var mIndexBuffer: MTLBuffer!
    public var mVertexCount: UInt32 = 0
    public var mIndexCount: UInt32 = 0
    public var mMaxVertexCount = 0
    public var mMaxIndexCount = 0
    
    
    //public var mCurrentOrientation: UIDeviceOrientation = .unknown
    //public var isUpdateWithOrientation: Bool = false
    
    /*
    // MARK: - orientation
    @objc func deviceRotated(notification: NSNotification) {
        if (!self.isUpdateWithOrientation) {
            return
        }
        
        let orientation = UIDevice.current.orientation
        if (orientation != mCurrentOrientation &&
            orientation != .portraitUpsideDown) {
            self.update()
            mCurrentOrientation = orientation
        }
    }
    */
    
    // MARK: - utility methods
    func addVertex(vertex: inout Vertex) {
        if (mVertexCount < mMaxVertexCount) {
            let vertexSize = MemoryLayout<Vertex>.size
            memcpy(mVertexBuffer.contents() + vertexSize * Int(mVertexCount), &vertex, vertexSize)
            mVertexCount += 1
        }
    }
    
    func addIndex(index: inout UInt32) {
        if (mIndexCount < mMaxIndexCount) {
            let indexSize = MemoryLayout<UInt32>.size
            memcpy(mIndexBuffer.contents() + indexSize * Int(mIndexCount), &index, indexSize)
            mIndexCount += 1
        }
    }
    
    // MARK: - texture utilities
    func createAliasingTexture(texture: MTLTexture) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = texture.pixelFormat
        textureDescriptor.width = texture.width
        textureDescriptor.height = texture.height
        textureDescriptor.textureType = .type2DMultisample
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.sampleCount = self.sampleCount
        return mDevice.makeTexture(descriptor: textureDescriptor)
    }
    
    func createDepthTexture(texture: MTLTexture) -> MTLTexture? {
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: texture.width, height: texture.height, mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite, .pixelFormatView]
        depthTextureDescriptor.textureType = .type2DMultisample
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.resourceOptions = [.storageModePrivate]
        depthTextureDescriptor.sampleCount = 4
        return mDevice.makeTexture(descriptor: depthTextureDescriptor)
    }
    
    // MARK: - public methods
    public func update() {
        self.setNeedsDisplay()
    }
    
    public func tearDownMetal() {
        //mVertexBuffer.setPurgeableState(.empty)
        //mIndexBuffer.setPurgeableState(.empty)
        //mTextureDepth?.setPurgeableState(.empty)
        //mTexture?.setPurgeableState(.empty)
        
        mVertexBuffer = nil
        mIndexBuffer = nil
        mTextureDepth = nil
        mTexture = nil
    }
    
    // MARK: - other methods
    func internalInit() {
        //self.enableSetNeedsDisplay = true
        //self.isPaused = true
        self.framebufferOnly = false
        self.isOpaque = false
        
        self.colorPixelFormat = .bgra8Unorm
        self.sampleCount = 4
        self.depthStencilPixelFormat = .depth32Float
        
        self.setupMetal()
        
        //NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        //UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    func setupMetal() {
        mDevice = MTLCreateSystemDefaultDevice()
        mCommandQueue = mDevice.makeCommandQueue()
        self.device = mDevice
        //self.delegate = self
        
        mLookAt = GLKMatrix4MakeLookAt(0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(Float(self.bounds.width / self.bounds.height)), 0.1, 100.0);
        mSceneMatrices.projectionMatrix = projectionMatrix
        
        var vertexBuffer = Array<Vertex>(repeating: Vertex.zero(), count: mMaxVertexCount)
        let vertexBufferSize = vertexBuffer.count * MemoryLayout<Vertex>.size
        mVertexBuffer = mDevice.makeBuffer(bytes: &vertexBuffer, length: vertexBufferSize, options: .storageModeShared)
        
        var indexBuffer = Array<UInt32>(repeating: 0, count: mMaxIndexCount)
        let indexBufferSize = indexBuffer.count * MemoryLayout<UInt32>.size
        mIndexBuffer = mDevice.makeBuffer(bytes: &indexBuffer, length: indexBufferSize, options: .storageModeShared)
        
        guard let defaultLibrary = mDevice.makeDefaultLibrary() else { return }
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        //pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.sampleCount = self.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
        
        mPipelineState = try! mDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        mDepthStencilState = mDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        mVertexCount = 0
        mIndexCount = 0
    }
}
