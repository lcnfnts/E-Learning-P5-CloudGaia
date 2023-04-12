import { LightningElement, wire , api} from 'lwc';
import getUnitWrapper from '@salesforce/apex/UnitService.getUnitWrapper';

export default class ContentUnit extends LightningElement {
    value = '';
    @api unitData  = {};

    @api unitQuestions = [];
    unitId= 'a02Dp000001o4WxIAI';

    @wire(getUnitWrapper, {unitId: 'a02Dp000001o4WxIAI'})
    unitWrapper(result){
        if(result.data){
        //    console.log(result.data);
            
            for(var i=0; i< result.data.questions.length ; i++){
                
                let currentQ = {
                    Id: result.data.questions[i].Id,
                    Name: result.data.questions[i].Name,
                    Content: result.data.questions[i].Content__c,
                    Answers: []
                }
                
        //        console.log('Current: ');
        //        console.log(currentQ.Name);
                
                var ans = result.data.answers[result.data.questions[i].Id];

                
                var answersToAdd = []; 
                for(var j=0; j < ans.length; j++){
                    answersToAdd.push({label: ans[j].Response_Content__c , value: ans[j].Id})
                }
                currentQ.Answers = answersToAdd;
                this.unitQuestions.push(currentQ);

            }

        //    console.log('Estructura -nueva');
        //    console.log(this.unitQuestions);
            this.unitData = result.data.unit;
            
        }
        else if(result.error){
            console.log('Errooor');
            console.log(result.error);
        }
    }


}