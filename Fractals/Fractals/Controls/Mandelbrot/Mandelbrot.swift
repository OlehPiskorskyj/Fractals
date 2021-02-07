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
    public static func zero() -> Vertex {
        return Vertex.init(x: 0, y: 0, z: 0)
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
    
    private var mSceneMatrices = SceneMatrices()
    private var mUniformBuffer: MTLBuffer!
    
    private var mVertexBuffer: MTLBuffer!
    private var mTexture: MTLTexture? = nil
    
    private var mCurrentOrientation: UIDeviceOrientation = .unknown
    private var mIsUpdateWithOrientation: Bool = false
    
    
    //@private EAGLContext *mContext;
    //@private GLKBaseEffect *mEffect;
        
    //@private GLKMatrix4 mLookAt;
    private var mAngle: Float = 0.0
    
    //@private Vertex *mVertexData;
    private var mVertexCount = 0
    //@private GLuint mVertexBuffer;
    //@private GLuint mVertexArray;
      
    /*
    @private GLuint *mIndexData;
    @private GLuint mIndexCount;
    @private GLuint mIndexBuffer;
    */
    
    private var mLookAt: GLKMatrix4 = GLKMatrix4Identity
    
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
        var color: GLKVector4? = nil
        if (n == mFractalIterationsCount) {
            color = GLKVector4Make(0.2, 0.4, 0.8, 1.0)
        } else if (n < 12) {
            color = GLKVector4Make(0.0, 0.0, 0.0, 1.0)
        } else {
            //int color = (int)(n * logf(n)) % 256;
            //int color = (int)(n * sinf(n)) % 256;
            //int color = n % 256;
            let c = GLfloat((n * n + n) % 256)
            color = GLKVector4Make(c / 255.0 + 0.3, c / 255.0 + 0.3, 0.0, 1.0)
        }
        
        /*
        ((Vertex)*vertex).Color[0] = color.r;
        ((Vertex)*vertex).Color[1] = color.g;
        ((Vertex)*vertex).Color[2] = color.b;
        ((Vertex)*vertex).Color[3] = color.a;
        */
    }
    
    private func addVertex(vertex: inout Vertex) {
        if (mVertexCount < Consts.FRACTAL_MAX_VERTICES) {
            let vertexSize = MemoryLayout<Vertex>.size
            memcpy(mVertexBuffer.contents() + vertexSize * mVertexCount, &vertex, vertexSize)
            mVertexCount += 1
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
        //mIndexCount = 0;
        
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
                
                var v1 = Vertex(x: GLfloat(Double(x) * delta), y: GLfloat(Double(v1m) / 255.0), z: GLfloat(Double(y + 1) * delta))
                self.addColor2Vertex(vertex: &v1, n: v1m)
                var v2 = Vertex(x: GLfloat(Double(x) * delta), y: GLfloat(Double(v2m) / 255.0), z: GLfloat(Double(y) * delta))
                self.addColor2Vertex(vertex: &v2, n: v2m)
                var v3 = Vertex(x: GLfloat(Double(x + 1) * delta), y: GLfloat(Double(v3m) / 255.0), z: GLfloat(Double(y + 1) * delta))
                self.addColor2Vertex(vertex: &v3, n: v3m)
                var v4 = Vertex(x: GLfloat(Double(x + 1) * delta), y: GLfloat(Double(v4m) / 255.0), z: GLfloat(Double(y) * delta))
                self.addColor2Vertex(vertex: &v4, n: v4m)
                
                /*
                GLuint index1 = mVertexCount;
                GLuint index2 = mVertexCount + 1;
                GLuint index3 = mVertexCount + 1;
                GLuint index4 = mVertexCount + 2;
                GLuint index5 = mVertexCount + 2;
                GLuint index6 = mVertexCount;
                
                GLuint index7 = mVertexCount + 1;
                GLuint index8 = mVertexCount + 3;
                GLuint index9 = mVertexCount + 3;
                GLuint index10 = mVertexCount + 2;
                GLuint index11 = mVertexCount + 2;
                GLuint index12 = mVertexCount + 1;
                
                [self addIndex:&index1];
                [self addIndex:&index2];
                [self addIndex:&index3];
                [self addIndex:&index4];
                [self addIndex:&index5];
                [self addIndex:&index6];
                
                [self addIndex:&index7];
                [self addIndex:&index8];
                [self addIndex:&index9];
                [self addIndex:&index10];
                [self addIndex:&index11];
                [self addIndex:&index12];
                */
                
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
        
        //start the iteration process
        for i in 0..<mFractalIterationsCount {
            //remember value of previous iteration
            mFractalOldRealPart = mFractalNewRealPart;
            mFractalOldImaginePart = mFractalNewImaginePart;
            //the actual iteration, the real and imaginary part are calculated
            mFractalNewRealPart = mFractalOldRealPart * mFractalOldRealPart - mFractalOldImaginePart * mFractalOldImaginePart + mFractalPointRealPart;
            mFractalNewImaginePart = 2.0 * mFractalOldRealPart * mFractalOldImaginePart + mFractalPointImaginePart;
            //if the point is outside the circle with radius 2: stop
            if ((mFractalNewRealPart * mFractalNewRealPart + mFractalNewImaginePart * mFractalNewImaginePart) > 4.0) {
                iterations = i
                break
            }
        }
        
        return iterations
    }
    
    // MARK: - other methods
    private func internalInit() {
        //self.enableSetNeedsDisplay = true
        //self.isPaused = true
        self.framebufferOnly = false
        self.isOpaque = false
        self.sampleCount = 4
        
        self.setupMetal()
        self.createMandelbrot()
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    private func setupMetal() {
        mDevice = MTLCreateSystemDefaultDevice()
        mCommandQueue = mDevice.makeCommandQueue()
        self.device = mDevice
        self.delegate = self
        
        mLookAt = GLKMatrix4MakeLookAt(0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), fabsf(Float(self.bounds.width / self.bounds.height)), 0.1, 100.0);
        mSceneMatrices.projectionMatrix = projectionMatrix
        
        var signatureVertices = Array<Vertex>(repeating: Vertex.zero(), count: Consts.FRACTAL_MAX_VERTICES)
        let vertexBufferSize = signatureVertices.count * MemoryLayout<Vertex>.size
        mVertexBuffer = mDevice.makeBuffer(bytes: &signatureVertices, length: vertexBufferSize, options: .storageModeShared)
        
        guard let defaultLibrary = mDevice.makeDefaultLibrary() else { return }
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        //pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.sampleCount = self.sampleCount
        
        mPipelineState = try! mDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        mVertexCount = 0
    }
    
    private func createAliasingTexture(texture: MTLTexture) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = texture.pixelFormat
        textureDescriptor.width = texture.width
        textureDescriptor.height = texture.height
        textureDescriptor.textureType = MTLTextureType.type2DMultisample
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
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = mTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        
        guard let commandBuffer = mCommandQueue.makeCommandBuffer() else { return }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        var modelView = GLKMatrix4Multiply(GLKMatrix4MakeScale(10.0, 1.0, 10.0), GLKMatrix4MakeRotation(mAngle, 0.0, 1.0, 0.0))
        modelView = GLKMatrix4Multiply(modelView, GLKMatrix4MakeTranslation(-0.5, 0.0, -0.5))
        mSceneMatrices.modelviewMatrix = GLKMatrix4Multiply(mLookAt, modelView)
        let uniformBufferSize = MemoryLayout.size(ofValue: mSceneMatrices)
        mUniformBuffer = mDevice.makeBuffer(bytes: &mSceneMatrices, length: uniformBufferSize, options: .storageModeShared)
        renderEncoder.setVertexBuffer(mUniformBuffer, offset: 0, index: 1)
        renderEncoder.setRenderPipelineState(mPipelineState)
        
        if (mVertexCount > 0) {
            renderEncoder.setVertexBuffer(mVertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: mVertexCount)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        mAngle += 0.01
        
        #endif
    }
}
