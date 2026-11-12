import SceneKit
import UIKit
import SwiftUI

/// A spur gear driven by a worm screw, rendered in 3D (reference screenshot): the gear has a black satin face, pale
/// grey tooth flanks and a keyed bore; the worm is polished black steel that throws off white highlights. The worm's
/// threads keep running up its length and the gear turns with them, one tooth per thread. Coloured like a peak at
/// first light: dawn-sky backdrop, rock-dark face with a golden sheen, snow-pale flanks with sunlit rims.
struct GearWormPattern: View {
    /// Draw over the card's own background instead of the dawn sky
    var transparent = false
    /// Below 1 pulls the camera back, so the gear and screw sit smaller in the card
    var zoom: Float = 1
    @State private var stage = GearWormStage()

    var body: some View {
        let _ = stage.setZoom(zoom)
        if transparent {
            ClearSceneView(scene: stage.scene, camera: stage.camera)
        } else {
            SceneView(scene: stage.scene, pointOfView: stage.camera, options: [], antialiasingMode: .multisampling4X)
        }
    }
}

/// SceneKit view with a see-through background
private struct ClearSceneView: UIViewRepresentable {
    let scene: SCNScene
    let camera: SCNNode

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.pointOfView = camera
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true
        view.isPlaying = true
        scene.background.contents = UIColor.clear
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}
}

private final class GearWormStage {
    let scene = SCNScene()
    let camera = SCNNode()
    private static let cameraHome = SCNVector3(0.2, -0.15, 5.3)

    func setZoom(_ zoom: Float) {
        let z = Self.cameraHome.z / max(zoom, 0.1)
        if camera.position.z != z { camera.position = SCNVector3(Self.cameraHome.x, Self.cameraHome.y, z) }
    }

    // Gear: 20 teeth; the worm's thread pitch matches the tooth spacing at the pitch circle so they mesh
    private static let teeth = 20
    private static let tipRadius: CGFloat = 1.0
    private static let rootRadius: CGFloat = 0.82
    private static let pitchRadius: CGFloat = 0.91
    private static let thickness: CGFloat = 0.34
    private static let pitch: CGFloat = 2 * .pi * pitchRadius / CGFloat(teeth)
    /// One thread passes the gear every this many seconds
    private static let threadPeriod: TimeInterval = 0.55

    /// Alpenglow palette (a peak at first light): lavender-to-peach dawn sky, golden sun on the summit, near-black
    /// rock and lavender-tinted snow
    private enum Dawn {
        static let skyTop = UIColor(rgb: 0xD8D3E2)
        static let skyLow = UIColor(rgb: 0xF2E3DC)
        static let sun = UIColor(rgb: 0xF7D85A)
        static let sunDeep = UIColor(rgb: 0xE8B83C)
        static let rock = UIColor(rgb: 0x120D0B)
        static let snow = UIColor(rgb: 0xE6D9E0)
        static let shade = UIColor(rgb: 0xB7B0CB)
    }

