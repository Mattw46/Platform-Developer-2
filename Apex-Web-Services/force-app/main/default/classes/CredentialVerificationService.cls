/**
 * SOAP service for validating a drone operator credential.
 */
global with sharing class CredentialVerificationService {
    private static final String RESPONSE_VALID = 'Valid';
    private static final String RESPONSE_NEEDS_RENEWAL = 'Needs Renewal';
    private static final String RESPONSE_NOT_FOUND = 'No record found.';

    /**
     * Verifies a contact certification based on contact last name and certification record name.
     * @param contactLastName Contact.LastName value.
     * @param contactCertificationName Contact_Certification__c.Name value.
     * @return Valid, Needs Renewal, or No record found.
     */
    webservice static String verifyCredential(String contactLastName, String contactCertificationName) {
        if (String.isBlank(contactLastName) || String.isBlank(contactCertificationName)) {
            return RESPONSE_NOT_FOUND;
        }

        if (
            !Schema.sObjectType.Contact_Certification__c.isAccessible() ||
            !Schema.sObjectType.Contact_Certification__c.fields.Name.isAccessible() ||
            !Schema.sObjectType.Contact_Certification__c.fields.isActive__c.isAccessible() ||
            !Schema.sObjectType.Contact_Certification__c.fields.Contact__c.isAccessible() ||
            !Schema.sObjectType.Contact.fields.LastName.isAccessible()
        ) {
            return RESPONSE_NOT_FOUND;
        }

        List<Contact_Certification__c> certificationLinks = [
            SELECT Id, isActive__c
            FROM Contact_Certification__c
            WHERE Name = :contactCertificationName
            AND Contact__r.LastName = :contactLastName
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (certificationLinks.isEmpty()) {
            return RESPONSE_NOT_FOUND;
        }

        return certificationLinks[0].isActive__c ? RESPONSE_VALID : RESPONSE_NEEDS_RENEWAL;
    }
}