public class unitWrapper {
    
    @AuraEnabled public Unit__c unit;
	
    @AuraEnabled public List<Question__c> questions;
    
    @AuraEnabled public Map<Id, List<Answer__c>> answers;
    
}