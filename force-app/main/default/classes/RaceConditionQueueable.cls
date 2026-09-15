/**
 * @description Demonstrates race conditions using Queueable Apex
 * Multiple queueables updating the same record will cause concurrency issues
 * 
 * HOW TO ENCOUNTER THE RACE CONDITION:
 * 1. Run: RaceConditionQueueable.triggerMultipleQueueables(accountId);
 * 2. Multiple jobs will run in parallel
 * 3. They'll all try to update the same Account
 * 4. RESULT: Lost updates or UNABLE_TO_LOCK_ROW errors!
 */
public class RaceConditionQueueable implements Queueable {
    
    private Id accountId;
    private Decimal amountToDeduct;
    private Boolean useLock;
    private String jobName;
    
    public RaceConditionQueueable(Id accountId, Decimal amountToDeduct, Boolean useLock, String jobName) {
        this.accountId = accountId;
        this.amountToDeduct = amountToDeduct;
        this.useLock = useLock;
        this.jobName = jobName;
    }
    
    public void execute(QueueableContext context) {
        System.debug('=== ' + jobName + ' STARTED ===');
        
        try {
            if (useLock) {
                processWithLock();
            } else {
                processWithoutLock();
            }
            
            System.debug('=== ' + jobName + ' COMPLETED SUCCESSFULLY ===');
            
        } catch (Exception e) {
            System.debug('=== ' + jobName + ' FAILED: ' + e.getMessage() + ' ===');
        }
    }
    
    /**
     * UNSAFE: Process without lock - RACE CONDITION!
     */
    private void processWithoutLock() {
        // Read account without lock
        Account acc = [
            SELECT Id, Name, AnnualRevenue 
            FROM Account 
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        Decimal before = acc.AnnualRevenue != null ? acc.AnnualRevenue : 0;
        
        System.debug(jobName + ': Read balance = ' + before);
        
        // Simulate some processing time to increase race condition likelihood
        Integer dummy = 0;
        for (Integer i = 0; i < 10000; i++) {
            dummy += i;
        }
        
        // Deduct amount
        acc.AnnualRevenue = before - amountToDeduct;
        
        System.debug(jobName + ': Updating balance from ' + before + ' to ' + acc.AnnualRevenue);
        
        // Update without lock - OTHER QUEUEABLES MIGHT BE DOING THIS TOO!
        update acc;
        
        System.debug(jobName + ': Update complete');
    }
    
    /**
     * SAFE: Process with lock
     */
    private void processWithLock() {
        // Read with FOR UPDATE - locks the record
        Account acc = [
            SELECT Id, Name, AnnualRevenue 
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
            FOR UPDATE
        ];
        
        Decimal before = acc.AnnualRevenue != null ? acc.AnnualRevenue : 0;
        
        System.debug(jobName + ': Acquired lock. Balance = ' + before);
        
        // Simulate processing
        Integer dummy = 0;
        for (Integer i = 0; i < 10000; i++) {
            dummy += i;
        }
        
        // Deduct amount
        acc.AnnualRevenue = before - amountToDeduct;
        
        System.debug(jobName + ': Updating balance from ' + before + ' to ' + acc.AnnualRevenue);
        
        update acc;
        
        System.debug(jobName + ': Update complete with lock');
    }
    
    /**
     * @description Trigger multiple queueables to create race condition
     * This will cause REAL concurrency issues!
     */
    public static List<Id> triggerMultipleQueueables(Id accountId, Boolean useLock) {
        List<Id> jobIds = new List<Id>();
        
        System.debug('========================================');
        System.debug('STARTING MULTIPLE QUEUEABLES');
        System.debug('Account: ' + accountId);
        System.debug('Using Lock: ' + useLock);
        System.debug('========================================');
        
        // Queue 5 jobs that will run in parallel
        jobIds.add(System.enqueueJob(new RaceConditionQueueable(accountId, 100, useLock, 'Job-1')));
        jobIds.add(System.enqueueJob(new RaceConditionQueueable(accountId, 150, useLock, 'Job-2')));
        jobIds.add(System.enqueueJob(new RaceConditionQueueable(accountId, 200, useLock, 'Job-3')));
        jobIds.add(System.enqueueJob(new RaceConditionQueueable(accountId, 75, useLock, 'Job-4')));
        jobIds.add(System.enqueueJob(new RaceConditionQueueable(accountId, 125, useLock, 'Job-5')));
        
        System.debug('Queued ' + jobIds.size() + ' jobs');
        System.debug('Expected total deduction: 650');
        System.debug('Check the account balance after all jobs complete!');
        
        return jobIds;
    }
    
    /**
     * @description Check the results of concurrent execution
     */
    public static void checkResults(Id accountId, Decimal originalBalance) {
        Account acc = [SELECT Id, Name, AnnualRevenue FROM Account WHERE Id = :accountId];
        
        Decimal expectedBalance = originalBalance - 650; // Total of all deductions
        Decimal actualBalance = acc.AnnualRevenue != null ? acc.AnnualRevenue : 0;
        
        System.debug('========================================');
        System.debug('RESULTS:');
        System.debug('Original Balance: ' + originalBalance);
        System.debug('Expected Balance: ' + expectedBalance);
        System.debug('Actual Balance: ' + actualBalance);
        System.debug('Difference: ' + (actualBalance - expectedBalance));
        
        if (actualBalance != expectedBalance) {
            System.debug('⚠️ RACE CONDITION DETECTED! Lost update of ' + (actualBalance - expectedBalance));
        } else {
            System.debug('✓ All updates applied correctly (FOR UPDATE used)');
        }
        System.debug('========================================');
    }
}