@RestResource(urlMapping='/lost/*')
/**
 * REST service for reporting lost assets and filing insurance claims.
 */
global with sharing class AssetService {
    private static final String NO_DEVICE_FOUND_MESSAGE = 'No device found.';
    private static final String NO_COVERAGE_MESSAGE = 'No coverage. Asset status adjusted to Lost.';
    private static final String LOSS_TYPE = 'Loss';
    private static final String CLAIM_STATUS_NEW = 'New';
    private static final String COVERAGE_COMPREHENSIVE = 'Comprehensive';

    private class LostDeviceRequest {
        public String assetIdentifier;
    }

    @HttpPost
    /**
     * Parses the request body and forwards the asset identifier to the business method.
     * @return Claim number or a guidance message.
     */
    global static String reportLostDevice() {
        String assetIdentifier;
        RestRequest request = RestContext.request;
        if (request != null && request.requestBody != null) {
            String body = request.requestBody.toString();
            if (!String.isBlank(body)) {
                LostDeviceRequest payload = (LostDeviceRequest) JSON.deserialize(body, LostDeviceRequest.class);
                assetIdentifier = payload == null ? null : payload.assetIdentifier;
            }
        }
        return reportLostDevice(assetIdentifier);
    }

    /**
     * Reports a lost asset and optionally files a loss claim.
     * @param assetIdentifier The external asset identifier from the client request.
     * @return Claim number, duplicate-claim message, no-coverage message, or no-device message.
     */
    global static String reportLostDevice(String assetIdentifier) {
        if (String.isBlank(assetIdentifier)) {
            return NO_DEVICE_FOUND_MESSAGE;
        }

        List<Asset> assets = [
            SELECT Id, Status
            FROM Asset
            WHERE Asset_Identifier__c = :assetIdentifier
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (assets.isEmpty()) {
            return NO_DEVICE_FOUND_MESSAGE;
        }

        Asset assetRecord = assets[0];

        List<Claim__c> existingClaims = [
            SELECT Id, Name
            FROM Claim__c
            WHERE Asset__c = :assetRecord.Id
            AND Type__c = :LOSS_TYPE
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!existingClaims.isEmpty()) {
            return existingClaims[0].Name + ' already filed.';
        }

        List<Insurance__c> insurancePolicies = [
            SELECT Id
            FROM Insurance__c
            WHERE Asset__c = :assetRecord.Id
            AND Active__c = true
            AND Coverage__c = :COVERAGE_COMPREHENSIVE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (!Schema.sObjectType.Asset.isUpdateable() || !Schema.sObjectType.Asset.fields.Status.isUpdateable()) {
            return NO_DEVICE_FOUND_MESSAGE;
        }
        assetRecord.Status = 'Lost';
        update assetRecord;

        if (insurancePolicies.isEmpty()) {
            return NO_COVERAGE_MESSAGE;
        }

        if (
            !Schema.sObjectType.Claim__c.isCreateable() ||
            !Schema.sObjectType.Claim__c.fields.Asset__c.isCreateable() ||
            !Schema.sObjectType.Claim__c.fields.Insurance__c.isCreateable() ||
            !Schema.sObjectType.Claim__c.fields.Type__c.isCreateable() ||
            !Schema.sObjectType.Claim__c.fields.Status__c.isCreateable()
        ) {
            return NO_COVERAGE_MESSAGE;
        }

        Claim__c newClaim = new Claim__c(
            Asset__c = assetRecord.Id,
            Insurance__c = insurancePolicies[0].Id,
            Type__c = LOSS_TYPE,
            Status__c = CLAIM_STATUS_NEW
        );
        insert newClaim;

        Claim__c insertedClaim = [SELECT Name FROM Claim__c WHERE Id = :newClaim.Id LIMIT 1];
        return insertedClaim.Name;
    }
}