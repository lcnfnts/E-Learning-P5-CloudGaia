import { LightningElement, wire , api, track} from 'lwc';
import getUnitWrapper from '@salesforce/apex/UnitService.getUnitWrapper';
import validateUnit from '@salesforce/apex/UnitService.validateUnit';
//import { CurrentPageReference } from 'lightning/navigation';

export default class ContentUnit extends LightningElement {
    
    @api unitData  = {};
    @api userResponses = {};
    
    @track unitQuestions = [];
    @api recordId= '';
    
    @track successAlert = false;
    @track failAlert = false;

    @wire(getUnitWrapper, {unitId: '$recordId'})
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
                
                    // console.log('Current: ');
                    // console.log(currentQ.Name);
                
                var ans = result.data.answers[result.data.questions[i].Id];
                var answersToAdd = []; 
                for(var j=0; j < ans.length; j++){
                    answersToAdd.push({label: ans[j].Response_Content__c , value: ans[j].Id})
                }
                currentQ.Answers = answersToAdd;
                this.unitQuestions.push(currentQ);

                this.userResponses[currentQ.Id] = '';
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

    handleClick(){
        //Estructura para consumir un servicio de APEX
        validateUnit({unitId: this.recordId, response: this.userResponses})
        .then(result =>{
            console.log('respondio');
            console.log(result);
            if(result == true){
                this.successAlert = true;
                this.failAlert = false;
            } else {
                this.failAlert = true;
                this.successAlert = false;
            }
        })
        .catch(error =>{
            console.log('error de booleano');
            console.log(error);
        })
    }

    handleRadioChange(event){
        /*{
            a0BDp0000012gN4MAI: 'wertyu',
            a0BDp0000012gN3MAI: '',
            a0BDp0000012gN5MAI: ''
            event.target.name: ''
        }*/
        this.userResponses[event.target.name] = event.target.value;
        console.log('Id Name: ' + this.userResponses[event.target.name]);
    }

}

/*
[
    {
        questionId: 'Ysdjfksdjfl',
        responseId: 'jkahsfkjhakj'
    },
    {
        questionId: 'Ysdjfrete',
        responseId: 'jkahsfmkmk'
    }
]


{
    a0BDp0000012gN4MAI: '',
    a0BDp0000012gN3MAI: '',
    a0BDp0000012gN5MAI: ''
}*/
