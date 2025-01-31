public class LeadProcessor implements Database.Batchable<sObject> {
    public Database.QueryLocator Start(Database.BatchableContext bc) {
        // get all Leads
        return Database.getQueryLocator('SELECT Id, LeadSource FROM Lead');
    }
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // update LeadSource to Dreamforce
        for (Lead lead : scope) {
            lead.LeadSource = 'Dreamforce';
        }
        update scope;
    }
    public void finish(Database.BatchableContext bc) {

    }
}