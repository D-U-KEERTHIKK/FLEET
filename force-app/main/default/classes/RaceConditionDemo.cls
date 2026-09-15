/**
 * @description Demonstrates race conditions using different scenarios
 * This class shows various types of race conditions in Salesforce
 * 
 * NOTE: All methods are now at the top level to avoid the Apex limitation
 * that inner classes cannot have static methods.
 */
public class RaceConditionDemo {
    
    // ========================================================================
    // SCENARIO 1: Counter Race Condition
    // Multiple processes incrementing the same counter
    // ========================================================================
    
    /**
     * @description UNSAFE: Simple increment without locking
     * This method is vulnerable to race conditions
     */
    public static void incrementCounterUnsafe(Id recordId) {
        Account acc = [SELECT Id, NumberOfEmployees FROM Account WHERE Id = :recordId];
        
        // Simulate some processing time
        Integer dummy = 0;
        for (Integer i = 0; i < 100; i++) {
            dummy += i;
        }
        
        acc.NumberOfEmployees = (acc.NumberOfEmployees == null ? 0 : acc.NumberOfEmployees) + 1;
        update acc;
    }
    
    /**
     * @description SAFE: Increment with locking
     * This method uses FOR UPDATE to prevent race conditions
     */
    public static void incrementCounterSafe(Id recordId) {
        Account acc = [SELECT Id, NumberOfEmployees FROM Account WHERE Id = :recordId FOR UPDATE];
        acc.NumberOfEmployees = (acc.NumberOfEmployees == null ? 0 : acc.NumberOfEmployees) + 1;
        update acc;
    }
    
    // ========================================================================
    // SCENARIO 2: Balance Update Race Condition
    // Simulates financial transactions with race conditions
    // ========================================================================
    
    /**
     * @description UNSAFE: Debit operation without proper locking
     * This can result in lost updates or incorrect balances
     */
    public static Boolean debitAccountUnsafe(Id accountId, Decimal amount) {
        Account acc = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :accountId];
        
        if (acc.AnnualRevenue != null && acc.AnnualRevenue >= amount) {
            acc.AnnualRevenue -= amount;
            update acc;
            return true;
        }
        return false;
    }
    
    /**
     * @description SAFE: Debit with FOR UPDATE
     * This ensures the balance is correctly updated even with concurrent transactions
     */
    public static Boolean debitAccountSafe(Id accountId, Decimal amount) {
        Account acc = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :accountId FOR UPDATE];
        
        if (acc.AnnualRevenue != null && acc.AnnualRevenue >= amount) {
            acc.AnnualRevenue -= amount;
            update acc;
            return true;
        }
        return false;
    }
    
    // ========================================================================
    // SCENARIO 3: Status Transition Race Condition
    // Multiple processes trying to change status simultaneously
    // ========================================================================
    
    /**
     * @description UNSAFE: Status update without checking current state properly
     * This can lead to invalid state transitions
     */
    public static Boolean updateStatusUnsafe(Id caseId, String newStatus) {
        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        
        // Some business logic here
        if (c.Status == 'New' || c.Status == 'In Progress') {
            c.Status = newStatus;
            update c;
            return true;
        }
        return false;
    }
    
    /**
     * @description SAFE: Status update with locking and state validation
     * This ensures status transitions are valid and atomic
     */
    public static Boolean updateStatusSafe(Id caseId, String expectedCurrentStatus, String newStatus) {
        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId FOR UPDATE];
        
        // Verify the current state is what we expect
        if (c.Status == expectedCurrentStatus) {
            c.Status = newStatus;
            update c;
            return true;
        }
        
        System.debug('Status transition failed. Expected: ' + expectedCurrentStatus + 
                   ', Actual: ' + c.Status);
        return false;
    }
    
    // ========================================================================
    // SCENARIO 4: Asynchronous Race Condition
    // Demonstrates race conditions with future methods
    // ========================================================================
    
    /**
     * @description Async update with proper locking
     * Future method that updates a record asynchronously
     */
    @future
    public static void updateRecordAsync(Id recordId, String newValue) {
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :recordId FOR UPDATE];
        acc.Name = newValue + ' - ' + System.now();
        update acc;
    }
    
    /**
     * @description Triggers multiple async updates
     * Calling this method will trigger multiple future calls that may execute in parallel
     */
    public static void triggerMultipleAsync(Id recordId) {
        updateRecordAsync(recordId, 'Update1');
        updateRecordAsync(recordId, 'Update2');
        updateRecordAsync(recordId, 'Update3');
        // These will execute in parallel and may conflict
    }
    
    // ========================================================================
    // SCENARIO 5: Batch Processing Race Condition
    // Shows issues with processing records in batches
    // ========================================================================
    
    /**
     * @description UNSAFE: Processing without considering other concurrent processes
     * This can cause lost updates when multiple processes work on the same records
     */
    public static void processAccountsUnsafe(List<Id> accountIds) {
        List<Account> accounts = [SELECT Id, NumberOfEmployees FROM Account WHERE Id IN :accountIds];
        
        for (Account acc : accounts) {
            acc.NumberOfEmployees = (acc.NumberOfEmployees == null ? 0 : acc.NumberOfEmployees) + 1;
        }
        
        update accounts;
    }
    
    /**
     * @description SAFE: Processing with proper locking
     * This ensures records are locked before processing
     */
    public static void processAccountsSafe(List<Id> accountIds) {
        List<Account> accounts = [
            SELECT Id, NumberOfEmployees 
            FROM Account 
            WHERE Id IN :accountIds 
            FOR UPDATE
        ];
        
        for (Account acc : accounts) {
            acc.NumberOfEmployees = (acc.NumberOfEmployees == null ? 0 : acc.NumberOfEmployees) + 1;
        }
        
        update accounts;
    }
}