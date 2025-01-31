@isTest
private class DailyLeadProcessorTest {

    @isTest static void testDailyLeadProcessor() {
        // Step 1: Create 200 Lead records with LeadSource = null
        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leadList.add(new Lead(FirstName = 'Test', LastName = 'Lead ' + i, Company = 'Test Company', LeadSource = null));
        }
        insert leadList; // Insert 200 leads with null LeadSource

        // Step 2: Schedule the DailyLeadProcessor job
        String cronExpression = '0 0 0 1 1 ? *'; // This cron expression runs the job once at midnight on the 1st day of every month.
        DailyLeadProcessor leadProcessor = new DailyLeadProcessor();
        
        Test.startTest();
        String jobId = System.schedule('Test DailyLeadProcessor Job', cronExpression, leadProcessor);
        Test.stopTest();

        // Step 3: Verify that the LeadSource has been updated to 'Dreamforce'
        List<Lead> updatedLeads = [SELECT LeadSource FROM Lead WHERE Id IN :leadList];
        for (Lead updatedLead : updatedLeads) {
            System.assertEquals('Dreamforce', updatedLead.LeadSource, 'LeadSource should be updated to Dreamforce');
        }
    }
}
