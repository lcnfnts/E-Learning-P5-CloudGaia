import { LightningElement, wire , api } from 'lwc';
import getTrailWrapper from '@salesforce/apex/UnitService.getTrailWrapper';

export default class TrailView extends LightningElement {
    
    @api recordId= '';
    moduleData = [];
    trailData = [];

    @wire(getTrailWrapper, {trailId : '$recordId'})
    trailWrapper(result){
    //    console.log('TrailId ' + this.trailId);
    //    console.log('Hay datos');
        if(result.data){
        //    console.log(result.data);
            this.trailData = result.data.trail;

            for(var i=0; i < result.data.modules.length ; i++){
                let currentModules = {
                    Id: result.data.modules[i].Id,
                    Name: result.data.modules[i].Name,
                    Score: result.data.modules[i].Score__c,
                    Time: result.data.modules[i].Time__c,
                    Check: false
                }

                for(var j=0; j < result.data.passedModuleIds.length ; j++){
                    console.log(result.data.passedModuleIds[j] + ' == ' + currentModules.Id);
                    if(currentModules.Id == result.data.passedModuleIds[j]){
                        currentModules.Check = true;
                    }
                }
                this.moduleData.push(currentModules);
            }

        } else if(result.error){
        //    console.log('no Hay datos');
        }
    }

}