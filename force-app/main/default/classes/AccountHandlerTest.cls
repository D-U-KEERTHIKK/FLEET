@isTest
public class AccountHandlerTest {
    
    @isTest
    static void testHandleInsert() {
        // Test that new accounts get default values set
        Test.startTest();
        
        Account testAccount = new Account(
            Name = 'Test Account Insert'
        );
        insert testAccount;
        
        Test.stopTest();
        
        // Verify the fields were set correctly
        Account insertedAccount = [SELECT Id, Name, Custom_Account_Status__c, Account_Type__c 
                                    FROM Account 
                                    WHERE Id = :testAccount.Id];
        
        System.assertEquals('Active', insertedAccount.Custom_Account_Status__c, 
                          'Account Status should be set to Active on insert');
        System.assertEquals('Prospect', insertedAccount.Account_Type__c, 
                          'Account Type should be set to Prospect on insert');
    }
    
    @isTest
    static void testHandleInsertBulk() {
        // Test bulk insert of accounts
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 200; i++) {
            testAccounts.add(new Account(
                Name = 'Bulk Test Account ' + i
            ));
        }
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Verify all accounts have correct values
        List<Account> insertedAccounts = [SELECT Id, Custom_Account_Status__c, Account_Type__c 
                                          FROM Account 
                                          WHERE Id IN :testAccounts];
        
        System.assertEquals(200, insertedAccounts.size(), 'Should insert 200 accounts');
        
        for (Account acc : insertedAccounts) {
            System.assertEquals('Active', acc.Custom_Account_Status__c, 
                              'All accounts should have Active status');
            System.assertEquals('Prospect', acc.Account_Type__c, 
                              'All accounts should have Prospect type');
        }
    }
    
    @isTest
    static void testHandleUpdate() {
        // Create an account first
        Account testAccount = new Account(
            Name = 'Test Account Update'
        );
        insert testAccount;
        
        // Verify initial values from insert
        testAccount = [SELECT Id, Name, Custom_Account_Status__c, Account_Type__c 
                       FROM Account 
                       WHERE Id = :testAccount.Id];
        System.assertEquals('Active', testAccount.Custom_Account_Status__c);
        System.assertEquals('Prospect', testAccount.Account_Type__c);
        
        Test.startTest();
        
        // Update the account - change the name to trigger the update logic
        testAccount.Name = 'Updated Test Account';
        update testAccount;
        
        Test.stopTest();
        
        // Verify the fields were updated correctly
        Account updatedAccount = [SELECT Id, Name, Custom_Account_Status__c, Account_Type__c 
                                  FROM Account 
                                  WHERE Id = :testAccount.Id];
        
        System.assertEquals('Updated', updatedAccount.Custom_Account_Status__c, 
                          'Account Status should be set to Updated on update');
        System.assertEquals('Customer', updatedAccount.Account_Type__c, 
                          'Account Type should be set to Customer on update');
    }
    
    @isTest
    static void testHandleUpdateBulk() {
        // Create multiple accounts
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 200; i++) {
            testAccounts.add(new Account(
                Name = 'Bulk Update Test ' + i
            ));
        }
        insert testAccounts;
        
        Test.startTest();
        
        // Update all accounts
        for (Account acc : testAccounts) {
            acc.Name = acc.Name + ' - Modified';
        }
        update testAccounts;
        
        Test.stopTest();
        
        // Verify all accounts were updated correctly
        List<Account> updatedAccounts = [SELECT Id, Custom_Account_Status__c, Account_Type__c 
                                         FROM Account 
                                         WHERE Id IN :testAccounts];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals('Updated', acc.Custom_Account_Status__c, 
                              'All accounts should have Updated status');
            System.assertEquals('Customer', acc.Account_Type__c, 
                              'All accounts should have Customer type');
        }
    }
    
    @isTest
    static void testHandleUpdateNoChange() {
        // Create an account
        Account testAccount = new Account(
            Name = 'Test No Change'
        );
        insert testAccount;
        
        // Get the account after insert
        testAccount = [SELECT Id, Name, Custom_Account_Status__c, Account_Type__c, Phone 
                       FROM Account 
                       WHERE Id = :testAccount.Id];
        
        Test.startTest();
        
        // Update a field that doesn't trigger the update logic
        testAccount.Phone = '555-1234';
        update testAccount;
        
        Test.stopTest(); 
        
        // Verify the status fields were NOT changed (should still be from insert)
        Account updatedAccount = [SELECT Id, Custom_Account_Status__c, Account_Type__c 
                                  FROM Account 
                                  WHERE Id = :testAccount.Id];
        
        System.assertEquals('Active', updatedAccount.Custom_Account_Status__c, 
                          'Account Status should remain Active when non-tracked fields change');
        System.assertEquals('Prospect', updatedAccount.Account_Type__c, 
                          'Account Type should remain Prospect when non-tracked fields change');
    }
}