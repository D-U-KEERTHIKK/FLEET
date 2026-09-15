global class MyObjectSharingRecalc implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM DemoOverrideObject__c]);
    }
    global void execute(Database.BatchableContext bc, List<DemoOverrideObject__c> scope) {
        // Recalculate sharing for records in scope
    }
    global void finish(Database.BatchableContext bc) {}
}