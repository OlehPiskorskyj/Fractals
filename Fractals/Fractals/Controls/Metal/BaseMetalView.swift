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
    var x: Float
    var y: Float
    var z: Float
    var r: Float
    var g: Float
    var b: Float
    public static func zero() -> Vertex {
        return Vertex.init(x: 0, y: 0, z: 0, r: 0, g: 0, b: 0)
    }
}

struct SceneMatrices {
    var projection: GLKMatrix4 = GLKMatrix4Identity
    var modelview: GLKMatrix4 = GLKMatrix4Identity
}


class BaseMetalView: MTKView {
    
    // MARK: - props
    public var metalDevice: MTLDevice!
    public var commandQueue: MTLCommandQueue!
    public var pipelineState: MTLRenderPipelineState!
    public var depthStencilState: MTLDepthStencilState!
    private var textureDepth: MTLTexture? = nil
    private var texture: MTLTexture? = nil
    
    public var sceneMatrices = SceneMatrices()
    public var uniformBuffer: MTLBuffer!
    public var lookAt: GLKMatrix4 = GLKMatrix4Identity
    
    public var vertexBuffer: MTLBuffer!
    public var indexBuffer: MTLBuffer!
    public var vertexCount: UInt32 = 0
    public var indexCount: UInt32 = 0
    public var maxVertexCount = 0
    public var maxIndexCount = 0
    
    public var rotating: Bool = false
    public var angle: Float = 0.0
    public var zoom: Float = -5.0
    
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
    
    // MARK: - vertex logic
    func addVertex(vertex: inout Vertex) {
        if (vertexCount < maxVertexCount) {
            let vertexSize = MemoryLayout<Vertex>.size
            memcpy(vertexBuffer.contents() + vertexSize * Int(vertexCount), &vertex, vertexSize)
            vertexCount += 1
        }
    }
    
    func addIndex(index: inout UInt32) {
        if (indexCount < maxIndexCount) {
            let indexSize = MemoryLayout<UInt32>.size
            memcpy(indexBuffer.contents() + indexSize * Int(indexCount), &index, indexSize)
            indexCount += 1
        }
    }
    
    // MARK: - utilities
    func updateProjectionMatrix(aspectRatio: Float) {
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(aspectRatio), 0.1, 100.0);
        sceneMatrices.projection = projectionMatrix
        textureDepth = nil
        texture = nil
    }
    
    func createRenderPassDescriptor(drawable: CAMetalDrawable) -> MTLRenderPassDescriptor {
        if (texture == nil) {
            texture = self.createAliasingTexture(texture: drawable.texture)
        }
        
        if (textureDepth == nil) {
            textureDepth = self.createDepthTexture(texture: drawable.texture)
        }
        
        let depthAttachementTexureDescriptor = MTLRenderPassDepthAttachmentDescriptor()
        depthAttachementTexureDescriptor.clearDepth = 1.0
        depthAttachementTexureDescriptor.loadAction = .clear
        depthAttachementTexureDescriptor.storeAction = .dontCare
        depthAttachementTexureDescriptor.texture = textureDepth
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        renderPassDescriptor.depthAttachment = depthAttachementTexureDescriptor
        
        return renderPassDescriptor
    }
    
    func createAliasingTexture(texture: MTLTexture) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = texture.pixelFormat
        textureDescriptor.width = texture.width
        textureDescriptor.height = texture.height
        textureDescriptor.textureType = .type2DMultisample
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.sampleCount = self.sampleCount
        return metalDevice.makeTexture(descriptor: textureDescriptor)
    }
    
    func createDepthTexture(texture: MTLTexture) -> MTLTexture? {
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: texture.width, height: texture.height, mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite, .pixelFormatView]
        depthTextureDescriptor.textureType = .type2DMultisample
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.resourceOptions = [.storageModePrivate]
        depthTextureDescriptor.sampleCount = 4
        return metalDevice.makeTexture(descriptor: depthTextureDescriptor)
    }
    
    // MARK: - public methods
    public func update() {
        self.setNeedsDisplay()
    }
    
    public func tearDownMetal() {
        //vertexBuffer.setPurgeableState(.empty)
        //indexBuffer.setPurgeableState(.empty)
        //textureDepth?.setPurgeableState(.empty)
        //texture?.setPurgeableState(.empty)
        
        vertexBuffer = nil
        indexBuffer = nil
        textureDepth = nil
        texture = nil
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
        metalDevice = MTLCreateSystemDefaultDevice()
        commandQueue = metalDevice.makeCommandQueue()
        self.device = metalDevice
        
        lookAt = GLKMatrix4MakeLookAt(0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(Float(self.bounds.width / self.bounds.height)), 0.1, 100.0);
        sceneMatrices.projection = projectionMatrix
        
        var verBuffer = Array<Vertex>(repeating: Vertex.zero(), count: maxVertexCount)
        var bufferSize = verBuffer.count * MemoryLayout<Vertex>.size
        vertexBuffer = metalDevice.makeBuffer(bytes: &verBuffer, length: bufferSize, options: .storageModeShared)
        
        var indBuffer = Array<UInt32>(repeating: 0, count: maxIndexCount)
        bufferSize = indBuffer.count * MemoryLayout<UInt32>.size
        indexBuffer = metalDevice.makeBuffer(bytes: &indBuffer, length: bufferSize, options: .storageModeShared)
        
        guard let defaultLibrary = metalDevice.makeDefaultLibrary() else { return }
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat
        //pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.sampleCount = self.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
        
        pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        vertexCount = 0
        indexCount = 0
    }
}
