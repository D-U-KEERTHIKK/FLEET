@isTest 
private class AccountTriggerTest { 
 
    @isTest
    static void testAccountInsert() {   
        // Create a new Account record  
        //  3rd Dec Demo
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount; 
        
        // Query to ensure the Custom_Account_Status__c field is set correctly
        Account insertedAccount = [SELECT Custom_Account_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Active', insertedAccount.Custom_Account_Status__c);
    }
 
    @isTest
    static void testAccountUpdate() {
        // Create and insert a new Account record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Update the Account's Name
        // 3rd Dec Demo
        testAccount.Name = 'Updated Account';
        update testAccount; 
        
        // Query to ensure the Custom_Account_Status__c field is set correctly after update
        Account updatedAccount = [SELECT Custom_Account_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Updated', updatedAccount.Custom_Account_Status__c);
    }
}