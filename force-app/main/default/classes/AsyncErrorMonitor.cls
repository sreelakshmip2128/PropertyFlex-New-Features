public class AsyncErrorMonitor implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        processAsyncErrors();
    }

    public static void processAsyncErrors() {
        List<Exception_Log__c> newLogs = new List<Exception_Log__c>();
        
        Set<String> existingJobIds = new Set<String>();
        //for (Exception_Log__c log : [SELECT Async_Job_ID__c FROM Exception_Log__c WHERE CreatedDate = LAST_N_DAYS:1 AND Async_Job_ID__c != null]) {
        for (Exception_Log__c log : [SELECT Async_Job_ID__c FROM Exception_Log__c WHERE Async_Job_ID__c != null]) {
            existingJobIds.add(log.Async_Job_ID__c);
        }
        
        // Querying for failed or aborted jobs
        // We include ApexClass.Name to use as our Source
        List<AsyncApexJob> failedJobs = [
            SELECT Id, JobType, Status, ExtendedStatus, ApexClass.Name, CompletedDate , CreatedDate,  CreatedById
            FROM AsyncApexJob 
            WHERE Status IN ('Failed', 'Aborted','Completed') 
            //AND CompletedDate = LAST_N_DAYS:1
            AND Id NOT IN :existingJobIds
        ];

        for (AsyncApexJob job : failedJobs) {
           Exception_Log__c log = new Exception_Log__c();
            
            // Title: JobType + ' Error' (e.g., "BatchApex Error")
           // log.Name = job.JobType + ' Method Failure';
            
            // Source: The actual Class Name
            log.Source__c = job.ApexClass.Name != null ? job.ApexClass.Name : 'Unknown Apex Class';
            
            // Message: The ExtendedStatus from the system
            log.Exception_Message__c = job.ExtendedStatus;
            
            // Metadata for tracking
            log.Async_Job_ID__c = job.Id;
            log.Occurred_On__c = job.CreatedDate;
            log.Exception_Type__c = job.JobType + ' Method Failure';
            log.Triggered_By_User__c = job.CreatedById;
            
            newLogs.add(log);
        }

        if (!newLogs.isEmpty()) {
            // Using upsert with the Unique External ID to prevent duplicates
            upsert newLogs Async_Job_ID__c;
        }
    }
}