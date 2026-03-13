import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import updateStorageSelection from '@salesforce/apex/StorageAuthController.updateStorageSelection';
import getSelectedStorage from '@salesforce/apex/StorageAuthController.getSelectedStorage';

import isBoxAuthenticated from '@salesforce/apex/BoxService.isBoxAuthenticated';
import getBoxFiles from '@salesforce/apex/BoxFileController.getBoxFiles';

export default class BoxDocumentManager extends LightningElement {

    @api recordId;
    @api objectApiName;

    @track showModal = false;
    @track files = [];

    selectedStorage = '';
    isAuthCompleted = false;

    storageOptions = [
        { label: 'Box', value: 'box' },
        { label: 'Google Drive', value: 'google' },
        { label: 'Dropbox', value: 'dropbox' }
    ];

    connectedCallback() {
        this.loadStorage();
    }

    loadStorage(){

        getSelectedStorage()
        .then(storage => {

            if(storage){

                this.selectedStorage = storage;

                if(storage === 'box'){
                    this.checkBoxAuth();
                }

                this.loadFiles();
            }

        })
        .catch(error=>{
            console.error(error);
        });

    }

    loadFiles(){

        if(this.selectedStorage === 'box'){

            getBoxFiles({ recordId: this.recordId })
            .then(result => {

                const mappedFiles = result.map(file => ({
                    id: file.Box_File_Id__c,
                    name: file.Name,
                    url: file.File_URL__c,
                    size: file.Size__c
                }));

                this.files = [...mappedFiles];

            })
            .catch(error=>{
                console.error('Error loading Box files', error);
            });

        }

        else if(this.selectedStorage === 'google'){

            // future google integration
            this.files = [];

        }

        else if(this.selectedStorage === 'dropbox'){

            // future dropbox integration
            this.files = [];

        }

    }

    handleFilesSaved(){

        this.showModal = false;
        this.loadFiles();

    }

    checkBoxAuth(){

        isBoxAuthenticated()
        .then(result => {

            this.isAuthCompleted = result;

            if(!result){

                this.showToast(
                    'Authentication Required',
                    'Please authenticate Box in External Credential',
                    'warning'
                );

            }

        })
        .catch(error=>{
            console.error(error);
        });

    }

    handleStorageChange(event){

        this.selectedStorage = event.detail.value;

        updateStorageSelection({
            storageType: this.selectedStorage
        });

        if(this.selectedStorage === 'box'){
            this.checkBoxAuth();
        }

        this.loadFiles();

    }

    get addFileLabel(){

        if(!this.selectedStorage){
            return 'Add File';
        }

        return 'Add File (' + this.selectedStorageLabel + ')';

    }

    get selectedFilesTitle(){

        const map = {
            box : 'Selected Box Files',
            google : 'Selected Google Drive Files',
            dropbox : 'Selected Dropbox Files'
        };

        return map[this.selectedStorage];

    }

    get isButtonDisabled(){

        if(this.selectedStorage === 'box'){
            return !this.isAuthCompleted;
        }

        return false;

    }

    get selectedStorageLabel(){

        const map = {
            box : 'Box',
            google : 'Google Drive',
            dropbox : 'Dropbox'
        };

        return map[this.selectedStorage];

    }

    get isBox(){
        return this.selectedStorage === 'box';
    }

    get isGoogle(){
        return this.selectedStorage === 'google';
    }

    get isDropbox(){
        return this.selectedStorage === 'dropbox';
    }

    openModal(){
        this.showModal = true;
    }

    closeModal(){
        this.showModal = false;
    }

    showToast(title,message,variant){

        this.dispatchEvent(
            new ShowToastEvent({
                title : title,
                message : message,
                variant : variant
            })
        );

    }

}