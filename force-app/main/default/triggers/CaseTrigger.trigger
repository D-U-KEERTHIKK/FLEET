trigger CaseTrigger on Case (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.insertCaseNames(Trigger.new);
        }
        if (Trigger.isUpdate) {
            CaseTriggerHandler.updateCaseStatus(Trigger.new, Trigger.oldMap);
        }
    } 
}