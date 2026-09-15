@isTest
public class CaseTriggerHandlerTest {
     
    @isTest(SeeAllData=true)
    static void testInsertCaseNames() {
        // Arrange
        List<Case> casesToInsert = new List<Case>{
            new Case(Status = 'New', Priority = 'Medium'),
            new Case(Status = 'New', Priority = 'Medium', Subject = null),
            new Case(Status = 'New', Priority = 'Medium', Subject = '')
        };
        
        // Act
        Test.startTest();
        CaseTriggerHandler.insertCaseNames(casesToInsert);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCaseStatus() { 
        // Arrange
        Case oldCase = new Case(Status = 'New', Priority = 'Low');
        insert oldCase; // Insert the old case to reference
        
        // Creating a new case that reflects the updated values
        Case updatedCase = new Case(Id = oldCase.Id, Status = 'New', Priority = 'High');
        
        // Creating a map of old cases for the update method
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{
            oldCase.Id => oldCase
        };
        
        // Act
        Test.startTest();
        CaseTriggerHandler.updateCaseStatus(new List<Case>{updatedCase}, oldCaseMap);
        Test.stopTest();
        
        // Assert 
        System.assertEquals('Escalated', updatedCase.Status, 'Status should be updated to Escalated for High priority.');
       
        
        // Assert for unchanged priority
        System.assertEquals('Escalated', updatedCase.Status, 'Status should remain In Progress for Medium priority.');
  
    }
}