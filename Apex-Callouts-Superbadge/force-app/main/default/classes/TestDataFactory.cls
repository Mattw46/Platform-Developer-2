/**
 * @description Centralized factory for creating test data with sensible defaults.
 *              All methods accept a doInsert flag for flexibility.
 *              Bulk methods create multiple records; single-record methods delegate to bulk.
 */
@IsTest
public class TestDataFactory {

    // ─── Users ────────────────────────────────────────────────────────────

    /**
     * Creates test users with unique usernames and emails
     * @param count Number of users to create
     * @param doInsert Whether to insert the records
     * @return List of created User records
     */
    public static List<User> createUsers(Integer count, Boolean doInsert) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> users = new List<User>();
        
        for (Integer i = 0; i < count; i++) {
            String uniqueKey = String.valueOf(DateTime.now().getTime()) + i;
            users.add(new User(
                FirstName = 'Test',
                LastName = 'User ' + i,
                Email = 'testuser' + uniqueKey + '@example.com',
                Username = 'testuser' + uniqueKey + '@example.com.test',
                Alias = 'tuser' + Math.mod(i, 5),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id
            ));
        }
        
        if (doInsert) {
            insert users;
        }
        return users;
    }

    /**
     * Single user convenience method
     * @param doInsert Whether to insert the record
     * @return Created User record
     */
    public static User createUser(Boolean doInsert) {
        return createUsers(1, doInsert)[0];
    }

    // ─── Wellness Journey ─────────────────────────────────────────────────

    /**
     * Creates Wellness Journey records for specified users
     * @param userIds List of User IDs to create journeys for
     * @param countPerUser Number of journeys per user
     * @param completedDate The completion date for the journeys
     * @param doInsert Whether to insert the records
     * @return List of created Wellness_Journey__c records
     */
    public static List<Wellness_Journey__c> createWellnessJourneys(
        List<Id> userIds,
        Integer countPerUser,
        Date completedDate,
        Boolean doInsert
    ) {
        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();
        Integer idx = 0;
        
        for (Id userId : userIds) {
            for (Integer i = 0; i < countPerUser; i++) {
                journeys.add(new Wellness_Journey__c(
                    Name = 'Journey ' + idx,
                    OwnerId = userId,
                    Completion_Date__c = completedDate,
                    Status__c = 'Complete'
                ));
                idx++;
            }
        }
        
        if (doInsert) {
            insert journeys;
        }
        return journeys;
    }

    /**
     * Creates Wellness Journey records with field overrides
     * @param count Number of journeys to create
     * @param fieldOverrides Map of field names to values
     * @param doInsert Whether to insert the records
     * @return List of created Wellness_Journey__c records
     */
    public static List<Wellness_Journey__c> createWellnessJourneys(
        Integer count,
        Map<String, Object> fieldOverrides,
        Boolean doInsert
    ) {
        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();
        
        for (Integer i = 0; i < count; i++) {
            Wellness_Journey__c journey = new Wellness_Journey__c(
                Name = 'Journey ' + i
            );
            
            // Apply field overrides
            if (fieldOverrides != null) {
                for (String fieldName : fieldOverrides.keySet()) {
                    journey.put(fieldName, fieldOverrides.get(fieldName));
                }
            }
            
            journeys.add(journey);
        }
        
        if (doInsert) {
            insert journeys;
        }
        return journeys;
    }

    /**
     * Creates Wellness Journey records across a date range
     * @param userId The User ID to create journeys for
     * @param count Number of journeys to create
     * @param startDate Starting date for the range
     * @param endDate Ending date for the range
     * @param doInsert Whether to insert the records
     * @return List of created Wellness_Journey__c records
     */
    public static List<Wellness_Journey__c> createWellnessJourneysInRange(
        Id userId,
        Integer count,
        Date startDate,
        Date endDate,
        Boolean doInsert
    ) {
        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();
        Integer dayRange = startDate.daysBetween(endDate);
        Integer dayIncrement = count > 1 ? dayRange / (count - 1) : 0;
        
        for (Integer i = 0; i < count; i++) {
            Date completedDate = startDate.addDays(dayIncrement * i);
            journeys.add(new Wellness_Journey__c(
                Name = 'Journey ' + i,
                OwnerId = userId,
                Completion_Date__c = completedDate,
                Status__c = 'Complete'
            ));
        }
        
        if (doInsert) {
            insert journeys;
        }
        return journeys;
    }
}