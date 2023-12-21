//
//  OpenAIServiceFactory+Mock.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/20/23.
//

import SwiftOpenAI

extension OpenAIServiceFactory {
   
   // TODO: Add a real mock service.
   static func mockService() -> OpenAIService {
      OpenAIServiceFactory.service(apiKey: "")
   }
}
