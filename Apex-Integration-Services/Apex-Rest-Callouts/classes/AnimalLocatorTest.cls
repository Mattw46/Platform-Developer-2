@isTest
public class AnimalLocatorTest {

    @isTest
    static void testGetAnimalNameById_Success() {
        // Set up the mock response for the callout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMock());
        
        // Call the method you want to test
        String animalName = AnimalLocator.getAnimalNameById(1); // Pass any integer ID, e.g., 1
        
        System.assertEquals('chicken', animalName);
        Test.stopTest();
    }
}