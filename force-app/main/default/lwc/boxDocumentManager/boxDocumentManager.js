import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BoxDocumentManager extends LightningElement {

    @track showModal = false;
    @track showAuthModal = false;

    storageOptions = [
        { label: 'Box', value: 'box' },
        { label: 'Google Drive', value: 'google' },
        { label: 'Dropbox', value: 'dropbox' }
    ];

    handleStorageChange(event) {

        const selectedValue = event.detail.value;

        if(selectedValue === 'box'){
            this.openAuthModal();
        }
    }

    openModal() { 
        this.showModal = true;
    }

    closeModal() {
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

        this.showToast(
            'Success',
            'Box Connected Successfully',
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
                title: title,
                message: message,
                variant: variant
            })
        );

    }

}