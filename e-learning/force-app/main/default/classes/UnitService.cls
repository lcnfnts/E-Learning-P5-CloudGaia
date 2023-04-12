public class UnitService {
    
    public static boolean user_unit_register(Id uId, String strJs){
        // Se insertan registros para completar  el objeto "User Unit"
        Unit__c uResponse = [SELECT Module__c,
                                 (SELECT Id, Name 
                                  FROM Questions__r) 
                             FROM Unit__c 
                             WHERE Id =:uId];  
        
        User_Module__c userModule = NULL;
        //Se trajo el Id de User Module
        userModule = [SELECT Id
                        FROM User_Module__c
                        WHERE User__c =:UserInfo.getUserId() 
                      	AND Module__c =:uResponse.Module__c];
        
        if(userModule == NULL){
			userModule = new User_Module__c(Module__c = uResponse.Module__c, 
                                            User__c = UserInfo.getUserId(), 
                                            Status__c = 'In Progress');    
            insert userModule;
        }	
        // Seleccionar el número de intentos de una unidad específica y el usuario logueado
        List<User_Unit__c> listUserUnit =[SELECT Id, 
                                          	Attempts__c 
                                          FROM User_Unit__c 
                                          WHERE User__c =:UserInfo.getUserId() 
                                          AND Unit__c =:uId];
        // Guardamos en numero de la mayor cantidad de intentos en max Attempt
        Integer maxAttempt = -1;
        if(!listUserUnit.isEmpty()){
            for(User_Unit__c userU : listUserUnit){
            	if(userU.Attempts__c > maxAttempt){
                	maxAttempt = userU.Attempts__c.intValue();
            	}
        	}
        }
        
        
        //insertar Usuario_Unidad
        User_Unit__c uInsert = new User_Unit__c(User_Module__c = userModule.id, 
                                                User__c = UserInfo.getUserId(), 
                                                Status__c = 'Draft');
        
        if(!(maxAttempt == -1)){
            uInsert.Attempts__c = maxAttempt + 1;
        } else {
            uInsert.Attempts__c = 1;
        }
        
		insert uInsert;
        
        List <User_Response__c> responseList = new List<User_Response__c>();
        
        Map<Id,Id> p_r_Map = (Map<Id,Id>)JSON.deserialize(strJs,Map<Id,Id>.class);
        
        for(Question__c pr : uResponse.Questions__r){	
            User_Response__c response = new User_Response__c(Answer__c = p_r_Map.get(pr.Id),
                                                              Unit_User__c = uInsert.Id,
                                                              Question__c = pr.Id);
            responseList.add(response);
        }
        insert responseList;
        
        uInsert.Status__c = 'Answered';
        
        update uInsert;
        
        return true;  
    }
    //cambié el nombre de este método
    @AuraEnabled(cacheable=true)
    public static TrailWrapper getTrailWrapper(Id trailId){
     	
        TrailWrapper trailSummary = new TrailWrapper();
        Id userId = '005Dp000001ZyXNIA0';
        
        // Se busca la información del trail
        Trail__c trailData = [SELECT Id, 
                              		Name,
                              		Total_Time__c,
                             		Total_Score__c,
                              		Description__c
                             FROM Trail__c
                             WHERE Id =: trailId];
        
        //Se obtienen los ID de los modulos que pertenecen al trail
        List<Id> modulesIds = new List<Id>();
        for(Trail_Module__c module : [SELECT Id, Module__c FROM Trail_Module__c where Trail__r.Id =: trailId])
        {
            modulesIds.add(module.Module__c);
        }
        System.debug('Encuentra Trail ' +  trailData.Id);
        System.debug('Cantidad modulos ' +  modulesIds.size());
        
        //Se obtienen los modulos del trail asignados al usuario
     	List<User_Module__c> modulesData = [SELECT Id,
                                           Module__c,
                                           User__c,
                                           Check__c
                                     FROM User_Module__c
                                     WHERE User__r.Id =:userId//UserInfo.getUserId() 
                                     AND Module__c IN: modulesIds];
        
        //Se filtran los modulos finalizados para agregarlos a passedModuleIds
        Integer modulosRealizados = 0;
        List<Id> passedModuleIds = new List<Id>();
        for(User_Module__c userModule : modulesData)
        {
            if (userModule.Check__c)
            {
                modulosRealizados++;
                passedModuleIds.add(userModule.Module__c);
            }
        }
        
        List<Module__c> modulosEnTrail = [SELECT Id,
                                          		Name,
                                          		Score__c,
                                          		Time__c      
                                         FROM Module__c 
                                         WHERE Id IN: modulesIds];
        
        //Se asignan los datos a trailSummary
        System.debug('modulos registrados ' +  modulesData.size());
        trailSummary.modules = modulosEnTrail;
        trailSummary.trail = trailData;
        trailSummary.progressTrail = (modulosRealizados * 100) / (modulesData.size() > 0 ? modulesData.size() : 1);
        trailSummary.passedModuleIds = passedModuleIds;
        System.debug('Progreso ' +  trailSummary.progressTrail);
        return trailSummary;
    }
    
    @AuraEnabled(cacheable=true)
    public static unitWrapper getUnitWrapper(Id unitId){
        
        unitWrapper unitSummary = new unitWrapper();
        Unit__c unit = [SELECT Id,
                        		Name,
                        		Content__c,
                                Time__c,
                                Score__c
                       FROM Unit__c
                       WHERE Id =: unitId];
        System.debug('Agregró unidad ' + unit.Name);
        
        List<Question__c> questions = [SELECT Id,
                                       		Name,
                                       		Content__c
                                      FROM Question__c
                                      WHERE Unit__c =: unitId];
        System.debug('Total preguntas ' +  questions.size());
        
        List<Answer__c> answers = [SELECT Name,
                                   Is_correct__c,
                                   Response_Content__c,
                                   Question__c
                                  FROM Answer__c
                                   WHERE Question__c IN:questions ];
        System.debug('Total de respuestas ' +  answers.size());
        
        Map<Id, List<Answer__c>> mapAnswer = new Map<Id, List<Answer__c>>(); 
        for(Question__c q : questions){
            List<Answer__c> qAnswer = new List<Answer__c>();
            
            for(Answer__c a : answers){
                if(a.Question__c == q.Id){
                    qAnswer.add(a);
                }
            }
            mapAnswer.put(q.Id, qAnswer);
        }
        unitSummary.unit = unit;
        unitSummary.questions = questions;
        unitSummary.answers = mapAnswer;
        return unitSummary;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Unit__c> getUnitList(Id moduleId){
        List<Unit__c> unitL = [SELECT Id,
                               		Name,
                               		Time__c,
                               		Score__c
                              FROM Unit__c
                              WHERE Module__c =:moduleId];
        return unitL;
    }
}