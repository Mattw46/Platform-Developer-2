public with sharing class AccountListControllerLwc {
    @AuraEnabled(cacheable=true)
    public static List<Account> queryAccountsByEmployeeNumber(Integer numberOfEmployees) {
        System.debug('>>> called with: ' + numberOfEmployees);
        return [
            SELECT Name
            FROM Account
            WHERE NumberOfEmployees >= :numberOfEmployees
        ];
    }
}