// AIApplicationHandler.cls
public with sharing class AIApplicationHandler {
    
    public static void analyzeApplications(List<Application__c> newApplications) {
        List<Id> contactIds = new List<Id>();
        List<Id> jobReqIds = new List<Id>();
        Map<Id, Application__c> applicationMap = new Map<Id, Application__c>();
        
        for (Application__c app : newApplications) {
            if (app.Candidate__c!= null && app.Job_Requisition__c != null) {
                contactIds.add(app.Candidate__c);
                jobReqIds.add(app.Job_Requisition__c);
                applicationMap.put(app.Id, app);
            }
        }
        
        if (!contactIds.isEmpty() && !jobReqIds.isEmpty()) {
            analyzeApplicationsAsync(contactIds, jobReqIds, applicationMap.keySet());
        }
    }
    
    @Future(callout=true)
    public static void analyzeApplicationsAsync(List<Id> contactIds, List<Id> jobReqIds, Set<Id> applicationIds) {
        // Get contacts with resume data
        Map<Id, Contact> contacts = new Map<Id, Contact>();
       /* [
            SELECT Id, Name, Description, 
                   (SELECT Id, Title, ContentDocumentId FROM ContentDocumentLinks 
                    WHERE ContentDocument.Title LIKE '%resume%' OR ContentDocument.Title LIKE '%cv%' 
                    LIMIT 1)
            FROM Contact 
            WHERE Id IN :contactIds
        ]*/
        
        // Get job requisitions
        Map<Id, Job_Requisition__c> jobReqs = new Map<Id, Job_Requisition__c>([
            SELECT Id, Name, Description__c
            FROM Job_Requisition__c 
            WHERE Id IN :jobReqIds
        ]);
        
        // Get applications
        Map<Id, Application__c> applications = new Map<Id, Application__c>([
            SELECT Id, Candidate__c, Job_Requisition__c, Status__c, 
                   AI_Match_Score__c
            FROM Application__c 
            WHERE Id IN :applicationIds
        ]);
        
        for (Application__c app : applications.values()) {
            Contact candidate = contacts.get(app.Candidate__c);
            Job_Requisition__c jobReq = jobReqs.get(app.Job_Requisition__c);
            
            if (candidate != null && jobReq != null) {
                String resumeText = extractResumeText(candidate);
                //AIResumeAnalyzer.AnalysisResult result = AIResumeAnalyzer.analyzeResume(resumeText, jobReq.Description__c);
                
                /*if (result.success) {
                    updateApplicationWithAnalysis(app.Id, result);
                }*/
            }
        }
    }
    
    private static String extractResumeText(Contact candidate) {
        String resumeText = '';
        
        // First try to use Contact description field
        if (String.isNotBlank(candidate.Description)) {
            resumeText = candidate.Description;
        }
        
        // If no description, try to read from attached resume file
        else if (!candidate.ContentDocumentLinks.isEmpty()) {
            ContentDocumentLink docLink = candidate.ContentDocumentLinks[0];
            resumeText = readContentDocumentText(docLink.ContentDocumentId);
        }
        
        return resumeText;
    }
    
    private static String readContentDocumentText(Id contentDocumentId) {
        try {
            ContentVersion contentVersion = [
                SELECT VersionData, FileExtension 
                FROM ContentVersion 
                WHERE ContentDocumentId = :contentDocumentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            if (contentVersion.FileExtension == 'pdf') {
                // For PDF files, you might need a PDF parser service
                return 'PDF resume content extraction would require additional service';
            } else if (contentVersion.FileExtension == 'doc' || contentVersion.FileExtension == 'docx') {
                // For Word documents, similar parsing needed
                return 'Word document content extraction would require additional service';
            } else if (contentVersion.FileExtension == 'txt') {
                return contentVersion.VersionData.toString();
            }
        } catch (Exception e) {
            System.debug('Error reading content document: ' + e.getMessage());
        }
        
        return 'Resume content not extractable';
    }
    
    /*private static void updateApplicationWithAnalysis(Id applicationId, AIResumeAnalyzer.AnalysisResult result) {
        //Application__c appToUpdate = new Application__c(Id = applicationId,AI_Match_Score__c = result.matchScore,AI Summary = result.summary);
        update appToUpdate;
    }*/
}