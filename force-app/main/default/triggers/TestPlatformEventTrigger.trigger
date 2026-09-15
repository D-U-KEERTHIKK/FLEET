trigger TestPlatformEventTrigger on Test_PlatformEvent__e (after insert) {
	List<DemoOverrideObject__c> objectsToInsert = new List<DemoOverrideObject__c>();
    
    for (Test_PlatformEvent__e event : Trigger.New) {
        DemoOverrideObject__c obj = new DemoOverrideObject__c(
            Name = event.Name__c // Copy from event field
        );
        objectsToInsert.add(obj);
    }
    
    if (!objectsToInsert.isEmpty()) {
        insert objectsToInsert; // DML under trigger context
    }
}