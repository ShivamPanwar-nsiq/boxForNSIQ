import { LightningElement, track } from 'lwc';

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

}