import { LightningElement, track } from 'lwc';
import getBoxItems from '@salesforce/apex/BoxController.getBoxItems';

export default class AddFileComponent extends LightningElement {

    @track items = [];
    @track currentFolderName = 'Box Folders';

    folderId = '0';
    folderStack = [];

    // store selected items globally
    selectedMap = {};

    connectedCallback() {
        this.loadItems();
    }

    get cardTitle() {
        return this.currentFolderName;
    }

    get showBackButton() {
        return this.folderStack.length > 0;
    }

    loadItems(){

        getBoxItems({ folderId: this.folderId })

        .then(result => {

            let data = result.map(item => {

                const checked = this.selectedMap[item.id] === true;

                return {
                    ...item,
                    rowId: item.id,
                    indent:'',
                    checked: checked,
                    sizeDisplay: item.size ? item.size : '-',
                    modifiedDisplay: item.modified ? item.modified : '-',
                    isFolder: item.type === 'folder',
                    isFile: item.type === 'file'
                };

            });

            if(this.folderId === '0'){
                data = data.filter(i => i.isFolder);
                this.currentFolderName = 'Box Folders';
            }

            this.items = data;

        })

        .catch(error => {
            console.error('Error loading Box items', error);
        });

    }

    handleCheckbox(event){

        const id = event.target.dataset.id;
        const type = event.target.dataset.type;
        const checked = event.target.checked;

        this.selectedMap[id] = checked;

        if(type === 'folder' && checked){

            getBoxItems({ folderId: id })

            .then(result => {

                let files = result
                .filter(i => i.type === 'file')
                .map(file => {

                    this.selectedMap[file.id] = true;

                    return {
                        ...file,
                        rowId: id + '-' + file.id,
                        indent:'padding-left:25px',
                        checked:true,
                        sizeDisplay: file.size ? file.size : '-',
                        modifiedDisplay: file.modified ? file.modified : '-',
                        isFolder:false,
                        isFile:true
                    };

                });

                const index = this.items.findIndex(i => i.id === id);

                this.items = [
                    ...this.items.slice(0,index+1),
                    ...files,
                    ...this.items.slice(index+1)
                ];

            });

        }

        if(!checked){
            delete this.selectedMap[id];
        }

    }

    handleClick(event){

        const row = event.currentTarget.parentElement;

        const id = row.dataset.id;
        const type = row.dataset.type;
        const name = row.dataset.name;
        const url = row.dataset.url;

        if(type === 'folder'){

            this.folderStack.push({
                id: this.folderId,
                name: this.currentFolderName
            });

            this.folderId = id;
            this.currentFolderName = name;

            this.loadItems();

        }

        if(type === 'file'){
            window.open(url,'_blank');
        }

    }

    goBack(){

        if(this.folderStack.length > 0){

            const prev = this.folderStack.pop();

            this.folderId = prev.id;
            this.currentFolderName = prev.name;

            this.loadItems();

        }

    }

}