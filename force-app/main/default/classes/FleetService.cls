public with sharing class FleetService {

    public static List<Vehicle__c> getVehiclesDueForService(
        Integer mileageThreshold
    ) {

        return [
            SELECT Id,
                   VIN__c,
                   Make__c,
                   Model__c,
                   Mileage__c,
                   Status__c,
                   Last_Service_Date__c
            FROM Vehicle__c
            WHERE Status__c = 'Active'
            AND Mileage__c > :mileageThreshold
        ];
    }
}