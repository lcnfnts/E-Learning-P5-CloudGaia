import { LightningElement, api, track, wire } from 'lwc';
import getUnitList from '@salesforce/apex/UnitService.getUnitList';

const columns = [
    { 
        label: 'Modulo', 
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'module' },
            target: '_blank'
        },
        fieldName: 'unitUrl'
    },
    { label: 'Total tiempo', fieldName: 'totalTime'},
    { label: 'Total puntos', fieldName: 'totalScore'},
];

export default class UnitList extends LightningElement {
    columns  = columns;
    @track unitData = [];
    @api moduleId = '';
    
    /*@api
    set module(value){
        console.log('Module: ' + value);

        this.setAttribute('moduleId' , value);
        this.moduleId = value;
    }*/

    @wire(getUnitList, {moduleId : '$moduleId'})
    units(result){
        if(result.data){
            console.log('entro al if ');
            console.log(result.data);
            for(var i=0 ; i<result.data.length ; i++){
                let u = {
                        module: result.data[i].Name,
                        unitUrl: 'https://plataforma587-dev-ed.develop.lightning.force.com/lightning/r/' + result.data[i].Id + '/view',
                        totalTime: result.data[i].Time__c,
                        totalScore: result.data[i].Score__c
                    }
                console.log(u.module , u.totalTime, u.totalScore);
                this.unitData.push(u);
            }
        }else if(result.error){
            console.log('Error')
        }
    }
}