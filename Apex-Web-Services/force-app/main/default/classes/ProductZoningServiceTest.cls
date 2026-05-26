@IsTest
private class ProductZoningServiceTest {
    private static final String INVALID_PRODUCT_CODE_MESSAGE = 'ProductCode is missing or doesn\'t exist in response.';
    private static final String LOCAL_AUTHORITIES_MESSAGE = 'Confirm with the local authorities';

    @IsTest
    static void testReturnsPermissibleFlyZoneForValidInput() {
        Product_Geo_Mapping__mdt mapping = [
            SELECT Product_Family__c, Country_Code__c, Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            WHERE Permissible_Fly_Zone__c != null
            LIMIT 1
        ];
        System.assertNotEquals(null, mapping, 'Expected Product Geo Mapping metadata with a configured fly zone.');

        String productCode = 'PZ-' + String.valueOf(DateTime.now().getTime());
        insert new Product2(
            Name = 'Fly Zone Product ' + productCode,
            ProductCode = productCode,
            Family = mapping.Product_Family__c,
            IsActive = true
        );

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/ProductZoning';
        request.httpMethod = 'GET';
        request.addParameter('ProductCode', productCode);
        request.headers.put('CountryCode', mapping.Country_Code__c);
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(mapping.Permissible_Fly_Zone__c, response, 'Service should return fly zone from custom metadata.');
    }

    @IsTest
    static void testReturnsConfirmLocalAuthoritiesWhenNoSpecificRegulationExists() {
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        String productCode = 'PZ-UNMAPPED-' + uniqueSuffix;
        insert new Product2(
            Name = 'Unmapped Product ' + uniqueSuffix,
            ProductCode = productCode,
            Family = 'UNMAPPED_FAMILY_' + uniqueSuffix,
            IsActive = true
        );

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/ProductZoning/' + productCode;
        request.httpMethod = 'GET';
        request.headers.put('CountryCode', 'US');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(LOCAL_AUTHORITIES_MESSAGE, response, 'Unmapped family/country should return local-authorities guidance.');
    }

    @IsTest
    static void testReturnsErrorForMissingProductCode() {
        RestRequest missingCodeRequest = new RestRequest();
        missingCodeRequest.requestURI = '/services/apexrest/ProductZoning';
        missingCodeRequest.httpMethod = 'GET';
        missingCodeRequest.headers.put('CountryCode', 'AU');
        RestContext.request = missingCodeRequest;
        RestContext.response = new RestResponse();

        Test.startTest();
        String missingCodeResponse = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(INVALID_PRODUCT_CODE_MESSAGE, missingCodeResponse, 'Missing ProductCode should return required validation message.');
    }

    @IsTest
    static void testReturnsErrorForInvalidProductCode() {
        RestRequest invalidCodeRequest = new RestRequest();
        invalidCodeRequest.requestURI = '/services/apexrest/ProductZoning';
        invalidCodeRequest.httpMethod = 'GET';
        invalidCodeRequest.headers.put('CountryCode', 'DE');
        invalidCodeRequest.addParameter('ProductCode', 'DOES_NOT_EXIST');
        RestContext.request = invalidCodeRequest;
        RestContext.response = new RestResponse();

        Test.startTest();
        String invalidCodeResponse = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(INVALID_PRODUCT_CODE_MESSAGE, invalidCodeResponse, 'Unknown ProductCode should return required validation message.');
    }

    @IsTest
    static void testHeaderLookupIsCaseInsensitive() {
        Product_Geo_Mapping__mdt mapping = [
            SELECT Product_Family__c, Country_Code__c, Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            WHERE Permissible_Fly_Zone__c != null
            LIMIT 1
        ];

        String productCode = 'PZ-HDR-' + String.valueOf(DateTime.now().getTime());
        insert new Product2(
            Name = 'Header Case Product ' + productCode,
            ProductCode = productCode,
            Family = mapping.Product_Family__c,
            IsActive = true
        );

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/ProductZoning';
        request.httpMethod = 'GET';
        request.addParameter('ProductCode', productCode);
        request.headers.put('countrycode', mapping.Country_Code__c);
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(mapping.Permissible_Fly_Zone__c, response, 'CountryCode header lookup should be case-insensitive.');
    }

    @IsTest
    static void testProductCodeFromEncodedWildcardPath() {
        Product_Geo_Mapping__mdt mapping = [
            SELECT Product_Family__c, Country_Code__c, Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            WHERE Permissible_Fly_Zone__c != null
            LIMIT 1
        ];

        String productCode = 'PZ SPACE ' + String.valueOf(DateTime.now().getTime());
        insert new Product2(
            Name = 'Encoded Path Product ' + productCode,
            ProductCode = productCode,
            Family = mapping.Product_Family__c,
            IsActive = true
        );

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/ProductZoning/' + EncodingUtil.urlEncode(productCode, 'UTF-8');
        request.httpMethod = 'GET';
        request.headers.put('CountryCode', mapping.Country_Code__c);
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(mapping.Permissible_Fly_Zone__c, response, 'Service should decode ProductCode from wildcard path segment.');
    }

    @IsTest
    static void testDefaultsCountryCodeToUSWhenHeaderMissing() {
        List<Product_Geo_Mapping__mdt> usMappings = [
            SELECT Product_Family__c, Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            WHERE Country_Code__c = 'US'
            AND Permissible_Fly_Zone__c != null
            LIMIT 1
        ];
        Product_Geo_Mapping__mdt usMapping = usMappings.isEmpty() ? null : usMappings[0];
        if (usMapping == null) {
            String uniqueSuffix = String.valueOf(DateTime.now().getTime());
            String productCode = 'PZ-DEFAULT-US-' + uniqueSuffix;
            insert new Product2(
                Name = 'Default Country Product ' + uniqueSuffix,
                ProductCode = productCode,
                Family = 'NO_US_MAPPING_' + uniqueSuffix,
                IsActive = true
            );

            RestRequest fallbackRequest = new RestRequest();
            fallbackRequest.requestURI = '/services/apexrest/ProductZoning';
            fallbackRequest.httpMethod = 'GET';
            fallbackRequest.addParameter('ProductCode', productCode);
            RestContext.request = fallbackRequest;
            RestContext.response = new RestResponse();

            Test.startTest();
            String fallbackResponse = ProductZoningService.getFlyZone();
            Test.stopTest();

            System.assertEquals(LOCAL_AUTHORITIES_MESSAGE, fallbackResponse, 'When default country has no mapping, fallback message should be returned.');
            return;
        }

        String productCode = 'PZ-US-' + String.valueOf(DateTime.now().getTime());
        insert new Product2(
            Name = 'US Default Product ' + productCode,
            ProductCode = productCode,
            Family = usMapping.Product_Family__c,
            IsActive = true
        );

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/ProductZoning';
        request.httpMethod = 'GET';
        request.addParameter('ProductCode', productCode);
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = ProductZoningService.getFlyZone();
        Test.stopTest();

        System.assertEquals(usMapping.Permissible_Fly_Zone__c, response, 'Missing CountryCode header should default to US mapping.');
    }
}