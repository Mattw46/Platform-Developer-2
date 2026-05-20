@IsTest
private class WellnessJourneyRewardsBatchTest {

    private static final Integer MIN_GOALS = 12;
    private static Integer callCount = 0;
    private static String lastRequestBody;

    @IsTest
    static void shouldSubmitUserWithExactly12JourneysInQuarter() {
        User u = TestDataFactory.createUser(true);
        Date quarterStart = getPreviousQuarterStart();

        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();
        for (Integer i = 0; i < MIN_GOALS; i++) {
            journeys.add(new Wellness_Journey__c(
                Name = 'Eligible Journey ' + i,
                OwnerId = u.Id,
                Status__c = 'Complete',
                Completion_Date__c = quarterStart.addDays(i)
            ));
        }
        insert journeys;

        resetMockState();
        Test.setMock(HttpCalloutMock.class, new CaptureCalloutMock());

        Test.startTest();
        Id jobId = Database.executeBatch(new WellnessJourneyRewardsBatch(), 200);
        Test.stopTest();

        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully.');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should complete without errors.');

        System.assertEquals(1, callCount, 'Batch should call the reward API once');
        System.assertNotEquals(null, lastRequestBody, 'Callout body should be captured');
        System.assert(lastRequestBody.contains((String)u.Id),
            'Payload should include the eligible user Id');
    }

    @IsTest
    static void shouldNotSubmitUserWith11JourneysInQuarter() {
        User u = TestDataFactory.createUser(true);
        Date quarterStart = getPreviousQuarterStart();

        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();
        for (Integer i = 0; i < MIN_GOALS - 1; i++) {
            journeys.add(new Wellness_Journey__c(
                Name = 'Ineligible Journey ' + i,
                OwnerId = u.Id,
                Status__c = 'Complete',
                Completion_Date__c = quarterStart.addDays(i)
            ));
        }
        insert journeys;

        resetMockState();
        Test.setMock(HttpCalloutMock.class, new CaptureCalloutMock());

        Test.startTest();
        Database.executeBatch(new WellnessJourneyRewardsBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, callCount, 'Batch still performs one callout per execute');
        System.assertEquals('[]', lastRequestBody, 'No users should be submitted when under 12 goals');
    }

    @IsTest
    static void shouldIgnoreJourneysOutsideQuarterWindow() {
        User u = TestDataFactory.createUser(true);
        Date quarterStart = getPreviousQuarterStart();

        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();
        for (Integer i = 0; i < MIN_GOALS; i++) {
            journeys.add(new Wellness_Journey__c(
                Name = 'Outside Quarter Journey ' + i,
                OwnerId = u.Id,
                Status__c = 'Complete',
                Completion_Date__c = quarterStart.addMonths(-3).addDays(i)
            ));
        }
        insert journeys;

        resetMockState();
        Test.setMock(HttpCalloutMock.class, new CaptureCalloutMock());

        Test.startTest();
        Database.executeBatch(new WellnessJourneyRewardsBatch(), 200);
        Test.stopTest();

        System.assertEquals(0, callCount,
            'No callout should happen when start() returns no records in scope');
    }

    private static Date getPreviousQuarterStart() {
        Date today = Date.today();
        Integer currentYear = today.year();
        Integer currentMonth = today.month();
        Integer previousQuarterStartMonth = ((currentMonth - 1) / 3) * 3 + 1 - 3;

        if (previousQuarterStartMonth <= 0) {
            previousQuarterStartMonth += 12;
            currentYear--;
        }

        return Date.newInstance(currentYear, previousQuarterStartMonth, 1);
    }

    private static void resetMockState() {
        callCount = 0;
        lastRequestBody = null;
    }

    private class CaptureCalloutMock implements HttpCalloutMock {
        /**
         * Captures the outgoing request body and returns a successful response.
         * @param request The outbound HTTP request from the batch callout.
         * @return A mocked successful HTTP response.
         */
        public HttpResponse respond(HttpRequest request) {
            callCount++;
            lastRequestBody = request.getBody();

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"status":"success"}');
            return response;
        }
    }
}