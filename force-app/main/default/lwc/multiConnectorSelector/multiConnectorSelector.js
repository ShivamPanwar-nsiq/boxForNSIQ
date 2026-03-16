import { LightningElement, track } from 'lwc';
import updateStorageSelection from '@salesforce/apex/StorageAuthController.updateStorageSelection';
import getSelectedStorage from '@salesforce/apex/StorageAuthController.getSelectedStorage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MultiConnectorSelector extends LightningElement {

    @track boxChecked = false;
    @track sharepointChecked = false;
    @track googleChecked = false;
    @track dropboxChecked = false;

    selectedConnector;

    connectedCallback() {
        this.loadSelectedConnector();
    }

    loadSelectedConnector() {

        getSelectedStorage()
        .then(result => {

            if(result){

                this.selectedConnector = result;

                if(result === 'box'){
                    this.boxChecked = true;
                }

                if(result === 'sharepoint'){
                    this.sharepointChecked = true;
                }

                if(result === 'google'){
                    this.googleChecked = true;
                }

                if(result === 'dropbox'){
                    this.dropboxChecked = true;
                }

            }

        })
        .catch(error => {
            console.error(error);
        });

    }

    handleChange(event){

        const value = event.target.dataset.value;

        this.boxChecked = false;
        this.sharepointChecked = false;
        this.googleChecked = false;
        this.dropboxChecked = false;

        if(value === 'box'){
            this.boxChecked = true;
        }

        if(value === 'sharepoint'){
            this.sharepointChecked = true;
        }

        if(value === 'google'){
            this.googleChecked = true;
        }

        if(value === 'dropbox'){
            this.dropboxChecked = true;
        }

        this.selectedConnector = value;

    }

    saveSelection(){

        if(!this.selectedConnector){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a connector',
                    variant: 'error'
                })
            );
            return;
        }

        updateStorageSelection({ storageType: this.selectedConnector })
        .then(() => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Connector Saved Successfully',
                    variant: 'success'
                })
            );

        })
        .catch(error => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error saving connector',
                    variant: 'error'
                })
            );

            console.error(error);

        });

    }

}