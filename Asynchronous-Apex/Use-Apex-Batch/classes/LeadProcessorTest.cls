@isTest
private class LeadProcessorTest {

    @isTest static void testLeadProcessorBatch() {
        // Step 1: Create 200 Lead records for testing
        List<Lead> leadList = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            Lead newLead = new Lead(LastName = 'Test Lead ' + i, Company = 'Test Company ' + i);
            leadList.add(newLead);
        }
        insert leadList; // Insert 200 leads

        // Step 2: Execute the batch job
        Test.startTest();
        LeadProcessor batch = new LeadProcessor();
        Database.executeBatch(batch, 200); // Passing batch size as 200 to process the leads in one go
        Test.stopTest();

        // Step 3: Verify that the LeadSource has been updated to "Dreamforce"
        List<Lead> updatedLeads = [SELECT Id, LeadSource FROM Lead WHERE Id IN :leadList];
        for (Lead updatedLead : updatedLeads) {
            System.assertEquals('Dreamforce', updatedLead.LeadSource, 'LeadSource should be updated to Dreamforce');
        }
    }
}
