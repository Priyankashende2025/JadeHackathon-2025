trigger ApplicationTrigger on Application__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        for (Application__c jobApp : trigger.new) {
            if (jobApp.Candidate__c!= null && jobApp.Job_Requisition__c != null) {
                ResumeJobMatcher.analyzeResumeAgainstJobAsync(jobApp.Candidate__c, jobApp.Job_Requisition__c, jobApp.Id);
            }
        }
        //AIApplicationHandler.analyzeApplications(Trigger.new);
    }
}