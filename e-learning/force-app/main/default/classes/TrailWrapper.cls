public class TrailWrapper {
	@AuraEnabled public Trail__c trail;
    
    @AuraEnabled public Integer progressTrail;
    
    @AuraEnabled public List<Module__c> modules;
    
    @AuraEnabled public List<Id> passedModuleIds;
    
    Set<Id> passedUnitIds;
}