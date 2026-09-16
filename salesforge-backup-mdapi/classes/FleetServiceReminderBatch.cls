global class FleetServiceReminderBatch
implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        return Database.getQueryLocator(
            [
                SELECT Id,
                       VIN__c,
                       Make__c,
                       Model__c,
                       Mileage__c,
                       Status__c
                FROM Vehicle__c
                WHERE Status__c = 'Active'
                AND Mileage__c > 5000
            ]
        );
    }

    global void execute(
        Database.BatchableContext bc,
        List<SObject> scope
    ) {

        // No processing required for this example
    }

    global void finish(
        Database.BatchableContext bc
    ) {

        List<Vehicle__c> vehicles =
            FleetService.getVehiclesDueForService(5000);

        String body =
            'Vehicles Due For Service: ' +
            vehicles.size() +
            '\n\n';

        for(Vehicle__c vehicle : vehicles) {

            body +=
                vehicle.Make__c + ' ' +
                vehicle.Model__c +
                ' - Mileage: ' +
                vehicle.Mileage__c +
                '\n';
        }

        Messaging.SingleEmailMessage email =
            new Messaging.SingleEmailMessage();

        email.setToAddresses(
            new String[] {
                'fleetmanager@example.com'
            }
        );

        email.setSubject(
            'Weekly Fleet Service Reminder'
        );

        email.setPlainTextBody(body);

        Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] {
                email
            }
        );
    }

    global void execute(
        SchedulableContext sc
    ) {

        Database.executeBatch(
            new FleetServiceReminderBatch(),
            200
        );
    }
}