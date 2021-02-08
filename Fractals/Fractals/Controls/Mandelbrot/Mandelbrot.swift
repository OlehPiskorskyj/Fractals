//
//  Mandelbrot.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 07/02/2021.
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

class Mandelbrot: MTKView {
    
    // MARK: - consts
    public struct Consts {
        static let FRACTAL_SIZE =                                   300
        static let FRACTAL_MAX_VERTICES =                           FRACTAL_SIZE * FRACTAL_SIZE * 4
        static let FRACTAL_MAX_INDICES =                            FRACTAL_MAX_VERTICES * 3
    }
    
    // MARK: - props
    private var mDevice: MTLDevice!
    private var mCommandQueue: MTLCommandQueue!
    private var mPipelineState: MTLRenderPipelineState!
    private var mDepthStencilState: MTLDepthStencilState!
    private var mTexture: MTLTexture? = nil
    
    private var mSceneMatrices = SceneMatrices()
    private var mUniformBuffer: MTLBuffer!
    private var mLookAt: GLKMatrix4 = GLKMatrix4Identity
    private var mAngle: Float = 0.0
    
    private var mVertexBuffer: MTLBuffer!
    private var mIndexBuffer: MTLBuffer!
    private var mVertexCount = 0
    private var mIndexCount = 0
    
    private var mCurrentOrientation: UIDeviceOrientation = .unknown
    private var mIsUpdateWithOrientation: Bool = false
    
    private var mFractalPointRealPart: Double = 0.0
    private var mFractalPointImaginePart: Double = 0.0
    private var mFractalNewRealPart: Double = 0.0
    private var mFractalNewImaginePart: Double = 0.0
    private var mFractalOldRealPart: Double = 0.0
    private var mFractalOldImaginePart: Double = 0.0
    private var mFractalZoom: Double = 0.0
    private var mFractalX: Double = 0.0
    private var mFractalY: Double = 0.0
    private var mFractalIterationsCount: Int = 0
    
