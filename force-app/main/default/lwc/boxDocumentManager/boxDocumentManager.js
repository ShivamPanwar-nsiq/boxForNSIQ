import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, getFiles } from 'c/boxFileStore';

export default class BoxDocumentManager extends LightningElement {

    @api recordId;
    @api objectApiName;

@track showModal = false;
@track showAuthModal = false;
@track files = [];

selectedStorage = '';
isAuthCompleted = false;

storageOptions = [
    { label: 'Box', value: 'box' },
    { label: 'Google Drive', value: 'google' },
    { label: 'Dropbox', value: 'dropbox' }
];

connectedCallback(){

    this.files = getFiles();

    registerListener((updatedFiles)=>{

        this.files = [...updatedFiles];

    });

}

get addFileLabel(){

    if(!this.selectedStorage){
        return 'Add File';
    }

    return 'Add File (' + this.selectedStorageLabel + ')';
}

get isButtonDisabled(){
    return !this.isAuthCompleted;
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

handleStorageChange(event){

    this.selectedStorage = event.detail.value;

    this.isAuthCompleted = false;

    this.openAuthModal();
}

openModal(){
    this.showModal = true;
}

closeModal(){
    this.showModal = false;
}

openAuthModal(){
    this.showAuthModal = true;
}

closeAuthModal(){
    this.showAuthModal = false;
}

handleAuthSuccess(){

    this.showAuthModal = false;

    this.isAuthCompleted = true;

    this.showToast(
        'Success',
        this.selectedStorageLabel + ' Connected Successfully',
        'success'
    );
}

handleAuthError(event){

    const message = event.detail || 'Authentication Failed';

    this.showToast(
        'Error',
        message,
        'error'
    );
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
