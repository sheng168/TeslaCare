//
//  AI.swift
//  TeslaCare
//
//  Created by Jin on 6/9/26.
//

import FoundationModels
import Playgrounds
import UIKit

@available(iOS 27, *)
class AI {
    /*
    func getRecommendation() async throws -> Bool {
        let session = LanguageModelSession(
            model: SystemLanguageModel()
        )
        
        guard let inputImage = UIImage(named: "your_image_name") else { return }

        // Create a multimodal prompt with the image and text instructions
//        let prompt: [PromptComponent] = [
//            .text("Describe what is happening in this image and list any potential hazards."),
//            .image(inputImage)
//        ]
//        SystemLanguageModel().contextSize
        
//    SystemLanguageModel.default.availability
    
//        session.usage.totalTokenCount
        
        let r = session.isResponding
        let response = try await session.respond(to: "Hello, world!", generating: IsTire.self)

        return response.content.tire!
    }
    
    func t() async throws {
        let session = LanguageModelSession(
            model: SystemLanguageModel()
        )

        let response = try await session.respond {
            "What part of car is this?"
            Attachment(UIImage())
        }
        
        let imageAttachment = ImageAttachment(image)
            
        let prompt = "What part of car is this?"
        
            // Pass the attachment and text to the model
            let response = try await session.respond(to: [
                imageAttachment
                
            ], generating: IsTire.self)
        
        session.respond(to: [
            "What part of car is this?",
            Attachment(UIImage())
        ], generating: IsTire.self)
    }
    */
    @Generable
    struct IsTire {
        var tire: Bool?
    }
}

#Playground {
    
    let session = LanguageModelSession()
    let response = try await session.respond(
        to: "Hello, world!")
}
