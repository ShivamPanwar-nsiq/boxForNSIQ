import { LightningElement, track } from 'lwc';
import getBoxItems from '@salesforce/apex/BoxController.getBoxItems';

export default class AddFileComponent extends LightningElement {

    @track items = [];

    folderId = '0';
    folderStack = [];

    connectedCallback() {
        this.loadItems();
    }

    loadItems(){

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
            console.error(error);
        });
    }

    handleClick(event){

        const id = event.currentTarget.dataset.id;
        const type = event.currentTarget.dataset.type;
        const url = event.currentTarget.dataset.url;

        // Folder click
        if(type === 'folder'){

            this.folderStack.push(this.folderId);

            this.folderId = id;

            this.loadItems();
        }

        // File click
        if(type === 'file'){
            window.open(url,'_blank');
        }

    }

    goBack(){

        if(this.folderStack.length > 0){

            this.folderId = this.folderStack.pop();

            this.loadItems();

        }

    }
}