public inherited sharing class ProductCreationController {
    /**
     * Returns distinct non-null Product Family values from existing Product2 records.
     * Useful for populating a picklist in the UI.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getProductFamilies() {
        Set<String> fams = new Set<String>();
        for (AggregateResult ar : [
            SELECT Family fam
            FROM Product2
            WHERE Family != null
            GROUP BY Family
            ORDER BY Family
        ]) {
            fams.add((String) ar.get('fam'));
        }
        return new List<String>(fams);
    }

    /**
     * Creates a single Product2 record with provided field values.
     * Returns the Id of the created Product2.
     */
    @AuraEnabled
    public static Id createProduct(String name, String productCode, String family, String description, Boolean isActive) {
        if (String.isBlank(name)) {
            throw new AuraHandledException('Name is required.');
        }
        // ProductCode may be required by org policy/validation; enforce if desired
        if (String.isBlank(productCode)) {
            throw new AuraHandledException('Product Code is required.');
        }
        // Default IsActive to true if not provided by client
        Boolean active = (isActive == null) ? true : isActive;

        Product2 p = new Product2();
        p.Name = name.trim();
        p.ProductCode = productCode.trim();
        p.IsActive = active;
        if (!String.isBlank(family)) {
            p.Family = family.trim();
        }
        if (!String.isBlank(description)) {
            p.Description = description.trim();
        }

        try {
            insert p;
            return p.Id;
        } catch (DmlException dmlEx) {
            // Surface the first error to LWC
            if (!dmlEx.getDmlFields(0).isEmpty()) {
                // no-op: keeping interface simple, returning combined message below
            }
            throw new AuraHandledException('Failed to create Product: ' + dmlEx.getMessage());
        }
    }
}