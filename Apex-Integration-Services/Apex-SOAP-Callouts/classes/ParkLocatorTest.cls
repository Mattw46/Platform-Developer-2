@isTest
private class ParkLocatorTest{
    @isTest 
    static void testParkLocator() {
        Test.setMock(WebServiceMock.class, new ParkServiceMock());
        String[] arrayOfParks = ParkLocator.country('Germany');
        
        System.assertEquals('Park1', arrayOfParks[0]);
    }
}