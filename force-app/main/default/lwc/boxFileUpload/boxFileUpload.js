import { LightningElement, api, track } from 'lwc';
import uploadFileToBox from '@salesforce/apex/BoxUploadController.uploadFileToBox';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BoxFileUpload extends LightningElement {

    @api recordId;
    @api objectApiName;

    @track isUploading = false;

    handleUpload(event){

        const file = event.target.files[0];

        if(!file){
            return;
        }

        const fileName = file.name;

        const reader = new FileReader();

        this.isUploading = true;

        reader.onload = () => {

            const base64 = reader.result.split(',')[1];

            uploadFileToBox({
                recordId : this.recordId,
                objectName : this.objectApiName,
                fileName : fileName,
                base64Data : base64
            })
            .then((result)=>{

                if(result.success){

                    this.showToast(
                        'Success',
                        result.message,
                        'success'
                    );

                }else{

                    this.showToast(
                        'Error',
                        result.message,
                        'error'
                    );
                }

                this.resetFileInput();

            })
            .catch(error=>{

                console.error(error);

                this.showToast(
                    'Error',
                    'Unexpected error occurred while uploading ' + fileName,
                    'error'
                );

            })
            .finally(()=>{
                this.isUploading = false;
            });

        };

        reader.readAsDataURL(file);
    }

    resetFileInput(){
        const input = this.template.querySelector('lightning-input');
        if(input){
            input.value = null;
        }
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