    init() {
        scene.background.contents = Self.skyGradient()
        scene.lightingEnvironment.contents = Self.studioEnvironment()
        scene.lightingEnvironment.intensity = 1.0

        let gear = Self.gearNode()
        let worm = Self.wormNode()

        // Gear in the middle, turned a little so the flanks of its left-hand teeth show
        let gearPivot = SCNNode()
        gearPivot.eulerAngles = SCNVector3(0.1, 0.45, 0)
        gearPivot.position = SCNVector3(-0.05, 0.22, 0)
        gearPivot.addChildNode(gear)
        scene.rootNode.addChildNode(gearPivot)

        // Worm lies across the gear's lower right, in the gear's mid-plane, tangent to the teeth there
        let contact: Float = -0.72   // radians round the gear (lower right)
        let wormCentreRadius = Float(Self.pitchRadius) + 0.38
        worm.position = SCNVector3(cos(contact) * wormCentreRadius, sin(contact) * wormCentreRadius, 0)
        // Its axis runs along the gear's tangent there, up and to the right
        worm.eulerAngles = SCNVector3(0, 0, contact + .pi / 2)
        gearPivot.addChildNode(worm)

        // Alpenglow halo behind the gear, like the sun-struck summit glowing against the dawn sky
        let halo = SCNPlane(width: 3.6, height: 3.6)
        let haloMaterial = SCNMaterial()
        haloMaterial.lightingModel = .constant
        haloMaterial.diffuse.contents = Self.haloImage()
        haloMaterial.writesToDepthBuffer = false
        haloMaterial.blendMode = .alpha
        halo.materials = [haloMaterial]
        let haloNode = SCNNode(geometry: halo)
        haloNode.position = SCNVector3(-0.12, 0.3, -0.9)
        haloNode.renderingOrder = -1
        scene.rootNode.addChildNode(haloNode)

        // Gear advances one tooth per thread so the teeth stay in mesh
        let toothAngle = CGFloat(2 * Double.pi / Double(Self.teeth))
        gear.runAction(.repeatForever(.rotateBy(x: 0, y: 0, z: toothAngle, duration: Self.threadPeriod)))

        // Lights: a soft key from the upper left, a cool fill, and a low ambient
        let key = SCNNode()
        key.light = SCNLight()
        key.light!.type = .directional
        key.light!.color = UIColor(rgb: 0xFFE3B0)   // low warm sun
        key.light!.intensity = 1600
        key.light!.castsShadow = true
        key.light!.shadowRadius = 6
        key.light!.shadowColor = UIColor(rgb: 0x2A2234).withAlphaComponent(0.45)
        key.eulerAngles = SCNVector3(-0.6, -0.7, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light!.type = .directional
        fill.light!.color = Dawn.shade   // lavender skylight in the shadows
        fill.light!.intensity = 500
        fill.eulerAngles = SCNVector3(0.3, 0.9, 0)
        scene.rootNode.addChildNode(fill)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.color = Dawn.skyTop
        ambient.light!.intensity = 200
        scene.rootNode.addChildNode(ambient)

        // Golden rim light from behind and above, so the teeth tops and thread crests flare with sunrise
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light!.type = .directional
        rim.light!.color = UIColor(rgb: 0xF6C9A0)   // peach-gold, as the light turns from gold to pink on the snow
        rim.light!.intensity = 650
        rim.eulerAngles = SCNVector3(-1.1, -2.6, 0)
        scene.rootNode.addChildNode(rim)

        camera.camera = SCNCamera()
        camera.camera!.fieldOfView = 30
        // No HDR pass: it would tone the dawn sky down to grey
        camera.position = SCNVector3(0.2, -0.15, 5.3)
        scene.rootNode.addChildNode(camera)
    }

    // MARK: Gear

    private static func gearNode() -> SCNNode {
        let outline = UIBezierPath()
        let n = teeth
        for i in 0..<n {
            // Each tooth: up a flank to a flat tip, down the other flank, along the root
            let a0 = CGFloat(i) / CGFloat(n) * 2 * .pi
            let step = 2 * CGFloat.pi / CGFloat(n)
            let rootStart = a0, flankUp = a0 + step * 0.18, tipEnd = a0 + step * 0.42, flankDown = a0 + step * 0.6
            func point(_ r: CGFloat, _ a: CGFloat) -> CGPoint { CGPoint(x: r * cos(a), y: r * sin(a)) }
            if i == 0 { outline.move(to: point(rootRadius, rootStart)) } else { outline.addLine(to: point(rootRadius, rootStart)) }
            outline.addLine(to: point(tipRadius, flankUp))
            outline.addArc(withCenter: .zero, radius: tipRadius, startAngle: flankUp, endAngle: tipEnd, clockwise: true)
            outline.addLine(to: point(rootRadius, flankDown))
            outline.addArc(withCenter: .zero, radius: rootRadius, startAngle: flankDown, endAngle: a0 + step, clockwise: true)
        }
        outline.close()

        // Bore with a keyway notch at the top right
        let bore = UIBezierPath()
        let boreRadius: CGFloat = 0.42
        let keyHalf: CGFloat = 0.1
        let keyAngle: CGFloat = 0.5
        let start = keyAngle + asin(keyHalf / boreRadius)
        let end = keyAngle - asin(keyHalf / boreRadius) + 2 * .pi
        bore.addArc(withCenter: .zero, radius: boreRadius, startAngle: start, endAngle: end, clockwise: true)
        let dir = CGPoint(x: cos(keyAngle), y: sin(keyAngle)), side = CGPoint(x: -sin(keyAngle), y: cos(keyAngle))
        let depth: CGFloat = 0.54
        bore.addLine(to: CGPoint(x: dir.x * depth - side.x * keyHalf, y: dir.y * depth - side.y * keyHalf))
        bore.addLine(to: CGPoint(x: dir.x * depth + side.x * keyHalf, y: dir.y * depth + side.y * keyHalf))
        bore.close()
        outline.append(bore)
        outline.usesEvenOddFillRule = true
        outline.flatness = 0.004

        let shape = SCNShape(path: outline, extrusionDepth: thickness)
        shape.chamferRadius = 0.012

        // SCNShape materials: front, back, sides, chamfer
        // Black lacquer: no diffuse light at all, just a tight sheen where the key light glances off it
        let face = SCNMaterial()
        face.lightingModel = .blinn
        face.diffuse.contents = Dawn.rock
        // A broad golden sheen across the dark face, like low sun on wet rock
        face.specular.contents = Dawn.sun
        face.shininess = 18

        let flank = SCNMaterial()
        flank.lightingModel = .physicallyBased
        // Snow caught by alpenglow: gold-washed, and faintly glowing on its own
        flank.diffuse.contents = Dawn.snow.blended(with: Dawn.sunDeep, by: 0.22)
        flank.emission.contents = Dawn.sunDeep.blended(with: .black, by: 0.9)
        flank.metalness.contents = 0.0
        flank.roughness.contents = 0.45

        let edge = SCNMaterial()
        edge.lightingModel = .physicallyBased
        edge.diffuse.contents = Dawn.sunDeep.blended(with: Dawn.snow, by: 0.35)   // the rims catch the sun
        edge.emission.contents = Dawn.sunDeep.blended(with: .black, by: 0.75)
        edge.roughness.contents = 0.35

        shape.materials = [face, face, flank, edge]
        return SCNNode(geometry: shape)
    }

    // MARK: Worm

    /// Polished black steel: a core rod with thread crests, each tilted to the thread's lead so the stack reads as
    /// a helix. The crests run up the rod one pitch at a time and loop, so the thread looks endless.
    private static func wormNode() -> SCNNode {
        let steel = SCNMaterial()
        steel.lightingModel = .physicallyBased
        steel.diffuse.contents = UIColor(rgb: 0x15100D)
        steel.metalness.contents = 0.95
        steel.roughness.contents = 0.14

        let worm = SCNNode()
        let length: CGFloat = 5
        let core = SCNCylinder(radius: 0.21, height: length)
        core.materials = [steel]
        // Cylinders run along y; lay the worm along x (its axis)
        let coreNode = SCNNode(geometry: core)
        coreNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        worm.addChildNode(coreNode)

        let threads = SCNNode()
        let lead = atan(Float(pitch) / (2 * .pi * 0.3))
        let count = Int(length / pitch)
        // Each crest: a flat ring with rounded edges, so its rims catch sharp highlights like a cut thread
        let ring = UIBezierPath(arcCenter: .zero, radius: 0.4, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        ring.append(UIBezierPath(arcCenter: .zero, radius: 0.2, startAngle: 0, endAngle: 2 * .pi, clockwise: false))
        ring.usesEvenOddFillRule = true
        ring.flatness = 0.003
        // Fully rounded crests: the chamfer is half the rib's depth, so each one is a smooth bead of a ridge
        let crest = SCNShape(path: ring, extrusionDepth: 0.15)
        crest.chamferRadius = 0.075
        crest.chamferMode = .both
        crest.materials = [steel]
        for i in 0..<count {
            let node = SCNNode(geometry: crest)
            node.position = SCNVector3(Float(-length / 2) + Float(i) * Float(pitch), 0, 0)
            // The ring lies in xy facing z; turn it to face along the x axis, then lean it by the thread's lead
            node.eulerAngles = SCNVector3(0, Float.pi / 2, lead)
            threads.addChildNode(node)
        }
        worm.addChildNode(threads)

        // Threads advance one pitch per period, then jump back unseen (every crest is identical)
        let advance = SCNAction.moveBy(x: pitch, y: 0, z: 0, duration: threadPeriod)
        let reset = SCNAction.moveBy(x: -pitch, y: 0, z: 0, duration: 0)
        threads.runAction(.repeatForever(.sequence([advance, reset])))
        return worm
    }

    // MARK: Studio light

    /// A soft radial wash of honey-peach sunrise, fading to nothing
    private static func haloImage() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let glow = Dawn.sunDeep.blended(with: Dawn.skyLow, by: 0.5)
            let colours = [glow.withAlphaComponent(0.6).cgColor, glow.withAlphaComponent(0.22).cgColor, Dawn.skyLow.withAlphaComponent(0).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours, locations: [0, 0.4, 1])!
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.cgContext.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
        }
    }

    /// The dawn sky behind the widget: lavender above, warming to peach below
    private static func skyGradient() -> UIImage {
        let size = CGSize(width: 4, height: 256)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colours = [Dawn.skyTop.cgColor, Dawn.skyLow.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
    }

    /// What the polished parts reflect: dawn sky overhead, peach horizon, dark rock below, and the low sun
    private static func studioEnvironment() -> UIImage {
        let size = CGSize(width: 256, height: 128)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colours = [Dawn.skyTop.cgColor, Dawn.skyLow.cgColor, UIColor(rgb: 0x2A2220).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colours, locations: [0, 0.48, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            // The low sun, for golden glints along the threads
            Dawn.sun.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 40, y: 34, width: 60, height: 22))
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255, blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }

    func blended(with other: UIColor, by amount: CGFloat) -> UIColor {
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * amount, green: g1 + (g2 - g1) * amount, blue: b1 + (b2 - b1) * amount, alpha: a1 + (a2 - a1) * amount)
    }
}
