//
//  ViewController.swift
//  ARPractice
//
//  Created by CEDAM21 on 10/04/24.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var arView: ARView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        arView.session.delegate = self
        
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    @objc
    func handleTap(recognizer: UITapGestureRecognizer){
        let tapLocation = recognizer.location(in: arView)
        
        let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = result.first {
            let worldPos = simd_make_float3(firstResult.worldTransform.columns.3)
            
            let box = createBox()
            placeObject(object: box, location: worldPos)
        }
    }
    
    func createBox() -> ModelEntity{
//        1. Crear un modelo
        let box = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        
//        2. Agregar material al modelo
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        let mass: Float = 1.0
    
        let entity = ModelEntity(mesh: box, materials: [material])
        
        entity.physicsBody = .init(massProperties: .init(mass: mass), material: nil, mode: .dynamic)
        entity.physicsMotion = .init()
        
        let collisionShape = ShapeResource.generateBox(size: SIMD3(x: 0.1, y: 0.1, z: 0.1))
        entity.collision = .init(shapes: [collisionShape], mode: .default, filter: .default)
        
        return entity
    }
    
    func placeObject(object: ModelEntity, location: SIMD3<Float>){
        var newLocation = location
        newLocation.y += 0.5
        
        let anchor = AnchorEntity(world: newLocation)
        
        anchor.addChild(object)
        arView.scene.addAnchor(anchor)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
//                Entidad
                let extent = planeAnchor.extent
                let planeMesh = MeshResource.generatePlane(width: extent.x, depth: extent.z)
                let material = SimpleMaterial(color: .clear, isMetallic: false)
                
                let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
                
                let physicBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
                planeEntity.components.set(physicBody)
                
                let collisionShape = ShapeResource.generateBox(width: extent.x, height: 0.01, depth: extent.z)
                planeEntity.collision = .init(shapes: [collisionShape], mode: .default, filter: .default)
                
                let anchorEntity = AnchorEntity(anchor: planeAnchor)
                
                anchorEntity.addChild(planeEntity)
                arView.scene.addAnchor(anchorEntity)
            }
        }
    }

}

