@IsTest
private class FleetServiceTest {

    private static Vehicle__c createVehicle(
        String vin,
        Integer mileage,
        String status
    ) {

        Vehicle__c vehicle = new Vehicle__c(
            VIN__c = vin,
            Make__c = 'Toyota',
            Model__c = 'Camry',
            Mileage__c = mileage,
            Status__c = status
        );

        insert vehicle;

        return vehicle;
    }

    @IsTest
    static void testMileageValidationRule() {

        System.Test.startTest();

        Vehicle__c vehicle = new Vehicle__c(
            VIN__c = '12345678901234567',
            Make__c = 'Ford',
            Model__c = 'F150',
            Mileage__c = -100,
            Status__c = 'Active'
        );

        Database.SaveResult result =
            Database.insert(vehicle, false);

        System.Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess()
        );

        System.assert(
            result.getErrors()[0]
                  .getMessage()
                  .contains('Mileage')
        );
    }

    @IsTest
    static void testUrgentDescriptionValidation() {

        Vehicle__c vehicle =
            createVehicle(
                'VIN00000000000001',
                1000,
                'Active'
            );

        Maintenance_Request__c request =
            new Maintenance_Request__c(
                Vehicle__c = vehicle.Id,
                Priority__c = 'Urgent'
            );

        Database.SaveResult result =
            Database.insert(request, false);

        System.assertEquals(
            false,
            result.isSuccess()
        );
    }

    @IsTest
    static void testUrgentTriggerSingleRecord() {

        Vehicle__c vehicle =
            createVehicle(
                'VIN00000000000002',
                1000,
                'Active'
            );

        insert new Maintenance_Request__c(
            Vehicle__c = vehicle.Id,
            Priority__c = 'Urgent',
            Issue_Description__c = 'Brake failure'
        );

        Vehicle__c updatedVehicle =
            [
                SELECT Status__c
                FROM Vehicle__c
                WHERE Id = :vehicle.Id
            ];

        System.assertEquals(
            'In Maintenance',
            updatedVehicle.Status__c
        );
    }

    @IsTest
    static void testUrgentTriggerBulk() {

        Vehicle__c vehicle1 =
            createVehicle(
                'VIN00000000000003',
                2000,
                'Active'
            );

        Vehicle__c vehicle2 =
            createVehicle(
                'VIN00000000000004',
                3000,
                'Active'
            );

        List<Maintenance_Request__c> requests =
            new List<Maintenance_Request__c>{

                new Maintenance_Request__c(
                    Vehicle__c = vehicle1.Id,
                    Priority__c = 'Urgent',
                    Issue_Description__c = 'Engine issue'
                ),

                new Maintenance_Request__c(
                    Vehicle__c = vehicle2.Id,
                    Priority__c = 'Urgent',
                    Issue_Description__c = 'Transmission issue'
                )
            };

        insert requests;

        Map<Id, Vehicle__c> vehicles =
            new Map<Id, Vehicle__c>(
                [
                    SELECT Status__c
                    FROM Vehicle__c
                    WHERE Id IN :new Set<Id>{
                        vehicle1.Id,
                        vehicle2.Id
                    }
                ]
            );

        System.assertEquals(
            'In Maintenance',
            vehicles.get(vehicle1.Id).Status__c
        );

        System.assertEquals(
            'In Maintenance',
            vehicles.get(vehicle2.Id).Status__c
        );
    }

    @IsTest
    static void testFleetServiceQuery() {

        createVehicle(
            'VIN00000000000005',
            10000,
            'Active'
        );

        createVehicle(
            'VIN00000000000006',
            1000,
            'Active'
        );

        List<Vehicle__c> vehicles =
            FleetService.getVehiclesDueForService(
                5000
            );

        System.assertEquals(
            1,
            vehicles.size()
        );

        System.assert(
            vehicles[0].Mileage__c > 5000
        );
    }

    @IsTest
    static void testBatchQueryLogic() {

        createVehicle(
            'VIN00000000000007',
            8000,
            'Active'
        );

        createVehicle(
            'VIN00000000000008',
            2000,
            'Active'
        );

        List<Vehicle__c> dueVehicles =
            FleetService.getVehiclesDueForService(
                5000
            );

        System.assertEquals(
            1,
            dueVehicles.size()
        );
    }
}