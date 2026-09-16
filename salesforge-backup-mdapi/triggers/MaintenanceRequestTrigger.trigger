trigger MaintenanceRequestTrigger on Maintenance_Request__c (before insert) {

    Set<Id> vehicleIds = new Set<Id>();

    for(Maintenance_Request__c req : Trigger.new){
        if(req.Priority__c == 'Urgent' &&
           req.Vehicle__c != null){
            vehicleIds.add(req.Vehicle__c);
        }
    }

    if(vehicleIds.isEmpty()){
        return;
    }

    List<Vehicle__c> vehiclesToUpdate = [
        SELECT Id, Status__c
        FROM Vehicle__c
        WHERE Id IN :vehicleIds
    ];

    for(Vehicle__c v : vehiclesToUpdate){
        v.Status__c = 'In Maintenance';
    }

    update vehiclesToUpdate;
}