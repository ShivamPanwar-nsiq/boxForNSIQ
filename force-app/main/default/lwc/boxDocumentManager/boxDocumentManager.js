import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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

            else{

                this.showToast(
                    'Storage Not Configured',
                    'Please configure storage in Multi Connector Setting',
                    'warning'
                );

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
            this.files = [];
        }

        else if(this.selectedStorage === 'dropbox'){
            this.files = [];
        }

        else if(this.selectedStorage === 'sharepoint'){
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
            dropbox : 'Selected Dropbox Files',
            sharepoint : 'Selected SharePoint Files'
        };

        return map[this.selectedStorage] || 'Files';

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
            dropbox : 'Dropbox',
            sharepoint : 'SharePoint'
        };

        return map[this.selectedStorage] || 'Storage';

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

    get isSharepoint(){
        return this.selectedStorage === 'sharepoint';
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