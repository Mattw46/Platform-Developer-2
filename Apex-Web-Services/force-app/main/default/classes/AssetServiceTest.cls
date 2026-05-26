@IsTest
private class AssetServiceTest {
    private static final String NO_DEVICE_FOUND_MESSAGE = 'No device found.';
    private static final String NO_COVERAGE_MESSAGE = 'No coverage. Asset status adjusted to Lost.';

    @IsTest
    static void testMissingAssetIdentifierInRequestBody() {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/lost';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String missingIdentifierResponse = AssetService.reportLostDevice();
        Test.stopTest();

        System.assertEquals(NO_DEVICE_FOUND_MESSAGE, missingIdentifierResponse, 'Missing assetIdentifier in body should return no-device message.');
    }

    @IsTest
    static void testInvalidAssetIdentifier() {
        Test.startTest();
        String unknownIdentifierResponse = AssetService.reportLostDevice('UNKNOWN-ASSET-ID');
        Test.stopTest();

        System.assertEquals(NO_DEVICE_FOUND_MESSAGE, unknownIdentifierResponse, 'Unknown assetIdentifier should return no-device message.');
    }

    @IsTest
    static void testReturnsClaimNumberForActiveComprehensiveCoverage() {
        String identifier = 'AST-COVERED-' + String.valueOf(DateTime.now().getTime());
        Asset assetRecord = createAsset('Covered Drone', identifier);

        Insurance__c policy = new Insurance__c(
            Asset__c = assetRecord.Id,
            Active__c = true,
            Coverage__c = 'Comprehensive'
        );
        insert policy;

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/lost';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"assetIdentifier":"' + identifier + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = AssetService.reportLostDevice();
        Test.stopTest();

        System.assert(!String.isBlank(response), 'Claim number should be returned when active comprehensive coverage exists.');

        Claim__c createdClaim = [
            SELECT Id, Name, Type__c, Status__c, Asset__c, Insurance__c
            FROM Claim__c
            WHERE Name = :response
            LIMIT 1
        ];
        System.assertEquals('Loss', createdClaim.Type__c, 'Created claim must be a loss claim.');
        System.assertEquals('New', createdClaim.Status__c, 'Created claim should use New status.');
        System.assertEquals(assetRecord.Id, createdClaim.Asset__c, 'Created claim should be linked to the asset.');
        System.assertEquals(policy.Id, createdClaim.Insurance__c, 'Created claim should be linked to the active policy.');

        Asset refreshedAsset = [SELECT Status FROM Asset WHERE Id = :assetRecord.Id LIMIT 1];
        System.assertEquals('Lost', refreshedAsset.Status, 'Asset status should be updated to Lost when reported.');
    }

    @IsTest
    static void testReturnsAlreadyFiledWhenLossClaimExists() {
        String identifier = 'AST-ALREADY-' + String.valueOf(DateTime.now().getTime());
        Asset assetRecord = createAsset('Already Claimed Drone', identifier);

        Insurance__c policy = new Insurance__c(
            Asset__c = assetRecord.Id,
            Active__c = true,
            Coverage__c = 'Comprehensive'
        );
        insert policy;

        Claim__c existingClaim = new Claim__c(
            Asset__c = assetRecord.Id,
            Insurance__c = policy.Id,
            Type__c = 'Loss',
            Status__c = 'New'
        );
        insert existingClaim;
        existingClaim = [SELECT Name FROM Claim__c WHERE Id = :existingClaim.Id LIMIT 1];

        Test.startTest();
        String response = AssetService.reportLostDevice(identifier);
        Test.stopTest();

        System.assertEquals(existingClaim.Name + ' already filed.', response, 'Service should return already-filed message when loss claim exists.');

        Integer claimCount = [SELECT COUNT() FROM Claim__c WHERE Asset__c = :assetRecord.Id AND Type__c = 'Loss'];
        System.assertEquals(1, claimCount, 'No additional loss claim should be created.');
    }

    @IsTest
    static void testReturnsNoCoverageAndAdjustsAssetStatus() {
        String identifier = 'AST-NOCOVERAGE-' + String.valueOf(DateTime.now().getTime());
        Asset assetRecord = createAsset('Uninsured Drone', identifier);

        Test.startTest();
        String response = AssetService.reportLostDevice(identifier);
        Test.stopTest();

        System.assertEquals(NO_COVERAGE_MESSAGE, response, 'Without active comprehensive coverage, no-coverage message should be returned.');

        Asset refreshedAsset = [SELECT Status FROM Asset WHERE Id = :assetRecord.Id LIMIT 1];
        System.assertEquals('Lost', refreshedAsset.Status, 'Asset should still be marked Lost without coverage.');

        Integer claimCount = [SELECT COUNT() FROM Claim__c WHERE Asset__c = :assetRecord.Id];
        System.assertEquals(0, claimCount, 'No claim should be created when coverage is missing.');
    }

    private static Asset createAsset(String assetName, String identifier) {
        Account accountRecord = new Account(Name = 'Test Account ' + identifier);
        insert accountRecord;

        Asset assetRecord = new Asset(
            Name = assetName,
            Asset_Identifier__c = identifier,
            AccountId = accountRecord.Id,
            Status = 'Installed'
        );
        insert assetRecord;
        return assetRecord;
    }
}