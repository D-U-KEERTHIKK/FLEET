public class CaseTriggerHandler { 
     
    // Method to insert Case Names if blank - Developer 1
    public static void insertCaseNames(List<Case> newCases) {
        for (Case newCase : newCases) {
            if (String.isBlank(newCase.Subject)) {
                newCase.Subject = 'Case-' + DateTime.now().format('yyyyMMddHHmmss');
            }
        }
    }
    
    // Method to update Case Status and Sub Status based on Priority - DT-1637
    public static void updateCaseStatus(List<Case> updatedCases, Map<Id, Case> oldCaseMap) {
        for (Case updatedCase : updatedCases) {
            Case oldCase = oldCaseMap.get(updatedCase.Id);
            
            // Example logic to update status and sub-status based on priority change
            if (updatedCase.Priority == 'High' && oldCase.Priority != 'High') {
                updatedCase.Status = 'Escalated';
                //updatedCase.Sub_Status__c = 'In Progress';
            } else if (updatedCase.Priority == 'Low' && oldCase.Priority != 'Low') {
                updatedCase.Status = 'In Progress';
                //updatedCase.Sub_Status__c = 'Waiting for Customer';
            } else {
                updatedCase.Status = 'In Progress';
                //updatedCase.Sub_Status__c = 'Under Review';
            }
        }
    }
}