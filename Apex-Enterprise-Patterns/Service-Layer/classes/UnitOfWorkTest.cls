/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UnitOfWorkTest {

    @isTest
    static void challengeComplete() {
        // TO DO: implement unit test
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new Schema.SObjectType[]{
                Account.SObjectType,
                Contact.SObjectType,
                Note.SObjectType
            }   
        );

        for (Integer i = 0; i < 100; i++) {
            Account acc = new Account();
            acc.Name = 'Test_' + i;
            uow.registerNew(acc);

            for (Integer j = 0; j < 5; j++) {
                Contact con = new Contact(LastName = 'Test ' + j);    
                uow.registerNew(con, Contact.AccountId, acc);

                Note n = new Note(Title = 'Test ' + j, Body = 'Test ' + j);
                uow.registerNew(n, Note.ParentId, con);
            }
        }

        test.startTest();
        uow.commitWork();
        test.stopTest();

        System.assertEquals(100, [Select Id from Account].size());
        System.assertEquals(500, [Select Id from Contact].size());
        System.assertEquals(500, [Select Id from Note].size());
    }
}