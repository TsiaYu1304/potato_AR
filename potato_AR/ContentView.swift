//
//  ContentView.swift
//  potato_AR
//
//  Created by 蔡瑀 on 2022/6/12.
//

import SwiftUI
import RealityKit
import ARKit

// 5. Create BodySkeleton entity to visualize and update joint pose
//關節處可視化
class BodySkeleton :Entity{
    var joints:[String:Entity]=[:]//jointNames mapped to jointEntities
    
    required init(for bodyAnchor : ARBodyAnchor) {
        super.init()
        //6. Create entity for each joint in skeleton
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames{
            //Default values for joint appearance
            var jointRadius:Float=0.03
            var jointColor:UIColor = .green
            
            
            //Create an entity for the joint,add joints dictionary,and add it to the parent entity(i.e. bodySkeleton)
            let jointEntity = makeJoint(radius:jointRadius,color:jointColor)
            joints[jointName]=jointEntity
            self.addChild(jointEntity)
        }
        
        self.update(with: bodyAnchor)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    // 7. Create helper method to create a sphere-shaped entity with specified radius and color for a joint
    //新增綠色圓球
       func makeJoint(radius:Float,color:UIColor)->Entity{
           let mesh = MeshResource.generateSphere(radius: radius)
           let material = SimpleMaterial(color:color,roughness: 0.8,isMetallic: false)
           let modelEntity = ModelEntity(mesh:mesh,materials: [material])
           
           return modelEntity
       }
    // 8. Create method to update the position and orientation of each jointEntity
    // 更新球體的位置
       func update(with bodyAnchor:ARBodyAnchor){
           //獲得根關節的位置
           let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
           
           //依照根關節去設定每個關節的位置
           for jointName in ARSkeletonDefinition.defaultBody3D.jointNames{
               if let jointEntity = joints[jointName],let jointTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)){
                   
                   let jointOffset = simd_make_float3(jointTransform.columns.3)
                   jointEntity.position = rootPosition + jointOffset
                   jointEntity.orientation = Transform(matrix: jointTransform).rotation
               }
           }
       }
}

// 9. Create global variables for BodySkeleton
var bodySkeleton:BodySkeleton?
var bodySkeletonAnchor = AnchorEntity()

//3. Create ARViewContainer
struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        arView.setupForBodyTracking()
        
        //10. add bodySkeletonAnchor to scene
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}


//4. Extend ARView to implement body tracking functionality
extension ARView:ARSessionDelegate{
    //4a. Configure ARView for body tracking
    func setupForBodyTracking(){
            let config = ARBodyTrackingConfiguration()
            self.session.run(config)
            
            self.session.delegate = self
        }
    //4b. Implement ARSession didUpdate anchors delegate method
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]){
        for anchor in anchors{
            if let bodyAnchor = anchor as? ARBodyAnchor{
              //  print("Updated bodyAnchor.")
              //  let skeleton = bodyAnchor.skeleton
                
              //  //取得根關節的xyz座標
              //  let rootJointTransform = skeleton.modelTransform(for: .root)!
              //  let rootJointPosition = simd_make_float3(rootJointTransform.columns.3)
              //  print("root:\(rootJointPosition)")
                
              //  //取得左手關節的xyz座標
              //  let leftHandTransform = skeleton.modelTransform(for: .leftHand)!
              //  let leftHandOffset = simd_make_float3(leftHandTransform.columns.3)
              //  let leftHandPostion = rootJointPosition + leftHandOffset
              //  print("leftHand:\(leftHandPostion)")
            
                //11. Create or Update bodySkeleton
                if let skeleton = bodySkeleton{
                    // BodySkeleton already exists,update pose of all joints
                    skeleton.update(with: bodyAnchor)
                }
                else{
                    //seeing body for the first time,create bodySkeleton
                    let skeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeleton = skeleton
                    bodySkeletonAnchor.addChild(skeleton)
                }
                
            }
        }
    }
   
}

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
