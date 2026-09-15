public class InventoryManager {
    
    /**
     * @description UNSAFE - Reserves inventory without proper locking
     * This method is vulnerable to race conditions
     */
    public static Boolean reserveInventoryUnsafe(Id productId, Decimal quantityToReserve) {
        // STEP 1: Read current inventory (NO LOCK)
        Product2 product = [
            SELECT Id, QuantityOnHand__c 
            FROM Product2 
            WHERE Id = :productId
            LIMIT 1
        ];
        
        // Simulate processing time (in real scenarios, this could be business logic)
        // During this time, another transaction might read the same record
        Integer dummyCounter = 0;
        for (Integer i = 0; i < 1000; i++) {
            dummyCounter += i;
        }
        
        // STEP 2: Check if enough inventory exists
        if (product.QuantityOnHand__c >= quantityToReserve) {
            // STEP 3: Calculate new quantity
            product.QuantityOnHand__c -= quantityToReserve;
            
            // STEP 4: Update without lock (RACE CONDITION HERE!)
            update product;
            
            System.debug('Reserved ' + quantityToReserve + ' units. New quantity: ' + product.QuantityOnHand__c);
            return true;
        }
        
        return false;
    }
     public static void simulateConcurrentOrders(Id productId) {
        // This would be called from different transactions/contexts
        reserveInventoryUnsafe(productId, 10);
    }
}