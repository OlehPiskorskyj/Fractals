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
        
        static let STROKE_WIDTH_MIN: Float =                        0.6                 // stroke width determined by touch velocity
        static let STROKE_WIDTH_MAX: Float =                        6.0
        static let STROKE_WIDTH_SMOOTHING: Float =                  0.3                 // low pass filter alpha
        static let VELOCITY_CLAMP_MIN: Float =                      5.0
        static let VELOCITY_CLAMP_MAX: Float =                      1500.0
        static let QUADRATIC_DISTANCE_TOLERANCE: Float =            3.14159265          // minimum distance to make a curve
        static let MAXIMUM_VERTICES =                               100000
    }
    
    // MARK: - enums
    /*
    public enum VertexType: Int {
        case signature
        case startEnd
    }
    */
    
    // MARK: - props
    private var mDevice: MTLDevice!
    private var mCommandQueue: MTLCommandQueue!
    private var mPipelineState: MTLRenderPipelineState!
    
    private var mSceneMatrices = SceneMatrices()
    private var mUniformBuffer: MTLBuffer!
    
    private var mSignatureVerticesBuffer: MTLBuffer!
    private var mTexture: MTLTexture? = nil
    
    private var mPanGestureRecogniser: UIPanGestureRecognizer? = nil
    private var mCurrentOrientation: UIDeviceOrientation = .unknown
    
    private var mSignatureVerticesCount = 0
    
    private var mPreviousThickness: Float = 0.0
    private var mPenThickness: Float = 0.0
    
    private var mPreviousVertex: Vertex!
    private var mPreviousMidPoint: CGPoint!
    private var mPreviousPoint: CGPoint!
    
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
    
    // MARK: - gesture recognizers
    @objc func pan(p: UIPanGestureRecognizer) {
        let v = p.velocity(in: self)
        let l = p.location(in: self)
        
        // higher speed thinner line
        var temp: CGFloat = 0.0
        temp = (l.x - mPreviousPoint.x) * (l.x - mPreviousPoint.x) + (l.y - mPreviousPoint.y) * (l.y - mPreviousPoint.y)
        let distance = sqrtf(Float(temp))
        temp = v.x * v.x + v.y * v.y
        let velocityMagnitude = sqrtf(Float(temp))
        let clampedVelocityMagnitude = clamp(min: Consts.VELOCITY_CLAMP_MIN, max: Consts.VELOCITY_CLAMP_MAX, value: velocityMagnitude)
        let normalizedVelocity = (clampedVelocityMagnitude - Consts.VELOCITY_CLAMP_MIN) / (Consts.VELOCITY_CLAMP_MAX - Consts.VELOCITY_CLAMP_MIN)
        let lowPassFilterAlpha = Consts.STROKE_WIDTH_SMOOTHING
        let newThickness = (Consts.STROKE_WIDTH_MAX - Consts.STROKE_WIDTH_MIN) * normalizedVelocity + Consts.STROKE_WIDTH_MIN
        mPenThickness = Consts.STROKE_WIDTH_MAX - (mPenThickness * lowPassFilterAlpha + newThickness * (1 - lowPassFilterAlpha))
        
        if (p.state == .began) {
            mPreviousMidPoint = l
            mPreviousPoint = l
            
            var startPoint = Vertex(x: GLfloat(l.x), y: GLfloat(self.bounds.size.height - l.y), z: 0)
            mPreviousVertex = startPoint
            mPreviousThickness = mPenThickness
            
            self.addVertex(vertex: &startPoint)
            self.addVertex(vertex: &mPreviousVertex)
            
        } else if (p.state == .changed) {
            let mid = CGPoint(x: (l.x + mPreviousPoint.x) / 2.0, y: (l.y + mPreviousPoint.y) / 2.0)
            if (distance > Consts.QUADRATIC_DISTANCE_TOLERANCE) {
                let segments = Int(distance / 1.5)
                
                let startPenThickness = mPreviousThickness
                let endPenThickness = mPenThickness
                mPreviousThickness = mPenThickness
                
                for i in 0..<segments {
                    mPenThickness = startPenThickness + ((endPenThickness - startPenThickness) / Float(segments)) * Float(i)
                    let t = Double(i) / Double(segments)
                    let a = pow(1.0 - t, 2.0)
                    let b = 2.0 * t * (1.0 - t)
                    let c = pow(t, 2.0)
                    let x = a * Double(mPreviousMidPoint.x) + b * Double(mPreviousPoint.x) + c * Double(mid.x)
                    let y = a * Double(mPreviousMidPoint.y) + b * Double(mPreviousPoint.y) + c * Double(mid.y)
                    
                    var vertex = Vertex(x: GLfloat(x), y: GLfloat(Double(self.bounds.size.height) - y), z: 0)
                    self.addTriangleStripPoints(previous: &mPreviousVertex, next: &vertex)
                    mPreviousVertex = vertex
                }
            } else if (distance > 1.0) {
                var vertex = Vertex(x: GLfloat(l.x), y: GLfloat(self.bounds.size.height - l.y), z: 0)
                self.addTriangleStripPoints(previous: &mPreviousVertex, next: &vertex)
                mPreviousVertex = vertex
                mPreviousThickness = mPenThickness
            }
            
            mPreviousPoint = l
            mPreviousMidPoint = mid
            
        } else if (p.state == .ended || p.state == .cancelled) {
            var vertex = Vertex(x: GLfloat(l.x), y: GLfloat(self.bounds.size.height - l.y), z: 0)
            self.addTriangleStripPoints(previous: &mPreviousVertex, next: &vertex)
            mPreviousVertex = vertex
            self.addTriangleStripPoints(previous: &mPreviousVertex, next: &vertex)
        }
        
        self.setNeedsDisplay()
    }
    
    // MARK: - vertex math utility methods
    private func addVertex(vertex: inout Vertex) {
        if (mSignatureVerticesCount < Consts.MAXIMUM_VERTICES) {
            let vertexSize = MemoryLayout<Vertex>.size
            memcpy(mSignatureVerticesBuffer.contents() + vertexSize * mSignatureVerticesCount, &vertex, vertexSize)
            mSignatureVerticesCount += 1
        }
    }
    
    private func addTriangleStripPoints(previous: inout Vertex, next: inout Vertex) {
        var toTravel = mPenThickness / 2.0
        for _ in 0..<2 {
            let p = self.perpendicular(p1: &previous, p2: &next)
            let p1 = GLKVector3(v: (next.x, next.y, next.z))
            let ref = GLKVector3Add(p1, p)
            
            let distance = GLKVector3Distance(p1, ref)
            var difX = p1.x - ref.x
            var difY = p1.y - ref.y
            let ratio = -1.0 * (toTravel / distance)
            
            difX = difX * ratio
            difY = difY * ratio
            
            var stripPoint = Vertex(x: p1.x + difX, y: p1.y + difY, z: 0)
            self.addVertex(vertex: &stripPoint)
            
            toTravel *= -1
        }
    }
    
    private func clamp(min: Float, max: Float, value: Float) -> Float {
        return fmaxf(min, fminf(max, value))
    }
    
    private func perpendicular(p1: inout Vertex, p2: inout Vertex) -> GLKVector3 {
        return GLKVector3(v: (p2.y - p1.y, -1.0 * (p2.x - p1.x), 0))
    }
    
    // MARK: - public methods
    public func update() {
        self.setNeedsDisplay()
    }
    
    public func updateWithOrientation(update: Bool) {
        mIsUpdateWithOrientation = update
    }
    
    public func isEmpty() -> Bool {
        return (mSignatureVerticesCount == 0)
    }
    
    public func tearDownMetal() {
        mSignatureVerticesBuffer = nil
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
        /*
        mAngle = 0.33f;
        mIndexCount = 0;
        mVertexCount = 0;
        
        mFractalZoom = 1;
        mFractalX = -0.5;
        mFractalY = 0.0;
        mFractalIterationsCount = 250;
        
        float delta = 1.0f / FRACTAL_SIZE;
        
        for (int x = 0; x < FRACTAL_SIZE; x++)
        {
            for (int y = 0; y < FRACTAL_SIZE; y++)
            {
                int v1m = [self mandelbrotWithX:x Y:y + 1];
                int v2m = [self mandelbrotWithX:x Y:y];
                int v3m = [self mandelbrotWithX:x + 1 Y:y + 1];
                int v4m = [self mandelbrotWithX:x + 1 Y:y];
                
                Vertex v1 = {{
                    x * delta,
                    v1m / 255.0f,
                    (y + 1) * delta
                },
                    {1.0f, 1.0f, 1.0f, 1.0f},
                    {0.0f, 0.0f}};
                [self addColorToVertex:&v1 MandelbrotN:v1m];
                Vertex v2 = {{
                    x * delta,
                    v2m / 255.0f,
                    y * delta
                },
                    {1.0f, 1.0f, 1.0f, 1.0f},
                    {0.0f, 0.0f}};
                [self addColorToVertex:&v2 MandelbrotN:v2m];
                Vertex v3 = {{
                    (x + 1) * delta,
                    v3m / 255.0f,
                    (y + 1) * delta
                },
                    {1.0f, 1.0f, 1.0f, 1.0f},
                    {0.0f, 0.0f}};
                [self addColorToVertex:&v3 MandelbrotN:v3m];
                Vertex v4 = {{
                    (x + 1) * delta,
                    v4m / 255.0f,
                    y * delta
                },
                    {1.0f, 1.0f, 1.0f, 1.0f},
                    {0.0f, 0.0f}};
                [self addColorToVertex:&v4 MandelbrotN:v4m];
                
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
                
                [self addVertex:&v1];
                [self addVertex:&v2];
                [self addVertex:&v3];
                [self addVertex:&v4];
            }
        }
        */
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
            iterations = i
            //remember value of previous iteration
            mFractalOldRealPart = mFractalNewRealPart;
            mFractalOldImaginePart = mFractalNewImaginePart;
            //the actual iteration, the real and imaginary part are calculated
            mFractalNewRealPart = mFractalOldRealPart * mFractalOldRealPart - mFractalOldImaginePart * mFractalOldImaginePart + mFractalPointRealPart;
            mFractalNewImaginePart = 2 * mFractalOldRealPart * mFractalOldImaginePart + mFractalPointImaginePart;
            //if the point is outside the circle with radius 2: stop
            if ((mFractalNewRealPart * mFractalNewRealPart + mFractalNewImaginePart * mFractalNewImaginePart) > 4) {
                break
            }
        }
        
        return iterations
    }
    
    // MARK: - other methods
    private func internalInit() {
        self.enableSetNeedsDisplay = true
        self.framebufferOnly = false
        self.isOpaque = false
        self.sampleCount = 4
        
        self.setupMetal()
        
        mPanGestureRecogniser = UIPanGestureRecognizer()
        mPanGestureRecogniser!.addTarget(self, action: #selector(pan))
        mPanGestureRecogniser!.maximumNumberOfTouches = 1
        mPanGestureRecogniser!.minimumNumberOfTouches = 1
        self.addGestureRecognizer(mPanGestureRecogniser!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    private func setupMetal() {
        mDevice = MTLCreateSystemDefaultDevice()
        mCommandQueue = mDevice.makeCommandQueue()
        self.device = mDevice
        self.delegate = self
        
        let projectionMatrix = GLKMatrix4MakeOrtho(0.0, Float(self.bounds.size.width), 0.0, Float(self.bounds.size.height), -1.0, 1.0)
        mSceneMatrices.projectionMatrix = projectionMatrix
        
        var signatureVertices = Array<Vertex>(repeating: Vertex.zero(), count: Consts.MAXIMUM_VERTICES)
        let vertexBufferSize = signatureVertices.count * MemoryLayout<Vertex>.size
        mSignatureVerticesBuffer = mDevice.makeBuffer(bytes: &signatureVertices, length: vertexBufferSize, options: .storageModeShared)
        
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
        
        mSignatureVerticesCount = 0
        mPenThickness = 0.02
        mPreviousPoint = CGPoint(x: -100, y: -100)
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
        let projectionMatrix = GLKMatrix4MakeOrtho(0.0, Float(self.bounds.size.width), 0.0, Float(self.bounds.size.height), -1.0, 1.0)
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
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        
        guard let commandBuffer = mCommandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        let modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -0.1)
        mSceneMatrices.modelviewMatrix = modelViewMatrix
        let uniformBufferSize = MemoryLayout.size(ofValue: mSceneMatrices)
        mUniformBuffer = mDevice.makeBuffer(bytes: &mSceneMatrices, length: uniformBufferSize, options: .storageModeShared)
        renderEncoder.setVertexBuffer(mUniformBuffer, offset: 0, index: 1)
        renderEncoder.setRenderPipelineState(mPipelineState)
        
        if (mSignatureVerticesCount > 2) {
            renderEncoder.setVertexBuffer(mSignatureVerticesBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: mSignatureVerticesCount)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        #endif
    }
}