    // MARK: - ctors
    override public init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.internalInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self.internalInit()
    }
    
    // MARK: - vertex math utility methods
    func addColor2Vertex(vertex: inout Vertex, n: Int) {
        var color: GLKVector3? = nil
        if (n == mFractalIterationsCount) {
            color = GLKVector3Make(0.2, 0.4, 0.8)
        } else if (n < 12) {
            color = GLKVector3Make(0.0, 0.0, 0.0)
        } else {
            //int color = (int)(n * logf(n)) % 256;
            //int color = (int)(n * sinf(n)) % 256;
            //int color = n % 256;
            let c = GLfloat((n * n + n) % 256)
            color = GLKVector3Make(c / 255.0 + 0.3, c / 255.0 + 0.3, 0.0)
        }
        
        vertex.r = color!.r
        vertex.g = color!.g
        vertex.b = color!.b
    }
    
    func addVertex(vertex: inout Vertex) {
        if (mVertexCount < Consts.FRACTAL_MAX_VERTICES) {
            let vertexSize = MemoryLayout<Vertex>.size
            memcpy(mVertexBuffer.contents() + vertexSize * mVertexCount, &vertex, vertexSize)
            mVertexCount += 1
        }
    }
    
    func addIndex(index: inout UInt32) {
        if (mIndexCount < Consts.FRACTAL_MAX_INDICES) {
            let indexSize = MemoryLayout<UInt32>.size
            memcpy(mIndexBuffer.contents() + indexSize * mIndexCount, &index, indexSize)
            mIndexCount += 1
        }
    }
    
    // MARK: - public methods
    public func update() {
        self.setNeedsDisplay()
    }
    
    public func updateWithOrientation(update: Bool) {
        mIsUpdateWithOrientation = update
    }
    
    public func tearDownMetal() {
        mVertexBuffer = nil
        mTexture = nil
    }
    
    // MARK: - orientation
    @objc func deviceRotated(notification: NSNotification) {
        if (!mIsUpdateWithOrientation) {
            return
        }
        
        let orientation = UIDevice.current.orientation
        if (orientation != mCurrentOrientation &&
            orientation != .portraitUpsideDown) {
            self.update()
            mCurrentOrientation = orientation
        }
    }
    
    // MARK: - fractal logic
    func createMandelbrot() {
        mAngle = 0.33
        mVertexCount = 0
        mIndexCount = 0

        mFractalZoom = 1.0
        mFractalX = -0.5
        mFractalY = 0.0
        mFractalIterationsCount = 250
        
        let delta = 1.0 / Double(Consts.FRACTAL_SIZE)
        
        for x in 0..<Consts.FRACTAL_SIZE {
            for y in 0..<Consts.FRACTAL_SIZE {
                
                let v1m = self.mandelbrot(x: x, y: y + 1)
                let v2m = self.mandelbrot(x: x, y: y)
                let v3m = self.mandelbrot(x: x + 1, y: y + 1)
                let v4m = self.mandelbrot(x: x + 1, y: y)
                
                var v1 = Vertex(x: GLfloat(Double(x) * delta), y: GLfloat(Double(v1m) / 255.0), z: GLfloat(Double(y + 1) * delta), r: 1, g: 0, b: 0)
                self.addColor2Vertex(vertex: &v1, n: v1m)
                var v2 = Vertex(x: GLfloat(Double(x) * delta), y: GLfloat(Double(v2m) / 255.0), z: GLfloat(Double(y) * delta), r: 1, g: 0, b: 0)
                self.addColor2Vertex(vertex: &v2, n: v2m)
                var v3 = Vertex(x: GLfloat(Double(x + 1) * delta), y: GLfloat(Double(v3m) / 255.0), z: GLfloat(Double(y + 1) * delta), r: 1, g: 0, b: 0)
                self.addColor2Vertex(vertex: &v3, n: v3m)
                var v4 = Vertex(x: GLfloat(Double(x + 1) * delta), y: GLfloat(Double(v4m) / 255.0), z: GLfloat(Double(y) * delta), r: 1, g: 0, b: 0)
                self.addColor2Vertex(vertex: &v4, n: v4m)
                
                var index1 = UInt32(mVertexCount)
                var index2 = UInt32(mVertexCount + 1)
                var index3 = UInt32(mVertexCount + 1)
                var index4 = UInt32(mVertexCount + 2)
                var index5 = UInt32(mVertexCount + 2)
                var index6 = UInt32(mVertexCount)
                
                var index7 = UInt32(mVertexCount + 1)
                var index8 = UInt32(mVertexCount + 3)
                var index9 = UInt32(mVertexCount + 3)
                var index10 = UInt32(mVertexCount + 2)
                var index11 = UInt32(mVertexCount + 2)
                var index12 = UInt32(mVertexCount + 1)
                
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
                self.addIndex(index: &index11)
                self.addIndex(index: &index12)
                
                self.addVertex(vertex: &v1)
                self.addVertex(vertex: &v2)
                self.addVertex(vertex: &v3)
                self.addVertex(vertex: &v4)
            }
        }
    }

    func mandelbrot(x: Int, y: Int) -> Int {
        
        // calculate the initial real and imaginary part of z, based on the pixel location and zoom and position values
        mFractalPointRealPart = 1.5 * Double(x - Consts.FRACTAL_SIZE / 2) / (0.5 * mFractalZoom * Double(Consts.FRACTAL_SIZE)) + mFractalX
        mFractalPointImaginePart = Double(y - Consts.FRACTAL_SIZE / 2) / (0.5 * mFractalZoom * Double(Consts.FRACTAL_SIZE)) + mFractalY
        mFractalNewRealPart = 0.0
        mFractalNewImaginePart = 0.0
        mFractalOldRealPart = 0.0
        mFractalOldImaginePart = 0.0
        
        // "i" will represent the number of iterations
        var iterations = 0
        
        // start the iteration process
        for i in 0..<mFractalIterationsCount {
            iterations = i + 1
            
            // remember value of previous iteration
            mFractalOldRealPart = mFractalNewRealPart;
            mFractalOldImaginePart = mFractalNewImaginePart;
            
            // the actual iteration, the real and imaginary part are calculated
            mFractalNewRealPart = mFractalOldRealPart * mFractalOldRealPart - mFractalOldImaginePart * mFractalOldImaginePart + mFractalPointRealPart;
            mFractalNewImaginePart = 2.0 * mFractalOldRealPart * mFractalOldImaginePart + mFractalPointImaginePart;
            
            // if the point is outside the circle with radius 2: stop
            if ((mFractalNewRealPart * mFractalNewRealPart + mFractalNewImaginePart * mFractalNewImaginePart) > 4.0) {
                break
            }
        }
        
        return iterations
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
        
        DispatchQueue.global().async {
            self.createMandelbrot()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    func setupMetal() {
        mDevice = MTLCreateSystemDefaultDevice()
        mCommandQueue = mDevice.makeCommandQueue()
        self.device = mDevice
        self.delegate = self
        
        mLookAt = GLKMatrix4MakeLookAt(0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(Float(self.bounds.width / self.bounds.height)), 0.1, 100.0);
        mSceneMatrices.projectionMatrix = projectionMatrix
        
        var vertexBuffer = Array<Vertex>(repeating: Vertex.zero(), count: Consts.FRACTAL_MAX_VERTICES)
        let vertexBufferSize = vertexBuffer.count * MemoryLayout<Vertex>.size
        mVertexBuffer = mDevice.makeBuffer(bytes: &vertexBuffer, length: vertexBufferSize, options: .storageModeShared)
        
        var indexBuffer = Array<Int>(repeating: 0, count: Consts.FRACTAL_MAX_INDICES)
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
}

extension Mandelbrot: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(Float(view.frame.width / view.frame.height)), 0.1, 100.0);
        mSceneMatrices.projectionMatrix = projectionMatrix
        mTexture = nil
    }
    
    func draw(in view: MTKView) {
        #if targetEnvironment(simulator)
        return
        #else
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        if (mTexture == nil) {
            mTexture = self.createAliasingTexture(texture: drawable.texture)
        }
        
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: mTexture!.width, height: mTexture!.height, mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite, .pixelFormatView]
        depthTextureDescriptor.textureType = .type2DMultisample
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.resourceOptions = [.storageModePrivate]
        depthTextureDescriptor.sampleCount = 4
        
        let depthAttachementTexureDescriptor = MTLRenderPassDepthAttachmentDescriptor()
        depthAttachementTexureDescriptor.clearDepth = 1.0
        depthAttachementTexureDescriptor.loadAction = .clear
        depthAttachementTexureDescriptor.storeAction = .dontCare
        depthAttachementTexureDescriptor.texture = mDevice.makeTexture(descriptor: depthTextureDescriptor)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = mTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        renderPassDescriptor.depthAttachment = depthAttachementTexureDescriptor
        
        guard let commandBuffer = mCommandQueue.makeCommandBuffer() else { return }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
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
            renderEncoder.drawIndexedPrimitives(type: .line, indexCount: mIndexCount, indexType: .uint32, indexBuffer: mIndexBuffer, indexBufferOffset: 0)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        mAngle += 0.01
        
        #endif
    }
}
