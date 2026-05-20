/**
 * Test class for RewardsCalloutService
 * Validates HTTP callout functionality with reusable mock responses
 */
@IsTest
private class RewardsCalloutServiceTest {

    // ─── Positive Tests ──────────────────────────────────────────────────

    /**
     * Test successful callout with valid JSON body
     */
    @IsTest
    static void shouldReturnSuccessWhenValidJsonBody() {
        // Given
        String jsonBody = '{"users":[{"userId":"005xx000001X8Uz","name":"John Doe"}]}';
        Test.setMock(HttpCalloutMock.class, new RewardsCalloutServiceMock());

        // When
        Test.startTest();
        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout(jsonBody);
        Test.stopTest();

        // Then
        Assert.areEqual(200, statusCode,
            'Status code should be 200 for successful callout');
    }

    /**
     * Test non-success callout status is returned from service
     */
    @IsTest
    static void shouldReturnHttpErrorStatusWhenApiReturnsBadRequest() {
        // Given
        String jsonBody = '{"invalid":"data"}';
        Test.setMock(HttpCalloutMock.class, new RewardsCalloutServiceMock(400, '{"error":"Invalid request"}'));

        // When
        Test.startTest();
        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout(jsonBody);
        Test.stopTest();

        // Then
        Assert.areEqual(400, statusCode,
            'Status code should be 400 when API returns bad request');
    }

    // ─── Negative Tests ──────────────────────────────────────────────────

    /**
     * Test callout exception returns 500 status
     */
    @IsTest
    static void shouldReturnInternalServerErrorWhenCalloutThrowsException() {
        // Given
        String jsonBody = '{"users":[]}';
        Test.setMock(HttpCalloutMock.class, new RewardsCalloutServiceMock('Network error'));

        // When
        Test.startTest();
        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout(jsonBody);
        Test.stopTest();

        // Then
        Assert.areEqual(500, statusCode,
            'Status code should be 500 when callout throws exception');
    }
}