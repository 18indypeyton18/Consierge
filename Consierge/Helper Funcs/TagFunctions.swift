//
//  TagFunctions.swift
//  Consierge
//
//  Created by Austin McLaughlin on 11/30/24.
//

import Foundation

class TagFunctions {
    var addTagRequestTask: Task<Void,Never>? = nil
    var openAIRequestTask: Task<Void, Never>? = nil
    
    weak var delegate: AddTagDelegate?
    
    deinit {
        addTagRequestTask?.cancel()
        openAIRequestTask?.cancel()
    }
    
    func addTag(addTag: AddTag) {
        addTagRequestTask = Task {
            if let _ = try? await AddTagRequest(addTag: addTag).send() {
                moderateTag(addTag: addTag)
                delegate?.didAddTag()
            } else {
                // print("add tag err")
            }
            addTagRequestTask = nil
        }
    }
}

extension TagFunctions {
    
    func moderateTag(addTag: AddTag) {
        let tagName = addTag.tagName
        
        let systemPrompt = """
You are moderating user submitted content. The acceptable moderationResult values are "Approved", "Review", "Rejected"
        Provide the response in a JSON format. Don't provide any supporting text, only the JSON response. The response should start with the character "{" and end with the character "}". See the required format below.
--------------------------------------------------------------------------------------------------
        {"moderationResult": "Review"}
--------------------------------------------------------------------------------------------------

"""
        
        var gptPrompt = """
You are a content moderation assistant. A user has submitted a Tag:

'
"""
        gptPrompt += tagName
        
        gptPrompt += """
'

Evaluate this tag against the following rules:

1. **Length:** Must be 25 characters or less.  
2. **Profanity & Obscenity:** No swear words, crude language, or sexual explicitness.  
3. **Hate Speech & Slurs:** No insults or slurs targeting protected groups (race, religion, gender, sexuality, etc.).  
4. **Harassment & Threats:** No threats, intimidation, or personal attacks.  
5. **Violence & Self-harm:** No graphic violence or encouragement of self-harm.  
6. **Illegal Activity:** No admission or promotion of crimes.  
7. **Context & Tone:** Harmless jokes, puns or non-offensive slang should be **approved**, even if mildly cheeky.

**Output only one** of these values (no extra text):
- **Approved**  → meets all rules  
- **Review**    → borderline or ambiguous (human review needed)  
- **Rejected**  → clearly violates one or more rules

Respond with exactly:
        {"moderationResult": "Approved"/"Review"/"Rejected"}
"""
        
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: [gptPrompt], maxTokens: 500, temperature: 0.7, username: "system")
        
        Task {
            let response = try await request.send()
            if let text = response.choices.first?.message.content {
                self.parseGPTModerationResponse(text: text, addTag: addTag)
            } else {
                // print("GPT Moderation for AskAI Error")
            }
        }
    }
    
    func parseGPTModerationResponse(text: String, addTag: AddTag) {
        // Convert the string to a Data object
        guard let jsonData = text.data(using: .utf8) else {
            // print("Error: Cannot convert string to Data object")
            return
        }

        // Create an instance of JSONDecoder
        let decoder = JSONDecoder()

        // Attempt to decode the Data object into our Swift structs
        do {
            let response = try decoder.decode(GPTModerationResponse.self, from: jsonData)
            Task {
                let status = response.moderationResult
                let approveTag = ApproveTag(addTag: addTag, status: status)
                
                let _ = try? await ApproveTagRequest(approveTag: approveTag).send()
            }
        } catch {
            // print("GPTModerationResponse decode failed")
        }
    }
}
protocol AddTagDelegate: AnyObject {
    func didAddTag()
}

