import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { registerListener, getFiles } from 'c/boxFileStore';

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

    connectedCallback(){

        // Load stored files
        this.loadFiles();

        // Load storage selection
        this.loadStorage();

        // Listener for global store updates (optional)
        this.files = getFiles();

        registerListener((updatedFiles)=>{
            this.files = [...updatedFiles];
        });

    }

   loadFiles(){

    getBoxFiles({ recordId: this.recordId })
    .then(result => {

        const mappedFiles = result.map(file => ({
            id: file.Box_File_Id__c,
            name: file.Name,
            url: file.File_URL__c,
            size: file.Size__c
        }));

        // force re-render
        this.files = [...mappedFiles];

    })
    .catch(error=>{
        console.error('Error loading files', error);
    });

}

    handleFilesSaved(){

        // Close modal
        this.showModal = false;

        // Reload files immediately
        this.loadFiles();
         // Wait for Apex commit
   // setTimeout(() => {
       // this.loadFiles();
   // }, 1000);

       
    }

    loadStorage(){

        getSelectedStorage()
        .then(storage => {

            if(storage){

                this.selectedStorage = storage;

                if(storage === 'box'){
                    this.checkBoxAuth();
                }

            }

        })
        .catch(error=>{
            console.error(error);
        });

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

    }

    get addFileLabel(){

        if(!this.selectedStorage){
            return 'Add File';
        }

        return 'Add File (' + this.selectedStorageLabel + ')';

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