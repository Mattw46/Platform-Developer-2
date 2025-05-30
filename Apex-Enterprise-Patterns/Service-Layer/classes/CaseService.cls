public with sharing class CaseService {
    
    public static void closeCases(Set<Id> caseIds, String reason) {
        List<Case> caseList = [SELECT Id, Status, Reason 
                            FROM Case
                            WHERE Id IN: caseIds];
        for (Case currentCase : caseList) {
            currentCase.Status = 'Closed';
            currentCase.Reason = reason;
        }
        update caseList;
    }
}