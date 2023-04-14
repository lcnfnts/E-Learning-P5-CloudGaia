trigger validateUnitTrigger on User_Unit__c (after update) {
	
    for(Integer i=0; i<Trigger.new.size() ; i++){
        if(Trigger.old[i].Status__c == 'Draft' && Trigger.new[i].Status__c == 'Answered'){
        	//Traer la informacion de Preguntas y resúestas con elUSER UNIT
        	//hacer for recorriendo las repsuestas y preguntas y hago un mapa
        	List<User_Response__c> unitR= [SELECT Id,
                                            Question__c,
                                            Answer__c
                                     FROM User_Response__c
                                    WHERE Unit_User__c =: Trigger.new[i].Id];
            
            Map<Id,Id> response = new Map<Id,Id>();
            Boolean unitSuccess = true;
            
            
            for(User_Response__c ur :  unitR){
                response.put(ur.Question__c , ur.Answer__c);
            }
            
            
            List<Id> questionsIds = new List<Id>();
            
            for(Id key : response.keySet()){
                questionsIds.add(key);   
            }
            
            List<Answer__c> answerData = [SELECT Id,
                                            Is_correct__c,
                                            Question__c
                                           FROM Answer__c
                                           WHERE Is_correct__c =: true AND 
                                          Question__c IN: questionsIds];
            
            System.debug('Existe answerData: ' + answerData.size());
            
            for(Id key : response.keySet()){
                
                for(Answer__c answ : answerData){
                    if(key == answ.Question__c){
                        if(response.get(key) != answ.Id){
                            System.debug('entra a primer for '+ response.get(key) + ' - '+ answ.Id);
                            
                           unitSuccess = false;
                        }
                    }
                }
            }
            User_Unit__c uu = [SELECT Id,
                               		Status__c
                              FROM User_Unit__c
                              WHERE Id =: Trigger.new[i].Id];
            
            if(unitSuccess == true){
                uu.Status__c = 'Success';
            } else {
                uu.Status__c = 'Fail';
            }
            update uu;
        }
    }
}