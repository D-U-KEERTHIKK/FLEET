public class automatedContactsExtension {
     public class AutomatedContactRequest {
        @InvocableVariable(label='Contact ID' required=true)
        public Id contactId;
        
        @InvocableVariable(label='First Name')
        public String firstName;
        
        @InvocableVariable(label='Last Name')
        public String lastName;
        
        @InvocableVariable(label='Email')
        public String email;
        
        @InvocableVariable(label='Phone')
        public String phone;
        
        @InvocableVariable(label='Account ID')
        public Id accountId;
        
        @InvocableVariable(label='Enable Auto Assignment')
        public Boolean enableAutoAssignment;
        
        @InvocableVariable(label='Owner ID')
        public Id ownerId;
        
        @InvocableVariable(label='Send Welcome Email')
        public Boolean sendWelcomeEmail;
        
        @InvocableVariable(label='Email Template Name')
        public String emailTemplateName;
        
        @InvocableVariable(label='Apply Default Settings')
        public Boolean applyDefaultSettings;
    }
    
    public class AutomatedContactResponse {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public Id processedContactId;
    }
    
    @InvocableMethod(
        label='Process Automated Contact' 
        description='Processes contact with automated settings'
        category='Contact Automation'
    )
    public static List<AutomatedContactResponse> processAutomatedContact(List<AutomatedContactRequest> requests) {
        List<AutomatedContactResponse> responses = new List<AutomatedContactResponse>();
        
        for (AutomatedContactRequest request : requests) {
            AutomatedContactResponse response = new AutomatedContactResponse();
            
            // Mock implementation - just return success
            response.success = true;
            response.message = 'Contact processed successfully';
            response.processedContactId = request.contactId;
            
            responses.add(response);
        }
        
        return responses;
    }

}