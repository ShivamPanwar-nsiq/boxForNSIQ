import { LightningElement, api, track } from 'lwc';
import uploadFileToBox from '@salesforce/apex/BoxUploadController.uploadFileToBox';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BoxFileUpload extends LightningElement {

    @api recordId;
    @api objectApiName;

    @track isUploading = false;
    @track showModal = false;

    fileName;
    base64Data;

    handleUpload(event) {

        const file = event.target.files[0];

        if (!file) {
            return;
        }

        this.fileName = file.name;

        const reader = new FileReader();

        reader.onload = () => {

            this.base64Data = reader.result.split(',')[1];

            this.uploadFile(false);

        };

        reader.readAsDataURL(file);
    }

    uploadFile(overwrite) {

        this.isUploading = true;

        uploadFileToBox({

            recordId: this.recordId,
            objectName: this.objectApiName,
            fileName: this.fileName,
            base64Data: this.base64Data,
            overwrite: overwrite

        })
        .then(result => {

            if (result.success) {

                this.showToast(
                    'Success',
                    result.message,
                    'success'
                );

                this.resetFileInput();

                // 🔹 IMPORTANT: Notify parent component
                this.dispatchEvent(
                    new CustomEvent('uploadcomplete')
                );

            } 
            else {

                if (result.message.includes('already exists')) {

                    this.showModal = true;

                } 
                else {

                    this.showToast(
                        'Error',
                        result.message,
                        'error'
                    );

                }
            }

        })
        .catch(error => {

            this.showToast(
                'Error',
                error?.body?.message || 'Unknown error',
                'error'
            );

        })
        .finally(() => {

            this.isUploading = false;

        });
    }

    handleYes() {

        this.showModal = false;

        this.uploadFile(true);

    }

    handleNo() {

        this.showModal = false;

        this.resetFileInput();

        this.showToast(
            'Cancelled',
            'File upload cancelled',
            'warning'
        );

    }

    resetFileInput() {

        const input = this.template.querySelector('lightning-input');

        if (input) {
            input.value = null;
        }

    }

    showToast(title, message, variant) {

        this.dispatchEvent(

            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })

        );

    }
}