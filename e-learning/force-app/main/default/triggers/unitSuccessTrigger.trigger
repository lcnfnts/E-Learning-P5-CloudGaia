trigger unitSuccessTrigger on User_Unit__c (after update) {

    for(User_Unit__c uu : Trigger.new){
        if (uu.Status__c == 'Success')
        {
            Boolean moduleFinished = true;
            Decimal moduleTotalScore = 0;
            
            // Consultar las unidades registradas por el estudiante 
            List<User_Unit__c> uUnits = [SELECT 
                                        Id,
                                        Status__c,
                                        Score__c,
                                        User_Module__c,
                                        Unit__c
                                        FROM User_Unit__c
                                        WHERE User_Module__c =: uu.User_Module__c];
            
            //Consultar la informacion del modulo al que pertenecen las unidades que esta realizando el estudiante
            User_Module__c uModule = [SELECT
                        	Id,
                            Module__c,
                            Status__c,
                            Score__c,
                            Progress__c,
                            Check__c
                        FROM User_Module__c
                        WHERE Id =: uUnits[0].User_Module__c ];
            
            //Se consulta el Score de cada unidad perteneciente al módulo 
            List<Unit__c> units = [SELECT
                                  Id,
                                  Score__c
                                  FROM Unit__c
                                  WHERE Module__c =: uModule.Module__c];
            
            //Se recorre cada unidad perteneciente al modulo, se evalua que se encuentra exitosa y se almacena su score
            for(Unit__c unit : units)
            {
                Boolean unitCompleted = false;
                
                for(User_Unit__c uUnit : uUnits)
                {
                    if (unit.Id == uUnit.Unit__c && uUnit.Status__c == 'Success')
                    {
                        moduleTotalScore += unit.Score__c;
                        unitCompleted = true;
                    }
                }
                
                //Si la unidad validada no ha sido resuelta exitosamente por el estudiante se depermina que el modulo no ha sido finalizado
                if (unitCompleted == false)
                {
                    moduleFinished = false;
                }
            }
            
            //Si el modulo fue completado se cambia el estado a completed
            if (moduleFinished == true)
            {
                /*User_Module__c um = [SELECT 
                                     Id,
                                     Status__c,
                                     Score__c,
                                     Progress__c,
                                     Check__c
                            FROM User_Module__c
                            where Id =: uu.User_Module__c];*/
                
                uModule.Status__c = 'Completed';
                uModule.Check__c = true;
                update uModule;
            }
        }
    }
}