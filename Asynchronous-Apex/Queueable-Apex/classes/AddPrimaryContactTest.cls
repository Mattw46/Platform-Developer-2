@isTest
private class AddPrimaryContactTest {

    @isTest static void testAddPrimaryContact() {
        // Step 1: Create 50 Account records for BillingState = 'NY'
        List<Account> nyAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            nyAccounts.add(new Account(Name = 'Account NY ' + i, BillingState = 'NY'));
        }
        insert nyAccounts;

        // Step 2: Create 50 Account records for BillingState = 'CA'
        List<Account> caAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            caAccounts.add(new Account(Name = 'Account CA ' + i, BillingState = 'CA'));
        }
        insert caAccounts;

        // Step 3: Create a Contact that we will clone for each Account
        Contact primaryContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        
        // Step 4: Execute the Queueable job for 'CA' state
        Test.startTest();
        AddPrimaryContact addPrimaryContactCA = new AddPrimaryContact(primaryContact, 'CA');
        System.enqueueJob(addPrimaryContactCA);
        Test.stopTest();

        // Step 5: Verify that Contacts were created for Accounts with BillingState 'CA'
        List<Contact> caContacts = [SELECT AccountId FROM Contact WHERE AccountId IN :caAccounts];
        System.assertEquals(50, caContacts.size(), 'There should be 50 contacts for accounts with BillingState CA');
    }
}
