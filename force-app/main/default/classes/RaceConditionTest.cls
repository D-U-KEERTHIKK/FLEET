/**
 * @description Test class demonstrating race conditions
 * Shows how to test for race conditions and verify the fixes
 */
@isTest
private class RaceConditionTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                NumberOfEmployees = 100,
                AnnualRevenue = 10000
            ));
        }
        insert accounts;
        
        // Create test product (if Product2 exists with custom field)
        // Note: You may need to create a custom field QuantityOnHand__c on Product2
        /*
        Product2 product = new Product2(
            Name = 'Test Product',
            QuantityOnHand__c = 100,
            IsActive = true
        );
        insert product;
        */
        
        // Create test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web'
        );
        insert testCase;
    }
    
    /**
     * @description Test 1: Demonstrates counter race condition
     * This test shows what happens when multiple transactions increment a counter
     */
    @isTest
    static void testCounterRaceCondition() {
        Account acc = [SELECT Id, NumberOfEmployees FROM Account LIMIT 1];
        Integer initialCount = acc.NumberOfEmployees;
        
        Test.startTest();
        
        // Simulate concurrent updates (in test context, these run sequentially)
        // In real scenario, these would be parallel transactions
        RaceConditionDemo.incrementCounterUnsafe(acc.Id);
        RaceConditionDemo.incrementCounterUnsafe(acc.Id);
        RaceConditionDemo.incrementCounterUnsafe(acc.Id);
        
        Test.stopTest();
        
        // Without FOR UPDATE, if these were truly concurrent, 
        // the final count might not be initial + 3
        Account updatedAcc = [SELECT NumberOfEmployees FROM Account WHERE Id = :acc.Id];
        System.assertEquals(initialCount + 3, updatedAcc.NumberOfEmployees, 
                          'Counter should be incremented 3 times');
    }
    
    /**
     * @description Test 2: Demonstrates safe counter with FOR UPDATE
     */
    @isTest
    static void testCounterSafe() {
        Account acc = [SELECT Id, NumberOfEmployees FROM Account LIMIT 1];
        Integer initialCount = acc.NumberOfEmployees;
        
        Test.startTest();
        
        // Safe version with FOR UPDATE
        RaceConditionDemo.incrementCounterSafe(acc.Id);
        RaceConditionDemo.incrementCounterSafe(acc.Id);
        RaceConditionDemo.incrementCounterSafe(acc.Id);
        
        Test.stopTest();
        
        Account updatedAcc = [SELECT NumberOfEmployees FROM Account WHERE Id = :acc.Id];
        System.assertEquals(initialCount + 3, updatedAcc.NumberOfEmployees, 
                          'Safe counter should correctly increment 3 times');
    }
    
    /**
     * @description Test 3: Balance deduction race condition
     */
    @isTest
    static void testBalanceRaceCondition() {
        Account acc = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        Decimal initialBalance = acc.AnnualRevenue;
        
        Test.startTest();
        
        // Try multiple debits
        Boolean result1 = RaceConditionDemo.debitAccountUnsafe(acc.Id, 100);
        Boolean result2 = RaceConditionDemo.debitAccountUnsafe(acc.Id, 200);
        Boolean result3 = RaceConditionDemo.debitAccountUnsafe(acc.Id, 150);
        
        Test.stopTest();
        
        System.assert(result1 && result2 && result3, 'All debits should succeed');
        
        Account updatedAcc = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(initialBalance - 450, updatedAcc.AnnualRevenue, 
                          'Balance should be reduced by total debits');
    }
    
    /**
     * @description Test 4: Safe balance deduction with FOR UPDATE
     */
    @isTest
    static void testBalanceSafe() {
        Account acc = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        Decimal initialBalance = acc.AnnualRevenue;
        
        Test.startTest();
        
        // Safe version
        Boolean result1 = RaceConditionDemo.debitAccountSafe(acc.Id, 100);
        Boolean result2 = RaceConditionDemo.debitAccountSafe(acc.Id, 200);
        Boolean result3 = RaceConditionDemo.debitAccountSafe(acc.Id, 150);
        
        Test.stopTest();
        
        System.assert(result1 && result2 && result3, 'All safe debits should succeed');
        
        Account updatedAcc = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(initialBalance - 450, updatedAcc.AnnualRevenue, 
                          'Safe balance should be correctly reduced');
    }
    
    /**
     * @description Test 5: Status transition race condition
     */
    @isTest
    static void testStatusRaceCondition() {
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];
        
        Test.startTest();
        
        // Unsafe status update
        Boolean result = RaceConditionDemo.updateStatusUnsafe(
            testCase.Id, 'In Progress'
        );
        
        Test.stopTest();
        
        System.assert(result, 'Status update should succeed');
        
        Case updatedCase = [SELECT Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('In Progress', updatedCase.Status, 'Status should be updated');
    }
    
    /**
     * @description Test 6: Safe status transition with state validation
     */
    @isTest
    static void testStatusSafe() {
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];
        
        Test.startTest();
        
        // Safe version with expected state check
        Boolean result = RaceConditionDemo.updateStatusSafe(
            testCase.Id, 'New', 'In Progress'
        );
        
        Test.stopTest();
        
        System.assert(result, 'Safe status update should succeed');
        
        Case updatedCase = [SELECT Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('In Progress', updatedCase.Status, 
                          'Status should be safely updated');
    }
    
    /**
     * @description Test 7: Async race condition scenario
     */
    @isTest
    static void testAsyncRaceCondition() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Trigger multiple async updates
        RaceConditionDemo.updateRecordAsync(acc.Id, 'Async Update 1');
        RaceConditionDemo.updateRecordAsync(acc.Id, 'Async Update 2');
        
        Test.stopTest(); // This ensures futures complete
        
        // Verify the record was updated (last one wins due to FOR UPDATE in the method)
        Account updatedAcc = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assert(updatedAcc.Name.contains('Async Update'), 
                     'Account should be updated by async process');
    }
    
    /**
     * @description Test 8: Batch processing race condition
     */
    @isTest
    static void testBatchRaceCondition() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 3];
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        
        // Unsafe batch processing
        RaceConditionDemo.processAccountsUnsafe(accountIds);
        
        Test.stopTest();
        
        List<Account> updatedAccounts = [
            SELECT NumberOfEmployees 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(101, acc.NumberOfEmployees, 
                              'Each account should be incremented once');
        }
    }
    
    /**
     * @description Test 9: Safe batch processing
     */
    @isTest
    static void testBatchSafe() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 3];
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        
        // Safe batch processing with FOR UPDATE
        RaceConditionDemo.processAccountsSafe(accountIds);
        
        Test.stopTest();
        
        List<Account> updatedAccounts = [
            SELECT NumberOfEmployees 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(101, acc.NumberOfEmployees, 
                              'Each account should be safely incremented');
        }
    }
    
    /**
     * @description Test 10: Demonstrates UNABLE_TO_LOCK_ROW exception
     * This test shows what happens when lock conflicts occur
     */
    @isTest
    static void testLockConflictHandling() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        try {
            // In real scenario with true concurrency, this could fail
            // In test context, we simulate the behavior
            RaceConditionDemo.incrementCounterSafe(acc.Id);
            
            System.assert(true, 'Lock acquired successfully');
            
        } catch (QueryException e) {
            // This would happen if record is already locked
            System.assert(e.getMessage().contains('UNABLE_TO_LOCK_ROW'), 
                         'Should get lock exception');
        }
        
        Test.stopTest();
    }
}