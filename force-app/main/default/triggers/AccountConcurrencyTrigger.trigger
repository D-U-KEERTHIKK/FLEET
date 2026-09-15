trigger AccountConcurrencyTrigger on Account (before update, after update) {
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Simulate some processing time to increase chance of race condition
        Integer dummyCounter = 0;
        for (Integer i = 0; i < 5000; i++) {
            dummyCounter += i;
        }
        
        System.debug('AccountConcurrencyTrigger: Processing ' + Trigger.new.size() + ' accounts');
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        for (Account acc : Trigger.new) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            
            if (acc.AnnualRevenue != oldAcc.AnnualRevenue) {
                System.debug('Account ' + acc.Name + ' - Revenue changed from ' + 
                           oldAcc.AnnualRevenue + ' to ' + acc.AnnualRevenue);
            }
        }
    }
}