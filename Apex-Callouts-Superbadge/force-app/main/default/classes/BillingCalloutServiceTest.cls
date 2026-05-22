@IsTest
private class BillingCalloutServiceTest {

    @IsTest
    static void shouldMarkAccessibilityProjectCompleteWhenBillingReturnsOk() {
        BillingCalloutServiceMock.lastProject = null;

        Accessibility_Project__c accessibilityProject = new Accessibility_Project__c(
            Amount__c = 200,
            Type__c = 'Sign Language Interpreters',
            Status__c = 'Submitted'
        );
        insert accessibilityProject;

        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock('OK'));

        Test.startTest();
        AccessibilityProjectBilling.callBillingService(accessibilityProject.Id, accessibilityProject.Amount__c);
        Test.stopTest();

        Accessibility_Project__c updatedProject = [
            SELECT Status__c
            FROM Accessibility_Project__c
            WHERE Id = :accessibilityProject.Id
            LIMIT 1
        ];

        Assert.areEqual('Complete', updatedProject.Status__c,
            'Accessibility project should be marked Complete when billing returns OK.');
        Assert.isNotNull(BillingCalloutServiceMock.lastProject,
            'SOAP request payload should be captured by mock.');
        Assert.areEqual(String.valueOf(accessibilityProject.Id), BillingCalloutServiceMock.lastProject.projectid,
            'Project id passed to billing SOAP call should match Accessibility Project Id.');
    }

    @IsTest
    static void shouldNotUpdateAccessibilityProjectWhenBillingNotOk() {
        Accessibility_Project__c accessibilityProject = new Accessibility_Project__c(
            Amount__c = 300,
            Type__c = 'Sign Language Interpreters',
            Status__c = 'Submitted'
        );
        insert accessibilityProject;

        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock('FAILED'));

        Test.startTest();
        AccessibilityProjectBilling.callBillingService(accessibilityProject.Id, accessibilityProject.Amount__c);
        Test.stopTest();

        Accessibility_Project__c unchangedProject = [
            SELECT Status__c
            FROM Accessibility_Project__c
            WHERE Id = :accessibilityProject.Id
            LIMIT 1
        ];

        Assert.areEqual('Submitted', unchangedProject.Status__c,
            'Accessibility project should remain Submitted when billing status is not OK.');
    }

    @IsTest
    static void shouldSendCalloutForMissingProjectRecordWhenBillingNotOk() {
        BillingCalloutServiceMock.lastProject = null;

        Accessibility_Project__c accessibilityProject = new Accessibility_Project__c(
            Amount__c = 400,
            Type__c = 'Sign Language Interpreters',
            Status__c = 'Submitted'
        );
        insert accessibilityProject;
        Id deletedProjectId = accessibilityProject.Id;
        delete accessibilityProject;

        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock('FAILED'));

        Test.startTest();
        AccessibilityProjectBilling.callBillingService(deletedProjectId, 400);
        Test.stopTest();

        Assert.isNotNull(BillingCalloutServiceMock.lastProject,
            'Future callout should execute even when project record no longer exists.');
        Assert.areEqual(String.valueOf(deletedProjectId), BillingCalloutServiceMock.lastProject.projectid,
            'Deleted project id should still be passed to SOAP payload.');
        Assert.areEqual(400.0, BillingCalloutServiceMock.lastProject.billAmount,
            'Billing amount should still be passed for missing record case.');
    }

    @IsTest
    static void shouldReturnOkResponseFromBillingServiceProxyMock() {
        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock('OK'));

        BillingServiceProxy.project project = new BillingServiceProxy.project();
        project.username = 'testUser';
        project.password = 'testPass';
        project.projectid = 'a00123456789012AAA';
        project.billAmount = 150.0;

        Test.startTest();
        String status = new BillingServiceProxy.InvoicesPortSoap11().billProject(project);
        Test.stopTest();

        Assert.areEqual('OK', status, 'Should return mocked OK response.');
    }

    @IsTest
    static void shouldCaptureBillingServiceRequestInMock() {
        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock('OK'));

        BillingServiceProxy.project project = new BillingServiceProxy.project();
        project.username = 'testUser';
        project.password = 'testPass';
        project.projectid = 'a00123456789012AAB';
        project.billAmount = 250.0;

        Test.startTest();
        new BillingServiceProxy.InvoicesPortSoap11().billProject(project);
        Test.stopTest();

        Assert.isNotNull(BillingCalloutServiceMock.lastProject, 'Mock should capture project data.');
        Assert.areEqual('a00123456789012AAB', BillingCalloutServiceMock.lastProject.projectid, 'Project ID should match');
        Assert.areEqual(250.0, BillingCalloutServiceMock.lastProject.billAmount, 'Bill amount should match');
    }

    @IsTest
    static void shouldThrowCalloutExceptionWhenMockConfiguredToThrow() {
        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock(true, 'Service error'));

        BillingServiceProxy.project project = new BillingServiceProxy.project();
        project.projectid = 'a00123456789012AAC';
        project.billAmount = 100.0;

        Test.startTest();
        try {
            new BillingServiceProxy.InvoicesPortSoap11().billProject(project);
            Assert.fail('Should throw CalloutException');
        } catch (CalloutException ex) {
            Assert.areEqual('Service error', ex.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
}
