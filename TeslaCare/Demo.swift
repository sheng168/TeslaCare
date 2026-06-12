//
//  Demo.swift
//  TeslaCare
//
//  Created by Jin on 6/8/26.
//

import Foundation
import FoundationModels

import Playgrounds

#Playground {
//    if #available(iOS 27.0, *) {
        let session = LanguageModelSession(
            model: SystemLanguageModel()
        )
        
        SystemLanguageModel().contextSize
        
    SystemLanguageModel.default.availability
    
//        session.usage.totalTokenCount
        
        let r = session.isResponding
        let response = try await session.respond(to: "Hello, world!")
//        
//        let cnt = response.content
//    } else {
//        // Fallback on earlier versions
//        let pi = 3.14
//    }
    
}
