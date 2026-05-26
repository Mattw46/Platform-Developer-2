@RestResource(urlMapping='/ProductZoning/*')
/**
 * REST service that returns the permissible fly zone for a given product and country.
 */
global with sharing class ProductZoningService {
    private static final String DEFAULT_COUNTRY_CODE = 'US';
    private static final String INVALID_PRODUCT_CODE_MESSAGE = 'ProductCode is missing or doesn\'t exist in response.';
    private static final String LOCAL_AUTHORITIES_MESSAGE = 'Confirm with the local authorities';

    @HttpGet
    /**
     * Resolves fly-zone guidance for a product code and a country code header.
        * @return Permissible fly zone or fallback guidance message.
     */
    global static String getFlyZone() {
        RestRequest request = RestContext.request;
        String countryCode = getHeaderValue(request, 'CountryCode');
        if (String.isBlank(countryCode)) {
            countryCode = DEFAULT_COUNTRY_CODE;
        }

        String productCode = getProductCode(request);
        if (String.isBlank(productCode)) {
            return INVALID_PRODUCT_CODE_MESSAGE;
        }

        Product2 product = getProductByCode(productCode);
        if (product == null || String.isBlank(product.Family)) {
            return INVALID_PRODUCT_CODE_MESSAGE;
        }

        String permissibleFlyZone = getPermissibleFlyZone(product.Family, countryCode);
        if (String.isBlank(permissibleFlyZone)) {
            return LOCAL_AUTHORITIES_MESSAGE;
        }

        return permissibleFlyZone;
    }

    private static Product2 getProductByCode(String productCode) {
        if (
            !Schema.sObjectType.Product2.isAccessible() ||
            !Schema.sObjectType.Product2.fields.ProductCode.isAccessible() ||
            !Schema.sObjectType.Product2.fields.Family.isAccessible()
        ) {
            return null;
        }

        List<Product2> products = [
            SELECT Id, Family
            FROM Product2
            WHERE ProductCode = :productCode
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return products.isEmpty() ? null : products[0];
    }

    private static String getHeaderValue(RestRequest request, String headerName) {
        if (request == null || request.headers == null) {
            return null;
        }

        if (request.headers.containsKey(headerName)) {
            return request.headers.get(headerName);
        }

        for (String headerKey : request.headers.keySet()) {
            if (headerKey != null && headerKey.equalsIgnoreCase(headerName)) {
                return request.headers.get(headerKey);
            }
        }

        return null;
    }

    private static String getProductCode(RestRequest request) {
        if (request == null) {
            return null;
        }

        String productCode;
        if (request.params != null) {
            productCode = request.params.get('ProductCode');
        }
        if (!String.isBlank(productCode)) {
            return productCode;
        }

        if (String.isBlank(request.requestURI)) {
            return null;
        }

        List<String> uriSegments = request.requestURI.split('/');
        if (uriSegments.isEmpty()) {
            return null;
        }

        String lastSegment = uriSegments[uriSegments.size() - 1];
        if (String.isBlank(lastSegment) || lastSegment.equalsIgnoreCase('ProductZoning')) {
            return null;
        }

        return EncodingUtil.urlDecode(lastSegment, 'UTF-8');
    }

    private static String getPermissibleFlyZone(String productFamily, String countryCode) {
        if (
            !Schema.sObjectType.Product_Geo_Mapping__mdt.isAccessible() ||
            !Schema.sObjectType.Product_Geo_Mapping__mdt.fields.Product_Family__c.isAccessible() ||
            !Schema.sObjectType.Product_Geo_Mapping__mdt.fields.Country_Code__c.isAccessible() ||
            !Schema.sObjectType.Product_Geo_Mapping__mdt.fields.Permissible_Fly_Zone__c.isAccessible()
        ) {
            return null;
        }

        List<Product_Geo_Mapping__mdt> mappings = [
            SELECT Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            WHERE Product_Family__c = :productFamily
            AND Country_Code__c = :countryCode
            LIMIT 1
        ];
        if (mappings.isEmpty()) {
            return null;
        }
        return mappings[0].Permissible_Fly_Zone__c;
    }
}