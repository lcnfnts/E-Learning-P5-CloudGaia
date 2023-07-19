trigger addScoreToTrailTrigger on Trail_Module__c (after insert, after update, after delete) {
	
    //con el trailmodule que se inserta usar el ID del trail en la misma tabla para obtener todos los moduls asociados
    //y cargar sus IDs a una lista de IDs
    for(Trail_Module__c tm : Trigger.new){
        
        List<Trail_Module__c> trailModule = [SELECT Id,
                                                Trail__c,
                                                Module__c
                                          FROM Trail_Module__c
                                          WHERE Trail__c =: tm.Trail__c];
        
        List<Id> modulesId = new List<Id>();
        for(Trail_Module__c t : trailModule){
            modulesId.add(t.Module__c);
        }
        
        List<Module__c> module = [SELECT Id,
                                    Score__c,
                                  	Time__c
                            FROM Module__c
                            WHERE Id IN: modulesId];
        
        Trail__c trail = [SELECT Id,
                                	Total_Score__c,
                          			Total_Time__c
                               FROM Trail__c
                               WHERE Id =: tm.Trail__c];
        
        Decimal score = 0;
        Decimal totalTime = 0;
        
        for(Module__c m : module){
            score += m.Score__c;
            totalTime += m.Time__c;
        }
        
        trail.Total_Score__c = score;
        trail.Total_Time__c = totalTime;
        update trail;
    }
}