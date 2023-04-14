public class UnitService {
    
    @AuraEnabled(cacheable=false)
    public static boolean validateUnit(Id unitId, Map<Id,Id> response){
        Id UserID = UserInfo.getUserId();
        Boolean unitSucces = true;
        
        // Isertar o actualizar en la tabla user unit el registro de la unidad
        // Se trae de la base de datos la unidad en la que está resolviendo preguntas el Usuario
        Unit__c unit = [SELECT Id,
                        	Name,
                        	Score__c,
                        	Module__c
                       FROM Unit__c
                       WHERE Id =: unitId];
        
        
        //Crear modulo en progreso sí no existe
        List<User_Module__c> userModule = [SELECT Id,
                                           Name,
                                           Progress__c,
                                           Status__c,
                                           Check__c
                                          FROM User_Module__c
                                          WHERE User__c =: UserId //UserInfo.getUserId()
                                          AND Module__c =: unit.Module__c];
        if(userModule.Size() == 0){
			User_Module__c umToCreate = new User_Module__c();
            umToCreate.Module__c = unit.Module__c;
            umToCreate.User__c = userId; //UserInfo.getUserId();
            umToCreate.Name = 'Module'; 
            umToCreate.Status__c = 'In progress';
            insert umToCreate;
            
            userModule.Add(umToCreate);
        } 
        
        //Se trae de la base de datos los campos donde se debe insertar o actualizar la información traida del front 
        //para el usuario logueado, la data se guarda en 'User_Unit__c'
		List<User_Unit__c> uuToUpsert = [SELECT Id,
                      		Name,
                      		User__c,
                      		Status__c,
                      		Score__c,
                      		Attempts__c,
                      		Unit__c
                     FROM User_Unit__c
                     WHERE User__c =: UserID//UserInfo.getUserId()
                     AND Unit__c =: unitId];
        
        //Si no hay nada dentro de la búsqueda, se inserta el registro por primera vez y se agrega el estado de 'Draft'
        if(uuToUpsert.Size() == 0){
            User_Unit__c uuToCreate = new User_Unit__c();
            uuToCreate.Name = unit.Name;
            uuToCreate.User__c = UserID;// UserInfo.getUserId();
            uuToCreate.Status__c ='Draft';
            uuToCreate.Score__c = 0;
            uuToCreate.Attempts__c = 1;
            uuToCreate.Unit__c = unit.Id;
            uuToCreate.User_Module__c = userModule[0].Id;
            insert uuToCreate;
            
            uuToUpsert.Add(uuToCreate);
            //Se inserta a una lista de Respuestas de usuario el valor de la pregunta/Respuesta traidas por parametro desde el front
            List<User_Response__c> uResponse = new List<User_Response__c>();
            for(Id key : response.KeySet()){
                User_Response__c u = new User_Response__c();
                u.Answer__c = response.get(key);
                u.Question__c = key;
                u.Unit_User__c = uuToUpsert[0].Id;
                uResponse.add(u);
            }
            insert uResponse;
            
        } //Si el usuario ya tiene registrada esa unidad se actualiza el estado y las nuevas respuestas traidas del front
        else{
            uuToUpsert[0].Status__c ='Draft';
            update uuToUpsert;
            List<User_Response__c> storedResponses = [SELECT Id,
                                                      		Answer__c,
                                                      		Question__c,
                                                      		Unit_User__c
                                                      FROM User_Response__c
                                                     WHERE Unit_User__c =: uuToUpsert[0].Id ];
            
            for(Integer i=0 ; i<storedResponses.size() ; i++){
                storedResponses[i].Answer__c = response.get(storedResponses[i].Question__c);
            }
            update storedResponses;
            
        }
        //Se dispara el trigger con el cambio de estado
        uuToUpsert[0].Status__c = 'Answered';
        update uuToUpsert;
        //Después de dispararse el trigger se vuelve a consultar la información del User_Unit para comprobar el ESTADO.
        User_Unit__c uuValidate = [SELECT Id,
                      		Name,
                      		User__c,
                      		Status__c,
                      		Score__c,
                      		Attempts__c,
                      		Unit__c
                     FROM User_Unit__c
                     WHERE Id =: uuToUpsert[0].Id];
        
        //Dependiendo del estado retornado por el trigger, se retorna que la respuesta fue verdadera o falsa
        if(uuValidate.Status__c == 'Success'){
            unitSucces = True; 
            
        } else if(uuValidate.Status__c == 'Fail'){
            unitSucces = False; 
        }
        return unitSucces;        
    }
    
    @AuraEnabled(cacheable=true)
    public static TrailWrapper getTrailWrapper(Id trailId){
     	
        TrailWrapper trailSummary = new TrailWrapper();
        Id userId = UserInfo.getUserId();
        
        // Se busca la información del trail
        Trail__c trailData = [SELECT Id, 
                              		Name,
                              		Description__c,
                              		Total_Score__c,
                                    Total_Time__c
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