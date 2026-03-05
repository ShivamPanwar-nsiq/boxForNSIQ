import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BoxDocumentManager extends LightningElement {

    @track showModal = false;
    @track showAuthModal = false;

    selectedStorage = '';
    isAuthCompleted = false;

    storageOptions = [
        { label: 'Box', value: 'box' },
        { label: 'Google Drive', value: 'google' },
        { label: 'Dropbox', value: 'dropbox' }
    ];

    // Button Label
    get addFileLabel(){

        if(!this.selectedStorage){
            return 'Add File';
        }

        return 'Add File (' + this.selectedStorageLabel + ')';
    }

    // Disable Button
    get isButtonDisabled(){
        return !this.isAuthCompleted;
    }

    // Storage Label
    get selectedStorageLabel(){

        const map = {
            box : 'Box',
            google : 'Google Drive',
            dropbox : 'Dropbox'
        };

        return map[this.selectedStorage];
    }

    // Storage Type Check
    get isBox(){
        return this.selectedStorage === 'box';
    }

    get isGoogle(){
        return this.selectedStorage === 'google';
    }

    get isDropbox(){
        return this.selectedStorage === 'dropbox';
    }

    // Select Storage
    handleStorageChange(event){

        this.selectedStorage = event.detail.value;

        this.isAuthCompleted = false;

        this.openAuthModal();
    }

    // File Modal
    openModal(){
        this.showModal = true;
    }

    closeModal(){
        this.showModal = false;
    }

    // Auth Modal
    openAuthModal(){
        this.showAuthModal = true;
    }

    closeAuthModal(){
        this.showAuthModal = false;
    }

    // Auth Success
    handleAuthSuccess(){

        this.showAuthModal = false;

        this.isAuthCompleted = true;

        this.showToast(
            'Success',
            this.selectedStorageLabel + ' Connected Successfully',
            'success'
        );
    }

    // Auth Error
    handleAuthError(event){

        const message = event.detail || 'Authentication Failed';

        this.showToast(
            'Error',
            message,
            'error'
        );
    }

    // Toast
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