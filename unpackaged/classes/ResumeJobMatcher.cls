public class ResumeJobMatcher {
    
    public class MatchingResult {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public Integer matchScore {get; set;}
        @AuraEnabled public List<String> keySkillsMatched {get; set;}
        @AuraEnabled public List<String> keySkillsMissing {get; set;}
        @AuraEnabled public String summary {get; set;}
        @AuraEnabled public String error {get; set;}
        @AuraEnabled public String apiResponse {get; set;}
        
        public MatchingResult() {
            this.success = false;
            this.matchScore = 0;
            this.keySkillsMatched = new List<String>();
            this.keySkillsMissing = new List<String>();
            this.summary = 'Analysis failed';
            this.error = null;
        }
    }
    
    @Future(callout=true)
    public static void analyzeResumeAgainstJobAsync(Id contactId, Id jobRequisitionId, Id applicationId) {
        MatchingResult aiResult = analyzeResumeAgainstJob(contactId, jobRequisitionId);
        updateJobApplicationWithResults(aiResult, applicationId);
        
    }
    
    public static MatchingResult analyzeResumeAgainstJob(Id contactId, Id jobRequisitionId) {
        MatchingResult result = new MatchingResult();
        
        try {
            // Get job description and resume data
            Contact con = [SELECT Description FROM Contact WHERE Id = :contactId LIMIT 1];
            Job_Requisition__c JD = [SELECT Description__c FROM Job_Requisition__c WHERE Id = :jobRequisitionId LIMIT 1];
            
            String jdText = String.isNotBlank(JD.Description__c) ? JD.Description__c : 'No job description provided';
            String resumeText = String.isNotBlank(con.Description) ? con.Description : 'No resume provided';
            
            // Truncate very long texts to avoid token limits
            Integer maxLength = 10000; // Adjust based on your needs
            if (jdText.length() > maxLength) {
                jdText = jdText.substring(0, maxLength) + '... [truncated]';
            }
            if (resumeText.length() > maxLength) {
                resumeText = resumeText.substring(0, maxLength) + '... [truncated]';
            }
            
            // Build a more concise prompt
            String prompt = 
                'Analyze resume against job description. Return ONLY JSON with this exact structure:\n' +
                '{\n' +
                '  "matchScore": number (0-100),\n' +
                '  "keySkillsMatched": ["skill1", "skill2"],\n' +
                '  "keySkillsMissing": ["skillA", "skillB"],\n' +
                '  "summary": "2-3 sentence summary"\n' +
                '}\n\n' +
                'JOB DESCRIPTION:\n' + jdText + '\n\n' +
                'RESUME:\n' + resumeText;
            
            // Azure OpenAI API call
            HttpRequest req = new HttpRequest();
            String endpoint = 'https://hrish-m3zpdd19-eastus2.cognitiveservices.azure.com/' +
                            'openai/deployments/hackathon-group5/chat/completions?api-version=2024-02-01';
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('api-key', '5bKI58jSZBaHLSWY5DS6fwyIqlEPtTIKqHi9tPdoUZOULfUqr7LmJQQJ99AKACHYHv6XJ3w3AAAAACOGyFpk');
            req.setTimeout(60000);
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'model' => 'gpt-5-mini',
                'messages' => new List<Map<String, String>>{
                    new Map<String, String>{
                        'role' => 'system',
                        'content' => 'You are a skills matching analyzer. Output ONLY valid JSON without any additional text, explanations, or markdown formatting. Strictly follow the specified schema.'
                    },
                    new Map<String, String>{
                        'role' => 'user',
                        'content' => prompt
                    }
                },
                'max_completion_tokens' => 2000
            };
            
            req.setBody(JSON.serialize(requestBody));
            System.debug('Request Body: ' + JSON.serializePretty(requestBody));
            
            // Execute the call
            Http http = new Http();
            HttpResponse res;
            try {
                res = http.send(req);
            } catch (Exception e) {
                System.debug('HTTP call failed: ' + e.getMessage());
                result.error = 'HTTP call failed: ' + e.getMessage();
                return result;
            }
            
            System.debug('Response Code: ' + res.getStatusCode());
            System.debug('Raw Response: ' + res.getBody());
            
            result.apiResponse = res.getBody();
            
            if (res.getStatusCode() == 200 && String.isNotBlank(res.getBody())) {
                try {
                    Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    List<Object> choices = (List<Object>)responseMap.get('choices');
                    
                    if (choices != null && !choices.isEmpty()) {
                        Map<String, Object> firstChoice = (Map<String, Object>)choices[0];
                        Map<String, Object> message = (Map<String, Object>)firstChoice.get('message');
                        String content = (String)message.get('content');
                        String finishReason = (String)firstChoice.get('finish_reason');
                        
                        System.debug('Finish Reason: ' + finishReason);
                        System.debug('Raw Content: ' + content);
                        
                        if (String.isNotBlank(content)) {
                            content = content.trim();
                            
                            // Handle markdown code blocks
                            if (content.startsWith('```json')) {
                                content = content.substring(6).trim();
                            }
                            if (content.endsWith('```')) {
                                content = content.substring(0, content.length() - 3).trim();
                            }
                            
                            if (content.startsWith('{') && content.endsWith('}')) {
                                try {
                                    Map<String, Object> aiResponse = (Map<String, Object>)JSON.deserializeUntyped(content);
                                    
                                    result.success = true;
                                    
                                    // Extract match score
                                    Object scoreObj = aiResponse.get('matchScore');
                                    if (scoreObj != null) {
                                        result.matchScore = Integer.valueOf(scoreObj);
                                    }
                                    
                                    // Extract matched skills
                                    Object matchedObj = aiResponse.get('keySkillsMatched');
                                    if (matchedObj instanceof List<Object>) {
                                        for (Object skill : (List<Object>)matchedObj) {
                                            result.keySkillsMatched.add(String.valueOf(skill));
                                        }
                                    }
                                    
                                    // Extract missing skills
                                    Object missingObj = aiResponse.get('keySkillsMissing');
                                    if (missingObj instanceof List<Object>) {
                                        for (Object skill : (List<Object>)missingObj) {
                                            result.keySkillsMissing.add(String.valueOf(skill));
                                        }
                                    }
                                    
                                    // Extract summary
                                    Object summaryObj = aiResponse.get('summary');
                                    if (summaryObj != null) {
                                        result.summary = String.valueOf(summaryObj);
                                    }
                                    
                                } catch (Exception e) {
                                    result.error = 'JSON parsing error: ' + e.getMessage();
                                    System.debug('JSON parsing error: ' + e.getMessage());
                                }
                            } else {
                                result.error = 'Invalid JSON format in response';
                                System.debug('Invalid JSON response: ' + content);
                            }
                        } else if (finishReason == 'length') {
                            result.error = 'Response truncated - increase max_completion_tokens or reduce input size';
                            System.debug('Response was truncated due to token limit');
                        } else {
                            result.error = 'Empty content in response. Finish reason: ' + finishReason;
                            System.debug('Empty content with finish reason: ' + finishReason);
                        }
                    }
                } catch (Exception e) {
                    result.error = 'Response processing error: ' + e.getMessage();
                    System.debug('Response processing error: ' + e.getMessage());
                }
            } else {
                result.error = 'API call failed. Code: ' + res.getStatusCode() + ', Body: ' + res.getBody();
                System.debug('API call failed with status: ' + res.getStatusCode());
            }
            
        } catch (Exception e) {
            result.error = 'Initialization error: ' + e.getMessage();
            System.debug('Initialization error: ' + e.getMessage());
        }
        
        // Output the final result
        System.debug('Final Result: ' + JSON.serializePretty(result));
        
        // Display results
        if (result.success == true) {
            System.debug('=== SKILL MATCHING RESULTS ===');
            System.debug('Match Score: ' + result.matchScore + '/100');
            System.debug('Skills Matched: ' + result.keySkillsMatched);
            System.debug('Skills Missing: ' + result.keySkillsMissing);
            System.debug('Summary: ' + result.summary);
        } else {
            System.debug('=== ERROR ===');
            System.debug('Error: ' + result.error);
        }
        
        return result;
    }
    
    // Helper method to update a Job Application record with the results
    public static void updateJobApplicationWithResults(MatchingResult result, Id applicationId) {
        try {
            Application__c jobApp = new Application__c(
                Id = applicationId,
                AI_Match_Score__c = result.matchScore,
                AI_Skills_Matched__c = String.join(result.keySkillsMatched, ';'),
                AI_Skills_Missing__c = String.join(result.keySkillsMissing, ';'),
                AI_Summary__c = result.summary,
                Status__c = result.success ? 'AI Screening Completed' : 'AI Screening Failed'
                //Error_Message__c = result.error
            );
            
            update jobApp;
            System.debug('Job Application updated successfully: ' + jobApp.Id);
            
        } catch (Exception e) {
            System.debug('Error creating Job Application: ' + e.getMessage());
        }
    }
}