import { LightningElement, track } from 'lwc';
import getBoxItems from '@salesforce/apex/BoxController.getBoxItems';

export default class AddFileComponent extends LightningElement {

    @track items = [];
    folderId = '0'; // root folder

    connectedCallback() {
        this.loadItems();
    }

    loadItems() {
        getBoxItems({ folderId: this.folderId })
            .then(result => {

                this.items = result.map(item => {
                    return {
                        ...item,
                        isFolder: item.type === 'folder',
                        isFile: item.type === 'file'
                    };
                });

            })
            .catch(error => {
                console.error('Error loading Box files', error);
            });
    }
}