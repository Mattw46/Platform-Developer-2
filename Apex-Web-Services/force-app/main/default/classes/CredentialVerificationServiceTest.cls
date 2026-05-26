@IsTest
private class CredentialVerificationServiceTest {
    private static final String RESPONSE_VALID = 'Valid';
    private static final String RESPONSE_NEEDS_RENEWAL = 'Needs Renewal';
    private static final String RESPONSE_NOT_FOUND = 'No record found.';

    @IsTest
    static void testReturnsValidForActiveCertification() {
        Contact contactRecord = createContact('Anderson');
        Certification__c certification = createCertification('Pilot License A', true);
        Contact_Certification__c link = createContactCertification(contactRecord.Id, certification.Id, true);

        Contact_Certification__c persistedLink = [SELECT Name FROM Contact_Certification__c WHERE Id = :link.Id LIMIT 1];

        Test.startTest();
        String response = CredentialVerificationService.verifyCredential(contactRecord.LastName, persistedLink.Name);
        Test.stopTest();

        System.assertEquals(RESPONSE_VALID, response, 'Active certification link should return Valid.');
    }

    @IsTest
    static void testReturnsNeedsRenewalForInactiveCertification() {
        Contact contactRecord = createContact('Brown');
        Certification__c certification = createCertification('Pilot License B', true);
        Contact_Certification__c link = createContactCertification(contactRecord.Id, certification.Id, false);

        Contact_Certification__c persistedLink = [SELECT Name FROM Contact_Certification__c WHERE Id = :link.Id LIMIT 1];

        Test.startTest();
        String response = CredentialVerificationService.verifyCredential(contactRecord.LastName, persistedLink.Name);
        Test.stopTest();

        System.assertEquals(RESPONSE_NEEDS_RENEWAL, response, 'Inactive certification link should return Needs Renewal.');
    }

    @IsTest
    static void testReturnsNoRecordFoundForInvalidInputs() {
        Test.startTest();
        String missingLastNameResponse = CredentialVerificationService.verifyCredential(null, 'CC-0001');
        String missingNameResponse = CredentialVerificationService.verifyCredential('AnyLastName', null);
        String noMatchResponse = CredentialVerificationService.verifyCredential('NoSuchContact', 'NO-SUCH-CERT');
        Test.stopTest();

        System.assertEquals(RESPONSE_NOT_FOUND, missingLastNameResponse, 'Missing contact last name should return No record found.');
        System.assertEquals(RESPONSE_NOT_FOUND, missingNameResponse, 'Missing contact certification name should return No record found.');
        System.assertEquals(RESPONSE_NOT_FOUND, noMatchResponse, 'Non-existent records should return No record found.');
    }

    @IsTest
    static void testReturnsNoRecordFoundWhenCertificationBelongsToDifferentContact() {
        Contact firstContact = createContact('Garcia');
        Contact secondContact = createContact('Miller');
        Certification__c certification = createCertification('Pilot License C', true);
        Contact_Certification__c link = createContactCertification(firstContact.Id, certification.Id, true);

        Contact_Certification__c persistedLink = [SELECT Name FROM Contact_Certification__c WHERE Id = :link.Id LIMIT 1];

        Test.startTest();
        String response = CredentialVerificationService.verifyCredential(secondContact.LastName, persistedLink.Name);
        Test.stopTest();

        System.assertEquals(RESPONSE_NOT_FOUND, response, 'Service should require both last name and certification name to match the same link record.');
    }

    private static Contact createContact(String lastName) {
        Account accountRecord = new Account(Name = 'Credential Account ' + lastName + DateTime.now().getTime());
        insert accountRecord;

        Contact contactRecord = new Contact(
            LastName = lastName,
            AccountId = accountRecord.Id
        );
        insert contactRecord;
        return contactRecord;
    }

    private static Certification__c createCertification(String nameValue, Boolean isActive) {
        Certification__c certification = new Certification__c(
            Name = nameValue,
            isActive__c = isActive
        );
        insert certification;
        return certification;
    }

    private static Contact_Certification__c createContactCertification(Id contactId, Id certificationId, Boolean isActive) {
        Contact_Certification__c link = new Contact_Certification__c(
            Contact__c = contactId,
            Certification__c = certificationId,
            Issue_Date__c = Date.today(),
            isActive__c = isActive
        );
        insert link;
        return link;
    }
}