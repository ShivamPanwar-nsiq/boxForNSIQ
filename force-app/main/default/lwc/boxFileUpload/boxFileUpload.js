import { LightningElement, api } from 'lwc';
import uploadFileToBox from '@salesforce/apex/BoxUploadController.uploadFileToBox';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BoxFileUpload extends LightningElement {

    @api recordId;
    @api objectApiName;

    handleUpload(event) {

        const file = event.target.files[0];

        if (!file) {
            return;
        }

        const reader = new FileReader();

        reader.onload = () => {

            const base64 = reader.result.split(',')[1];

            uploadFileToBox({
                recordId: this.recordId,
                objectName: this.objectApiName,
                fileName: file.name,
                base64Data: base64
            })
            .then(() => {

                this.showToast('Success','File uploaded to Box','success');

                this.template.querySelector('lightning-input').value = null;

            })
            .catch(error => {

                let message = 'Upload Failed';

                if(error?.body?.message){
                    message = error.body.message;
                }

                this.showToast('Error',message,'error');

            });
        };

        reader.readAsDataURL(file);
    }

    showToast(title,message,variant){

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}