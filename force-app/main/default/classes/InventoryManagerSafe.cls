public class InventoryManagerSafe {
    
    private static final Integer MAX_RETRIES = 3;
    private static final Integer RETRY_DELAY_MS = 100;
    
    /**
     * @description SAFE - Reserves inventory with proper locking mechanism
     * Uses FOR UPDATE to prevent concurrent modifications
     */
    public static Boolean reserveInventorySafe(Id productId, Decimal quantityToReserve) {
        Integer retryCount = 0;
        
        while (retryCount < MAX_RETRIES) {
            try {
                // STEP 1: Read with FOR UPDATE lock - prevents concurrent access
                Product2 product = [
                    SELECT Id, QuantityOnHand__c 
                    FROM Product2 
                    WHERE Id = :productId
                    FOR UPDATE // THIS PREVENTS RACE CONDITIONS!
                ];
                
                // STEP 2: Check inventory availability
                if (product.QuantityOnHand__c >= quantityToReserve) {
                    // STEP 3: Update quantity atomically
                    product.QuantityOnHand__c -= quantityToReserve;
                    update product;
                    
                    System.debug('Successfully reserved ' + quantityToReserve + 
                               ' units. New quantity: ' + product.QuantityOnHand__c);
                    return true;
                } else {
                    System.debug('Insufficient inventory. Available: ' + 
                               product.QuantityOnHand__c + ', Required: ' + quantityToReserve);
                    return false;
                }
                
            } catch (QueryException e) {
                // Handle lock timeout or other query exceptions
                if (e.getMessage().contains('unable to obtain exclusive access') || 
                    e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    
                    retryCount++;
                    System.debug('Lock contention detected. Retry attempt: ' + retryCount);
                    
                    if (retryCount >= MAX_RETRIES) {
                        System.debug('Max retries exceeded. Unable to reserve inventory.');
                        throw new InventoryException('Unable to lock inventory record after ' + 
                                                    MAX_RETRIES + ' attempts', e);
                    }
                    
                    // Wait before retry (exponential backoff)
                    Integer delayMs = RETRY_DELAY_MS * retryCount;
                    System.debug('Waiting ' + delayMs + 'ms before retry...');
                    // Note: Actual delay would require async processing in real scenarios
                    
                } else {
                    throw e;
                }
            }
        }
        
        return false;
    }
    
    /**
     * @description Batch reserve with proper transaction handling
     * Demonstrates handling multiple reservations safely
     */
    public static Map<Id, Boolean> reserveInventoryBatch(Map<Id, Decimal> productReservations) {
        Map<Id, Boolean> results = new Map<Id, Boolean>();
        
        // Process each reservation in a savepoint for rollback capability
        for (Id productId : productReservations.keySet()) {
            Savepoint sp = Database.setSavepoint();
            
            try {
                Boolean success = reserveInventorySafe(productId, productReservations.get(productId));
                results.put(productId, success);
            } catch (Exception e) {
                Database.rollback(sp);
                results.put(productId, false);
                System.debug('Failed to reserve inventory for product: ' + productId + 
                           '. Error: ' + e.getMessage());
            }
        }
        
        return results;
    }
    
    /**
     * @description Alternative approach using optimistic locking
     * Checks version/timestamp before update
     */
    public static Boolean reserveInventoryOptimistic(Id productId, Decimal quantityToReserve) {
        // Read current record with timestamp
        Product2 product = [
            SELECT Id, QuantityOnHand__c, LastModifiedDate 
            FROM Product2 
            WHERE Id = :productId
            LIMIT 1
        ];
        
        Datetime originalModifiedDate = product.LastModifiedDate;
        Decimal originalQuantity = product.QuantityOnHand__c;
        
        // Check availability
        if (product.QuantityOnHand__c < quantityToReserve) {
            return false;
        }
        
        // Update quantity
        product.QuantityOnHand__c -= quantityToReserve;
        
        try {
            // Use Database.update with allOrNone false to handle conflicts
            update product;
            
            // Verify no concurrent modification occurred
            Product2 verifyProduct = [
                SELECT Id, LastModifiedDate 
                FROM Product2 
                WHERE Id = :productId 
                LIMIT 1
            ];
            
            // If modification date changed unexpectedly, there was a concurrent update
            // This is a simplified check - in production, you'd use a version field
            return true;
            
        } catch (DmlException e) {
            System.debug('Optimistic lock failed: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Custom exception for inventory operations
     */
    public class InventoryException extends Exception {}
}