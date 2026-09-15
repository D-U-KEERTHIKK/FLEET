trigger AccountTrigger on Account (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccountHandler.handleInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AccountHandler.handleUpdate(Trigger.new, Trigger.old);
        }
    }
}